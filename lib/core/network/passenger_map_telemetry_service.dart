import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/auth_service.dart';
import '../config/app_config.dart';

class PassengerMapTelemetryService {
  PassengerMapTelemetryService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrlAuth,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
    ),
  );

  static final Map<String, DateTime> _lastSentByKey = <String, DateTime>{};
  static const Duration _cooldown = Duration(seconds: 25);

  static Future<void> sendMapOptimizationMode({
    required String mode,
    required String appState,
    required bool isLowBattery,
    required bool isDriverIdle,
    String? tripId,
    int? batteryLevel,
    required String platform,
    required String appVersion,
  }) async {
    final dedupeKey = '$tripId|$mode|$appState|$isLowBattery|$isDriverIdle';
    final now = DateTime.now();
    final prev = _lastSentByKey[dedupeKey];
    if (prev != null && now.difference(prev) < _cooldown) {
      return;
    }
    _lastSentByKey[dedupeKey] = now;
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) return;
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/telemetry/map-performance',
        data: <String, dynamic>{
          'trip_id': tripId,
          'mode': mode,
          'app_state': appState,
          'battery_level': batteryLevel,
          'is_low_battery': isLowBattery,
          'is_driver_idle': isDriverIdle,
          'platform': platform,
          'app_version': appVersion,
        },
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $token'},
        ),
      );
    } catch (_) {
      // Telemetría best-effort, nunca rompe UX.
    }
  }
}
