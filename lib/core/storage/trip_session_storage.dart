import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/quote_response.dart';

/// Almacenamiento local del trip para recuperar estado al reabrir la app.
///
/// Importante: el backend hoy NO hace replay por WebSocket y tampoco
/// persiste rating del pasajero. Por eso usamos persistencia local:
/// - `active_trip_id`: para saber qué trip re-hidratar
/// - `rating_done_by_tripId`: para decidir si mostrar la sheet de rating
class TripSessionStorage {
  TripSessionStorage._();

  static const _storage = FlutterSecureStorage();

  static const String _keyActiveTripId = 'active_trip_id';
  static const String _keyRatingDoneByTripId = 'rating_done_by_trip_id';

  static const String _keyDriverCacheByTripId = 'driver_cache_by_trip_id';
  static const String _keyActiveTripUiSnapshot = 'active_trip_ui_snapshot';

  static Future<void> saveActiveTripId(String tripId) async {
    await _storage.write(key: _keyActiveTripId, value: tripId);
  }

  static Future<String?> getActiveTripId() async {
    return _storage.read(key: _keyActiveTripId);
  }

  static Future<void> clearActiveTripId() async {
    await _storage.delete(key: _keyActiveTripId);
    await _storage.delete(key: _keyActiveTripUiSnapshot);
  }

  /// Contexto de UI del viaje activo (O/D, cotización) para rehidratar al reabrir.
  static Future<void> saveActiveTripUiSnapshot({
    required String tripId,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? originLabel,
    String? destLabel,
    required QuoteResponse quote,
    required QuoteOption selectedOption,
  }) async {
    final map = <String, dynamic>{
      'tripId': tripId,
      'originLat': originLat,
      'originLng': originLng,
      'destLat': destLat,
      'destLng': destLng,
      'originLabel': originLabel,
      'destLabel': destLabel,
      'quote': quote.toJson(),
      'selectedServiceTypeId': selectedOption.serviceTypeId,
    };
    await _storage.write(key: _keyActiveTripUiSnapshot, value: jsonEncode(map));
  }

  static Future<Map<String, dynamic>?> getActiveTripUiSnapshot() async {
    final raw = await _storage.read(key: _keyActiveTripUiSnapshot);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isRatingDone(String tripId) async {
    final raw = await _storage.read(key: _keyRatingDoneByTripId);
    if (raw == null || raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      final value = decoded[tripId];
      if (value == true) return true;
      if (value is String) return value == 'true';
      if (value is num) return value == 1;
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setRatingDone(String tripId, bool done) async {
    final raw = await _storage.read(key: _keyRatingDoneByTripId);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map = decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }
    map[tripId] = done;
    await _storage.write(key: _keyRatingDoneByTripId, value: jsonEncode(map));
  }

  static Future<void> clearRatingForTrip(String tripId) async {
    final raw = await _storage.read(key: _keyRatingDoneByTripId);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.remove(tripId);
      await _storage.write(key: _keyRatingDoneByTripId, value: jsonEncode(decoded));
    } catch (_) {}
  }

  static Future<void> cacheDriverInfo({
    required String tripId,
    required String? driverName,
    required String? carColor,
    required String? carPlate,
    required String? carModel,
    String? driverPhotoUrl,
    String? driverPhotoExpiresAt,
  }) async {
    final raw = await _storage.read(key: _keyDriverCacheByTripId);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map = decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }

    map[tripId] = {
      'driverName': driverName,
      'carColor': carColor,
      'carPlate': carPlate,
      'carModel': carModel,
      'driverPhotoUrl': driverPhotoUrl,
      'driverPhotoExpiresAt': driverPhotoExpiresAt,
    };
    await _storage.write(key: _keyDriverCacheByTripId, value: jsonEncode(map));
  }

  static Future<Map<String, String?>?> getCachedDriverInfo(String tripId) async {
    final raw = await _storage.read(key: _keyDriverCacheByTripId);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final entry = decoded[tripId];
      if (entry is! Map) return null;
      return {
        'driverName': entry['driverName']?.toString(),
        'carColor': entry['carColor']?.toString(),
        'carPlate': entry['carPlate']?.toString(),
        'carModel': entry['carModel']?.toString(),
        'driverPhotoUrl': entry['driverPhotoUrl']?.toString(),
        'driverPhotoExpiresAt': entry['driverPhotoExpiresAt']?.toString(),
      };
    } catch (_) {
      return null;
    }
  }
}

