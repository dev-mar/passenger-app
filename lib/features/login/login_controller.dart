import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';

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
  LoginState({this.errorMessage});
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
        data: {
          'brand': 'Texi App',
          'country_code': countryCode,
          'ip': '0.0.0.0',
          'model': _deviceModel(),
          'os': Platform.operatingSystem,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
        },
      );

      final body = response.data;
      if (body is! Map) {
        return _fail('Respuesta inválida');
      }

      final success = body['success'] == true;
      if (!success) {
        final msg = body['message']?.toString() ?? 'Error al iniciar sesión';
        return _fail(msg);
      }

      final data = body['data'];
      if (data is! Map) {
        return _fail('Respuesta sin datos');
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
        return _fail('No se recibió token');
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
      return LoginNextStep.tripRequest;
    } on DioException catch (e) {
      String message = 'Error de conexión';
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          message = msg;
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      return _fail(message);
    } catch (_) {
      return _fail('Error inesperado');
    }
  }

  LoginNextStep _fail(String message) {
    state = LoginState(errorMessage: message);
    return LoginNextStep.error;
  }

  String _deviceModel() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Unknown';
    }
  }
}
