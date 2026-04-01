import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../auth/auth_service.dart';
import '../../data/models/nearby_driver.dart';
import '../../data/models/quote_response.dart';
import '../../data/models/passenger_trip_sync_response.dart';

/// Cliente para el backend de viajes (quote, trips, nearby-drivers) en `app_texi_WebSocket`.
/// Ante 401 cierra sesión y dispara [AuthService.onSessionExpired].
class TripsApi {
  TripsApi({required String token}) : _dio = _createDio(token);

  static Dio _createDio(String token) {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrlTripsRest,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            AuthService.logout();
            AuthService.onSessionExpired?.call();
          }
          return handler.next(error);
        },
      ),
    );
    return dio;
  }

  final Dio _dio;

  /// GET /passengers/nearby-drivers
  Future<NearbyDriversResponse> getNearbyDrivers({
    required double lat,
    required double lng,
    double radiusKm = 5,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/passengers/nearby-drivers',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        'limit': limit,
      },
    );
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return NearbyDriversResponse.fromJson(data);
  }

  /// GET /passengers/trips/:tripId — sincroniza estado actual del viaje.
  Future<PassengerTripSyncResponse?> syncPassengerTrip(String tripId) async {
    final response = await _dio.get('/passengers/trips/$tripId');
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    if (data.isEmpty) return null;
    return PassengerTripSyncResponse.fromJson(data);
  }

  /// POST /passengers/trips/quote
  Future<QuoteResponse> quoteTrip({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final response = await _dio.post(
      '/passengers/trips/quote',
      data: {
        'origin': {'lat': originLat, 'lng': originLng},
        'destination': {'lat': destinationLat, 'lng': destinationLng},
      },
    );
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return QuoteResponse.fromJson(data);
  }

  /// POST /passengers/trips
  Future<CreateTripResponse> createTrip({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String? originAddress,
    String? destinationAddress,
    required String cityId,
    required int serviceTypeId,
    required double estimatedPrice,
  }) async {
    final payload = {
      'origin': {'lat': originLat, 'lng': originLng},
      'destination': {'lat': destinationLat, 'lng': destinationLng},
      if (originAddress != null && originAddress.trim().isNotEmpty)
        'originAddress': originAddress.trim(),
      if (destinationAddress != null && destinationAddress.trim().isNotEmpty)
        'destinationAddress': destinationAddress.trim(),
      'cityId': cityId,
      'serviceTypeId': serviceTypeId,
      'estimatedPrice': estimatedPrice,
    };
    final response = await _dio.post('/passengers/trips', data: payload);
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return CreateTripResponse.fromJson(data);
  }

  /// GET /passengers/trips/:tripId — rehidratar estado aunque falten eventos WS.
  Future<TripStatusResponse> getPassengerTripStatus({
    required String tripId,
  }) async {
    final response = await _dio.get('/passengers/trips/$tripId');
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return TripStatusResponse.fromJson(data);
  }

  /// POST /passengers/trips/:tripId/cancel
  Future<void> cancelPassengerTrip({required String tripId}) async {
    await _dio.post('/passengers/trips/$tripId/cancel');
  }
}

/// Respuesta de POST /passengers/trips
class CreateTripResponse {
  const CreateTripResponse({
    required this.tripId,
    required this.status,
    this.estimatedPrice,
    this.offers,
  });

  final String tripId;
  final String status;
  final double? estimatedPrice;
  final List<CreateTripOffer>? offers;

  factory CreateTripResponse.fromJson(Map<String, dynamic> json) {
    final offersList = json['offers'] as List<dynamic>? ?? [];
    final rawPrice = json['estimatedPrice'];
    double? estimatedPrice;
    if (rawPrice is num) estimatedPrice = rawPrice.toDouble();
    if (rawPrice is String) estimatedPrice = double.tryParse(rawPrice);
    return CreateTripResponse(
      tripId: json['tripId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      estimatedPrice: estimatedPrice,
      offers: offersList
          .map((e) => CreateTripOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Respuesta mínima de `GET /passengers/trips/:tripId`.
class TripStatusResponse {
  const TripStatusResponse({
    required this.tripId,
    required this.status,
    this.driverLat,
    this.driverLng,
    this.driverBearing,
    this.driverPhotoUrl,
    this.driverPhotoExpiresAt,
  });

  final String tripId;
  final String status;
  /// Última posición conocida del conductor (GET enriquecido si el socket va atrasado).
  final double? driverLat;
  final double? driverLng;
  final double? driverBearing;
  /// Foto de perfil del conductor (GET enriquecido; misma fuente que `trip:accepted`).
  final String? driverPhotoUrl;
  final DateTime? driverPhotoExpiresAt;

  factory TripStatusResponse.fromJson(Map<String, dynamic> json) {
    double? dLat;
    double? dLng;
    double? dBearing;
    final dl = json['driverLocation'];
    if (dl is Map) {
      final m = Map<String, dynamic>.from(dl);
      final latRaw = m['lat'];
      final lngRaw = m['lng'];
      final bearRaw = m['bearing'];
      if (latRaw is num) dLat = latRaw.toDouble();
      if (latRaw is String) dLat = double.tryParse(latRaw);
      if (lngRaw is num) dLng = lngRaw.toDouble();
      if (lngRaw is String) dLng = double.tryParse(lngRaw);
      if (bearRaw is num) dBearing = bearRaw.toDouble();
      if (bearRaw is String) dBearing = double.tryParse(bearRaw);
    }
    final rawPhoto = json['profilePhotoUrl']?.toString() ??
        json['picture_profile']?.toString() ??
        json['driverPhotoUrl']?.toString();
    final rawExpiresAt = json['profilePhotoExpiresAt']?.toString();
    final photo = (rawPhoto != null && rawPhoto.trim().isNotEmpty) ? rawPhoto.trim() : null;
    final expiresAt = (rawExpiresAt != null && rawExpiresAt.trim().isNotEmpty)
        ? DateTime.tryParse(rawExpiresAt.trim())
        : null;
    return TripStatusResponse(
      tripId: json['tripId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      driverLat: dLat,
      driverLng: dLng,
      driverBearing: dBearing,
      driverPhotoUrl: photo,
      driverPhotoExpiresAt: expiresAt,
    );
  }
}

class CreateTripOffer {
  const CreateTripOffer({
    required this.driverId,
    this.offeredPrice,
    this.etaMinutes,
  });

  final int driverId;
  final double? offeredPrice;
  final int? etaMinutes;

  factory CreateTripOffer.fromJson(Map<String, dynamic> json) {
    final rawId = json['driverId'];
    int driverId = 0;
    if (rawId is int) {
      driverId = rawId;
    } else if (rawId is String) {
      driverId = int.tryParse(rawId) ?? 0;
    } else if (rawId is num) {
      driverId = rawId.toInt();
    }
    final rawEta = json['etaMinutes'];
    int? etaMinutes;
    if (rawEta is int) {
      etaMinutes = rawEta;
    } else if (rawEta is String) {
      etaMinutes = int.tryParse(rawEta);
    } else if (rawEta is num) {
      etaMinutes = rawEta.toInt();
    }
    final rawOffer = json['offeredPrice'];
    double? offeredPrice;
    if (rawOffer is num) {
      offeredPrice = rawOffer.toDouble();
    }
    if (rawOffer is String) {
      offeredPrice = double.tryParse(rawOffer);
    }
    return CreateTripOffer(
      driverId: driverId,
      offeredPrice: offeredPrice,
      etaMinutes: etaMinutes,
    );
  }
}
