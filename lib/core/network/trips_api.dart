import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../auth/auth_service.dart';
import '../../data/models/nearby_driver.dart';
import '../../data/models/quote_response.dart';
import '../../data/models/passenger_trip_sync_response.dart';

/// Cliente para el backend de viajes (quote, trips, nearby-drivers).
/// Usar el token del pasajero en cada llamada.
/// Ante 401 (token expirado/inválido) cierra sesión y dispara [AuthService.onSessionExpired].
class TripsApi {
  TripsApi({required String token})
      : _dio = _createDio(token, baseUrl: AppConfig.baseUrlTripsRest),
        _dioFallback = _createDio(token, baseUrl: AppConfig.baseUrlTripsRestFallback);

  static Dio _createDio(String token, {required String baseUrl}) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
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
  final Dio _dioFallback;

  bool _shouldFallback(DioException e) {
    final status = e.response?.statusCode;
    if (status == 502 || status == 503 || status == 504) return true;
    // Algunos entornos tienen rutas REST solo en el API principal (auth) y
    // responden 404 en el host de websockets. En ese caso reintentamos.
    if (status == 404) {
      final data = e.response?.data;
      if (data is Map) {
        final err = data['error'];
        if (err is Map) {
          final code = err['code']?.toString();
          final msg = err['message']?.toString().toLowerCase();
          if (code == 'NOT_FOUND' || (msg != null && msg.contains('ruta no encontrada'))) {
            return true;
          }
        }
      }
      if (data is String && data.toLowerCase().contains('ruta no encontrada')) return true;
    }
    final data = e.response?.data;
    if (data is String && data.contains('502 Bad Gateway')) return true;
    return false;
  }

  /// GET /passengers/nearby-drivers
  Future<NearbyDriversResponse> getNearbyDrivers({
    required double lat,
    required double lng,
    double radiusKm = 5,
    int limit = 20,
  }) async {
    Response<dynamic> response;
    try {
      response = await _dio.get(
        '/passengers/nearby-drivers',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radiusKm': radiusKm,
          'limit': limit,
        },
      );
    } on DioException catch (e) {
      if (!_shouldFallback(e)) rethrow;
      response = await _dioFallback.get(
        '/passengers/nearby-drivers',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radiusKm': radiusKm,
          'limit': limit,
        },
      );
    }
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return NearbyDriversResponse.fromJson(data);
  }

  /// GET /passengers/trips/:tripId
  ///
  /// Sincroniza el estado actual del viaje para el pasajero.
  Future<PassengerTripSyncResponse?> syncPassengerTrip(String tripId) async {
    Response<dynamic> response;
    try {
      response = await _dio.get('/passengers/trips/$tripId');
    } on DioException catch (e) {
      if (!_shouldFallback(e)) rethrow;
      response = await _dioFallback.get('/passengers/trips/$tripId');
    }
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
    Response<dynamic> response;
    try {
      response = await _dio.post(
        '/passengers/trips/quote',
        data: {
          'origin': {'lat': originLat, 'lng': originLng},
          'destination': {'lat': destinationLat, 'lng': destinationLng},
        },
      );
    } on DioException catch (e) {
      if (!_shouldFallback(e)) rethrow;
      response = await _dioFallback.post(
        '/passengers/trips/quote',
        data: {
          'origin': {'lat': originLat, 'lng': originLng},
          'destination': {'lat': destinationLat, 'lng': destinationLng},
        },
      );
    }
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
    Response<dynamic> response;
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
    try {
      response = await _dio.post('/passengers/trips', data: payload);
    } on DioException catch (e) {
      if (!_shouldFallback(e)) rethrow;
      response = await _dioFallback.post('/passengers/trips', data: payload);
    }
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return CreateTripResponse.fromJson(data);
  }

  /// GET /passengers/trips/:tripId
  ///
  /// Se usa para rehidratar el estado del viaje cuando el socket pudo haber
  /// perdido eventos (p. ej. el conductor finaliza offline).
  Future<TripStatusResponse> getPassengerTripStatus({
    required String tripId,
  }) async {
    Response<dynamic> response;
    try {
      response = await _dio.get('/passengers/trips/$tripId');
    } on DioException catch (e) {
      if (!_shouldFallback(e)) rethrow;
      response = await _dioFallback.get('/passengers/trips/$tripId');
    }
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return TripStatusResponse.fromJson(data);
  }

  /// POST /passengers/trips/:tripId/cancel
  ///
  /// Cancela el viaje en servidor (ofertas pendientes + estado), para que los
  /// conductores dejen de ver la solicitud activa.
  Future<void> cancelPassengerTrip({required String tripId}) async {
    try {
      await _dio.post('/passengers/trips/$tripId/cancel');
    } on DioException catch (e) {
      if (!_shouldFallback(e)) rethrow;
      await _dioFallback.post('/passengers/trips/$tripId/cancel');
    }
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
///
/// Contiene el `status` para desbloquear el flujo del pasajero aunque falten
/// eventos por WebSocket.
class TripStatusResponse {
  const TripStatusResponse({
    required this.tripId,
    required this.status,
    this.driverLat,
    this.driverLng,
    this.driverPhotoUrl,
    this.driverPhotoExpiresAt,
  });

  final String tripId;
  final String status;
  /// Última posición conocida del conductor (GET enriquecido; fallback si el socket va atrasado).
  final double? driverLat;
  final double? driverLng;
  /// Foto de perfil del conductor (GET enriquecido; misma fuente que `trip:accepted`).
  final String? driverPhotoUrl;
  final DateTime? driverPhotoExpiresAt;

  factory TripStatusResponse.fromJson(Map<String, dynamic> json) {
    double? dLat;
    double? dLng;
    final dl = json['driverLocation'];
    if (dl is Map) {
      final m = Map<String, dynamic>.from(dl);
      final latRaw = m['lat'];
      final lngRaw = m['lng'];
      if (latRaw is num) dLat = latRaw.toDouble();
      if (latRaw is String) dLat = double.tryParse(latRaw);
      if (lngRaw is num) dLng = lngRaw.toDouble();
      if (lngRaw is String) dLng = double.tryParse(lngRaw);
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
    if (rawId is int) driverId = rawId;
    else if (rawId is String) driverId = int.tryParse(rawId) ?? 0;
    else if (rawId is num) driverId = rawId.toInt();
    final rawEta = json['etaMinutes'];
    int? etaMinutes;
    if (rawEta is int) etaMinutes = rawEta;
    else if (rawEta is String) etaMinutes = int.tryParse(rawEta);
    else if (rawEta is num) etaMinutes = rawEta.toInt();
    final rawOffer = json['offeredPrice'];
    double? offeredPrice;
    if (rawOffer is num) offeredPrice = rawOffer.toDouble();
    if (rawOffer is String) offeredPrice = double.tryParse(rawOffer);
    return CreateTripOffer(
      driverId: driverId,
      offeredPrice: offeredPrice,
      etaMinutes: etaMinutes,
    );
  }
}
