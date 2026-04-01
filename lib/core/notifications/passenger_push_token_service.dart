import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../auth/auth_service.dart';
import '../config/app_config.dart';

class PassengerPushTokenService {
  PassengerPushTokenService._();
  static final PassengerPushTokenService instance = PassengerPushTokenService._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrlAuth,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  Future<void> syncTokenIfPossible() async {
    try {
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
    } catch (_) {
      // No bloquea login/sesión si FCM o backend no están listos.
    }
  }
}

