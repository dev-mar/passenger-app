import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/passenger_api_client.dart';
import '../../core/network/passenger_api_providers.dart';
import '../../core/network/passenger_client_meta.dart';
import '../../core/config/passenger_app_environment.dart';
import '../../core/network/passenger_http_resilience.dart';
import '../../core/network/texi_backend_error.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(passengerApiClientProvider));
});

/// Próximo paso del flujo de login.
enum LoginNextStep {
  /// Usuario ya está activo y se guardó el token → ir al mapa.
  tripRequest,

  /// Usuario pendiente de verificación → ir a pantalla de código.
  verifyCode,

  /// Hubo algún error (mensaje en [LoginState.errorMessage]).
  error,
}

class LoginState {
  const LoginState({
    this.errorMessage,
    this.errorCode,
    this.accountDeletion,
    this.verificationChannel,
    this.challengeId,
    this.waDeepLink,
  });

  final String? errorMessage;
  /// Código de negocio del backend (`PASS_AUTH_*`, etc.) cuando aplica.
  final String? errorCode;
  final Map<String, dynamic>? accountDeletion;
  final String? verificationChannel;
  final String? challengeId;
  final String? waDeepLink;
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._api) : super(const LoginState());

  final PassengerApiClient _api;

  /// Login según contrato:
  /// - Si el usuario ya existe y está activo, devuelve token.
  /// - Si el usuario es nuevo o no verificado, devuelve status=pending y se solicita código de verificación.
  Future<LoginNextStep> login({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
    bool cancelPendingDeletion = false,
  }) async {
    state = const LoginState();

    try {
      final clientMeta = await passengerAuthClientMeta();
      String? pushToken;
      try {
        if (Firebase.apps.isNotEmpty) {
          final t = await FirebaseMessaging.instance
              .getToken()
              .timeout(const Duration(milliseconds: 1500));
          if (t != null && t.trim().isNotEmpty) pushToken = t.trim();
        }
      } catch (_) {}

      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.loginPath,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': countryCode,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          if (PassengerAppEnvironment.multichannelAuthEnabled)
            'otp_channel': 'whatsapp_inbound'
          else if (pushToken != null)
            'otp_channel': 'push',
          'push_token': ?pushToken,
          if (cancelPendingDeletion) 'cancel_pending_deletion': true,
        },
      );

      final body = response.data;
      if (body is! Map) {
        return _fail(code: 'CLIENT_INVALID_RESPONSE');
      }
      final envelope = Map<String, dynamic>.from(body as Map);

      final success = envelope['success'] == true;
      if (!success) {
        final code = envelope['code']?.toString();
        final msg = envelope['message']?.toString();
        return _fail(
          code: code ?? 'AUTH_LOGIN_FAILED',
          message: msg,
          data: envelope['data'] is Map
              ? Map<String, dynamic>.from(envelope['data'] as Map)
              : null,
        );
      }

      final data = envelope['data'];
      if (data is! Map) {
        return _fail(code: 'CLIENT_EMPTY_DATA');
      }

      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        final status = data['status']?.toString();
        final isVerified = data['is_verified'] == true;
        if (status == 'pending' || !isVerified) {
          state = LoginState(
            verificationChannel: data['verification_channel']?.toString(),
            challengeId: data['challenge_id']?.toString(),
            waDeepLink: data['wa_deep_link']?.toString(),
          );
          return LoginNextStep.verifyCode;
        }
        return _fail(code: 'CLIENT_TOKEN_MISSING');
      }

      final refreshToken = data['refresh_token']?.toString();
      final expiresIn = data['expires_in'];
      int? expiresInSec;
      if (expiresIn is int) {
        expiresInSec = expiresIn;
      } else if (expiresIn is num) {
        expiresInSec = expiresIn.toInt();
      }

      await AuthService.saveSession(
        token: token,
        refreshToken: refreshToken,
        expiresInSeconds: expiresInSec,
      );
      await AuthService.persistLoginPhoneE164(fullPhone);
      return LoginNextStep.tripRequest;
    } on DioException catch (e) {
      final networkCode = networkErrorCodeFromDio(e);
      if (networkCode != null) {
        return _fail(code: networkCode);
      }
      final data = e.response?.data;
      final code = TexiBackendError.codeFromResponse(data);
      final msg = TexiBackendError.messageFromResponse(data);
      Map<String, dynamic>? payload;
      if (data is Map && data['data'] is Map) {
        payload = Map<String, dynamic>.from(data['data'] as Map);
      }
      return _fail(
        code: code ?? 'AUTH_LOGIN_FAILED',
        message: msg ?? e.message,
        data: payload,
      );
    } catch (_) {
      return _fail(code: 'CLIENT_UNEXPECTED');
    }
  }

  Future<bool> recoverAccountFromPendingDeletion({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
  }) async {
    final step = await login(
      countryCode: countryCode,
      phoneNumber: phoneNumber,
      fullPhone: fullPhone,
      cancelPendingDeletion: true,
    );
    return step == LoginNextStep.tripRequest;
  }

  LoginNextStep _fail({
    required String code,
    String? message,
    Map<String, dynamic>? data,
  }) {
    Map<String, dynamic>? accountDeletion;
    if (data?['account_deletion'] is Map) {
      accountDeletion = Map<String, dynamic>.from(
        data!['account_deletion'] as Map,
      );
    }
    state = LoginState(
      errorMessage: message,
      errorCode: code,
      accountDeletion: accountDeletion,
    );
    return LoginNextStep.error;
  }
}
