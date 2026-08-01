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
import 'services/passenger_google_sign_in_service.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(passengerApiClientProvider));
});

/// Próximo paso del flujo de login.
enum LoginNextStep {
  tripRequest,
  verifyCode,
  stepUp,
  phoneRequired,
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
    this.googleLinkToken,
    this.googleEmail,
    this.googleDisplayName,
    this.entryCaptchaToken,
  });

  final String? errorMessage;
  /// Código de negocio del backend (`PASS_AUTH_*`, etc.) cuando aplica.
  final String? errorCode;
  final Map<String, dynamic>? accountDeletion;
  final String? verificationChannel;
  final String? challengeId;
  final String? waDeepLink;
  final String? googleLinkToken;
  final String? googleEmail;
  final String? googleDisplayName;
  /// Token Turnstile de la puerta de entrada (UX; backend lo validará en fase posterior).
  final String? entryCaptchaToken;
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._api) : super(const LoginState());

  final PassengerApiClient _api;
  final PassengerGoogleSignInService _googleSignIn = PassengerGoogleSignInService();

  /// Login según contrato:
  /// - Si el usuario ya existe y está activo, devuelve token.
  /// - Si el usuario es nuevo o no verificado, devuelve status=pending y se solicita código de verificación.
  Future<LoginNextStep> login({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
    bool cancelPendingDeletion = false,
    String? otpChannel,
    String? entryCaptchaToken,
  }) async {
    state = LoginState(
      entryCaptchaToken: entryCaptchaToken,
    );

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

      final resolvedChannel = otpChannel ??
          (PassengerAppEnvironment.multichannelAuthEnabled
              ? 'whatsapp_inbound'
              : (pushToken != null ? 'push' : 'code'));

      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.loginPath,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': countryCode,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          'otp_channel': resolvedChannel,
          'push_token': ?pushToken,
          if (cancelPendingDeletion) 'cancel_pending_deletion': true,
          // Reservado contrato Fase 6 — backend ignorará hasta implementación.
          if (entryCaptchaToken != null &&
              entryCaptchaToken.trim().isNotEmpty &&
              entryCaptchaToken != 'dev-bypass-captcha')
            'entry_captcha_token': entryCaptchaToken.trim(),
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
        if (code == 'PASS_AUTH_STEP_UP_REQUIRED') {
          return LoginNextStep.stepUp;
        }
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
      if (code == 'PASS_AUTH_STEP_UP_REQUIRED') {
        return LoginNextStep.stepUp;
      }
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

  bool get isGoogleAuthConfigured => _googleSignIn.isConfigured;

  Future<LoginNextStep> loginWithGoogle({String? entryCaptchaToken}) async {
    state = LoginState(entryCaptchaToken: entryCaptchaToken);
    try {
      final idToken = await _googleSignIn.signInAndGetIdToken();
      if (idToken == null) {
        return LoginNextStep.error;
      }
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.authGooglePath,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        data: <String, dynamic>{
          ...clientMeta,
          'id_token': idToken,
          if (entryCaptchaToken != null &&
              entryCaptchaToken.trim().isNotEmpty &&
              entryCaptchaToken != 'dev-bypass-captcha')
            'entry_captcha_token': entryCaptchaToken.trim(),
        },
      );
      final body = response.data;
      if (body is! Map) {
        return _fail(code: 'CLIENT_INVALID_RESPONSE');
      }
      final envelope = Map<String, dynamic>.from(body as Map);
      if (envelope['success'] != true) {
        final code = envelope['code']?.toString();
        return _fail(
          code: code ?? 'PASS_AUTH_GOOGLE_FAILED',
          message: envelope['message']?.toString(),
        );
      }
      final code = envelope['code']?.toString();
      final data = envelope['data'];
      if (code == 'PASS_AUTH_GOOGLE_PHONE_REQUIRED' && data is Map) {
        final payload = Map<String, dynamic>.from(data);
        state = LoginState(
          googleLinkToken: payload['link_token']?.toString(),
          googleEmail: payload['email']?.toString(),
          googleDisplayName: payload['display_name']?.toString(),
        );
        return LoginNextStep.phoneRequired;
      }
      if (data is! Map) {
        return _fail(code: 'CLIENT_EMPTY_DATA');
      }
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
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
      return LoginNextStep.tripRequest;
    } on DioException catch (e) {
      final networkCode = networkErrorCodeFromDio(e);
      if (networkCode != null) {
        return _fail(code: networkCode);
      }
      final data = e.response?.data;
      return _fail(
        code: TexiBackendError.codeFromResponse(data) ?? 'PASS_AUTH_GOOGLE_FAILED',
        message: TexiBackendError.messageFromResponse(data) ?? e.message,
      );
    } catch (_) {
      return _fail(code: 'CLIENT_UNEXPECTED');
    }
  }

  Future<LoginNextStep> requestWhatsAppOutbound({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
    String? entryCaptchaToken,
  }) async {
    state = LoginState(entryCaptchaToken: entryCaptchaToken);
    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.loginPath,
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': countryCode,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          'otp_channel': 'whatsapp_outbound',
          if (entryCaptchaToken != null &&
              entryCaptchaToken.trim().isNotEmpty &&
              entryCaptchaToken != 'dev-bypass-captcha')
            'entry_captcha_token': entryCaptchaToken.trim(),
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        final code = body is Map<String, dynamic> ? body['code']?.toString() : null;
        if (code == 'PASS_AUTH_STEP_UP_REQUIRED') {
          return LoginNextStep.stepUp;
        }
        return _fail(
          code: code ?? 'AUTH_LOGIN_FAILED',
          message: body is Map<String, dynamic> ? body['message']?.toString() : null,
        );
      }
      final data = body['data'];
      if (data is! Map) return _fail(code: 'CLIENT_EMPTY_DATA');
      final pending = Map<String, dynamic>.from(data);
      state = LoginState(
        verificationChannel: pending['verification_channel']?.toString() ?? 'whatsapp_outbound',
        challengeId: pending['challenge_id']?.toString(),
      );
      return LoginNextStep.verifyCode;
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = TexiBackendError.codeFromResponse(data);
      if (code == 'PASS_AUTH_STEP_UP_REQUIRED') {
        return LoginNextStep.stepUp;
      }
      return _fail(
        code: code ?? 'AUTH_LOGIN_FAILED',
        message: TexiBackendError.messageFromResponse(data) ?? e.message,
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
