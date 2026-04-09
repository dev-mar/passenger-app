import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/passenger_client_meta.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController();
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
  final String? errorMessage;
  /// Código de negocio del backend (`PASS_AUTH_*`, etc.) cuando aplica.
  final String? errorCode;
  LoginState({this.errorMessage, this.errorCode});
}

class LoginController extends StateNotifier<LoginState> {
  LoginController() : super(LoginState());

  final _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrlAuth,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Login según contrato:
  /// - Si el usuario ya existe y está activo, devuelve token.
  /// - Si el usuario es nuevo o no verificado, devuelve status=pending y se envía código SMS.
  Future<LoginNextStep> login({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
  }) async {
    state = LoginState();

    try {
      final response = await _dio.post(
        AppConfig.loginPath,
        data: <String, dynamic>{
          ...passengerAuthClientMeta(),
          'country_code': countryCode,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
        },
      );

      final body = response.data;
      if (body is! Map) {
        return _fail(code: 'CLIENT_INVALID_RESPONSE');
      }

      final success = body['success'] == true;
      if (!success) {
        final code = body['code']?.toString();
        final msg = body['message']?.toString();
        return _fail(code: code ?? 'AUTH_LOGIN_FAILED', message: msg);
      }

      final data = body['data'];
      if (data is! Map) {
        return _fail(code: 'CLIENT_EMPTY_DATA');
      }

      // Caso 1: respuesta con token → usuario activo (flujo clásico de login).
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        // Caso 2: sin token pero status=pending / no verificado → ir a pantalla de código.
        final status = data['status']?.toString();
        final isVerified = data['is_verified'] == true;
        if (status == 'pending' || !isVerified) {
          return LoginNextStep.verifyCode;
        }
        // Si no hay token ni estado pendiente, consideramos que falta configuración en backend.
        return _fail(code: 'CLIENT_TOKEN_MISSING');
      }

      // Los campos de refresh/expiración son opcionales en este backend.
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
      String? code;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return _fail(code: 'NETWORK_TIMEOUT');
      }
      final data = e.response?.data;
      if (data is Map) {
        code = data['code']?.toString();
        final msg = data['message']?.toString();
        return _fail(code: code ?? 'AUTH_LOGIN_FAILED', message: msg);
      } else if (e.type == DioExceptionType.connectionError) {
        return _fail(code: 'NETWORK_CONNECTION');
      }
      return _fail(code: code ?? 'NETWORK_REQUEST_FAILED', message: e.message);
    } catch (_) {
      return _fail(code: 'CLIENT_UNEXPECTED');
    }
  }

  LoginNextStep _fail({required String code, String? message}) {
    state = LoginState(errorMessage: message, errorCode: code);
    return LoginNextStep.error;
  }
}
