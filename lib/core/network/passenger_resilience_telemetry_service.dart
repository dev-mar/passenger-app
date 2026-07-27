import 'package:dio/dio.dart';

import '../auth/auth_service.dart';
import 'passenger_http_resilience.dart';

class PassengerResilienceTelemetryService {
  PassengerResilienceTelemetryService._();

  static Dio get _dio => passengerAuthPublicHttpClient();

  static final Map<String, DateTime> _lastSentByKey = <String, DateTime>{};
  static const Duration _cooldown = Duration(seconds: 20);

  static Future<void> sendEvent({
    required String flow,
    required String endpoint,
    required String event,
    int? attempt,
    int? waitMs,
    int? statusCode,
  }) async {
    final now = DateTime.now();
    final dedupeKey =
        'passenger|$flow|$endpoint|$event|${statusCode ?? 0}|${attempt ?? 0}';
    final prev = _lastSentByKey[dedupeKey];
    if (prev != null && now.difference(prev) < _cooldown) return;
    _lastSentByKey[dedupeKey] = now;
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) return;
    try {
      final payload = <String, dynamic>{
        'app': 'passenger',
        'flow': flow,
        'endpoint': endpoint,
        'event': event,
        'attempt': attempt,
        'wait_ms': waitMs,
        'status_code': statusCode,
        'platform': 'flutter',
      }..removeWhere((_, value) => value == null);
      await _dio.post<Map<String, dynamic>>(
        '/auth/telemetry/client-resilience',
        data: payload,
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $token'},
        ),
      );
    } catch (_) {
      // Telemetría best-effort, no rompe UX.
    }
  }
}
