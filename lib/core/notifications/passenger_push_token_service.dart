import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../auth/passenger_session_expulsion.dart';
import '../auth/auth_service.dart';
import '../config/app_config.dart';
import '../network/passenger_http_resilience.dart';

class PassengerPushTokenService {
  PassengerPushTokenService._();
  static final PassengerPushTokenService instance = PassengerPushTokenService._();

  Dio get _dio => passengerAuthPublicHttpClient();

  Future<void> syncTokenIfPossible() async {
    try {
      if (passengerSessionSyncBlocked) return;
      final bearer = await AuthService.getValidToken();
      if (bearer == null || bearer.isEmpty) return;
      if (Firebase.apps.isEmpty) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final platform = kIsWeb
          ? 'web'
          : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
      await _dio.post<Map<String, dynamic>>(
        '/auth/push-token',
        data: {
          'token': token,
          'provider': 'fcm',
          'platform': platform,
          'app_id': AppConfig.firebaseAndroidApplicationId,
        },
        options: Options(headers: {'Authorization': 'Bearer $bearer'}),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        passengerSessionSyncBlocked = true;
      }
    } catch (_) {
      // No bloquea login/sesión si FCM o backend no están listos.
    }
  }

  /// Logout: deja de enviar FCM a este dispositivo/cuenta hasta el próximo login + sync.
  Future<void> revokeAllOnServerIfPossible() async {
    try {
      final bearer = await AuthService.getValidToken();
      if (bearer == null || bearer.isEmpty) return;
      await _dio.delete<Map<String, dynamic>>(
        '/auth/push-token',
        options: Options(headers: {'Authorization': 'Bearer $bearer'}),
      );
    } catch (_) {
      // Cierre de sesión no debe fallar por red.
    }
  }
}

