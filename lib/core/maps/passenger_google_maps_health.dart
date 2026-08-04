import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../network/passenger_http_resilience.dart';

/// Resultado de la sonda REST de Google Maps (Places/Geocoding/Directions).
class PassengerGoogleMapsHealthResult {
  const PassengerGoogleMapsHealthResult({
    required this.ok,
    this.status,
    this.errorMessage,
    this.missingApiKey = false,
  });

  final bool ok;
  final String? status;
  final String? errorMessage;
  final bool missingApiKey;

  bool get isRequestDenied =>
      status == 'REQUEST_DENIED' || status == 'OVER_QUERY_LIMIT';
}

/// Diagnóstico compartido para APIs REST de Google (no el widget nativo del mapa).
class PassengerGoogleMapsHealth {
  PassengerGoogleMapsHealth._();

  static bool _missingKeyLogged = false;
  static bool? _lastProbeOk;

  static bool get lastProbeOk => _lastProbeOk ?? true;

  static void logApiStatus({
    required String service,
    String? status,
    String? errorMessage,
  }) {
    if (status == null || status == 'OK' || status == 'ZERO_RESULTS') return;
    debugPrint(
      '[GoogleMaps/$service] status=$status'
      '${errorMessage != null && errorMessage.isNotEmpty ? ', error=$errorMessage' : ''}',
    );
  }

  static void logMissingApiKeyOnce() {
    if (_missingKeyLogged) return;
    _missingKeyLogged = true;
    debugPrint(
      '[GoogleMaps] GOOGLE_MAPS_API_KEY ausente en --dart-define. '
      'Places/Geocoding/Directions no funcionarán (el mapa nativo puede seguir visible).',
    );
  }

  /// Sonda ligera vía Geocoding (misma key que Places/Directions).
  static Future<PassengerGoogleMapsHealthResult> probe() async {
    final apiKey = AppConfig.googleMapsRestApiKeyOrNull;
    if (apiKey == null || apiKey.isEmpty) {
      logMissingApiKeyOnce();
      _lastProbeOk = false;
      return const PassengerGoogleMapsHealthResult(
        ok: false,
        status: 'MISSING_KEY',
        missingApiKey: true,
      );
    }

    try {
      final dio = passengerGoogleMapsHttpClient(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      );
      final response = await dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: <String, dynamic>{
          'latlng': '-16.5000,-68.1500',
          'key': apiKey,
          'language': 'es',
        },
      );
      final data = response.data;
      final status = data?['status']?.toString();
      final errorMessage = data?['error_message']?.toString();
      logApiStatus(
        service: 'HealthProbe',
        status: status,
        errorMessage: errorMessage,
      );
      final ok = status == 'OK' || status == 'ZERO_RESULTS';
      _lastProbeOk = ok;
      return PassengerGoogleMapsHealthResult(
        ok: ok,
        status: status,
        errorMessage: errorMessage,
      );
    } on DioException catch (e) {
      debugPrint('[GoogleMaps/HealthProbe] network error: ${e.message}');
      _lastProbeOk = false;
      return PassengerGoogleMapsHealthResult(
        ok: false,
        status: 'NETWORK_ERROR',
        errorMessage: e.message,
      );
    } catch (e) {
      debugPrint('[GoogleMaps/HealthProbe] unexpected: $e');
      _lastProbeOk = false;
      return PassengerGoogleMapsHealthResult(
        ok: false,
        status: 'ERROR',
        errorMessage: e.toString(),
      );
    }
  }
}
