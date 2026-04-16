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
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrlTripsRest,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

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
    String? routeOverviewEncoded,
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
      if (routeOverviewEncoded != null &&
          routeOverviewEncoded.trim().isNotEmpty)
        'routeOverviewEncoded': routeOverviewEncoded.trim(),
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

  Future<void> submitPassengerTripRating({
    required String tripId,
    required int stars,
    String? commentText,
    List<String>? feedbackCodes,
  }) async {
    await _dio.post(
      '/passengers/trips/$tripId/rating',
      data: {
        'stars': stars,
        if (commentText != null && commentText.trim().isNotEmpty)
          'commentText': commentText.trim(),
        'feedbackCodes': ?feedbackCodes,
      },
    );
  }

  Future<List<TripRatingFeedbackItem>> getPassengerRatingFeedbackCatalog({
    required int stars,
  }) async {
    final response = await _dio.get(
      '/passengers/trips/rating-feedback-catalog',
      queryParameters: {'stars': stars},
    );
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final itemsRaw = data['items'] as List<dynamic>? ?? const [];
    return itemsRaw
        .whereType<Map>()
        .map(
          (e) => TripRatingFeedbackItem.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList(growable: false);
  }

  /// GET /passengers/trips/recent-places
  Future<List<PassengerRecentPlace>> getPassengerRecentPlaces({
    int limit = 5,
  }) async {
    final response = await _dio.get(
      '/passengers/trips/recent-places',
      queryParameters: {'limit': limit},
    );
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final placesRaw = data['places'] as List<dynamic>? ?? const [];
    return placesRaw
        .whereType<Map>()
        .map((e) => PassengerRecentPlace.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PassengerTripHistoryResponse> getPassengerTripHistory({
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/passengers/trips/history',
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        'limit': limit,
        'offset': offset,
      },
    );
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return PassengerTripHistoryResponse.fromJson(data);
  }

  Future<List<PassengerSavedPlace>> getPassengerSavedPlaces({
    int limit = 12,
  }) async {
    final response = await _dio.get(
      '/passengers/places/saved',
      queryParameters: {'limit': limit},
    );
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final placesRaw = data['places'] as List<dynamic>? ?? const [];
    return placesRaw
        .whereType<Map>()
        .map((e) => PassengerSavedPlace.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PassengerSavedPlace> savePassengerPlace({
    required String label,
    required String address,
    required double lat,
    required double lng,
    bool isFavorite = false,
  }) async {
    final response = await _dio.post(
      '/passengers/places/saved',
      data: {
        'label': label,
        'address': address,
        'lat': lat,
        'lng': lng,
        'isFavorite': isFavorite,
      },
    );
    final body = response.data as Map<String, dynamic>? ?? const {};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return PassengerSavedPlace.fromJson(data);
  }

  Future<void> deletePassengerSavedPlace(String placeId) async {
    await _dio.delete('/passengers/places/saved/$placeId');
  }

  Future<PassengerSavedPlace> updatePassengerSavedPlace({
    required String placeId,
    String? label,
    String? address,
    double? lat,
    double? lng,
    bool? isFavorite,
  }) async {
    final data = <String, dynamic>{};
    if (label != null) data['label'] = label;
    if (address != null) data['address'] = address;
    if (lat != null && lng != null) {
      data['lat'] = lat;
      data['lng'] = lng;
    }
    if (isFavorite != null) data['isFavorite'] = isFavorite;
    final response = await _dio.patch(
      '/passengers/places/saved/$placeId',
      data: data,
    );
    final body = response.data as Map<String, dynamic>? ?? const {};
    final payload = body['data'] as Map<String, dynamic>? ?? const {};
    return PassengerSavedPlace.fromJson(payload);
  }
}

class PassengerRecentPlace {
  const PassengerRecentPlace({
    required this.placeType,
    required this.label,
    this.subtitle,
    required this.lat,
    required this.lng,
  });

  final String placeType; // origin | destination
  final String label;
  final String? subtitle;
  final double lat;
  final double lng;

  factory PassengerRecentPlace.fromJson(Map<String, dynamic> json) {
    final latRaw = json['lat'];
    final lngRaw = json['lng'];
    final lat = latRaw is num
        ? latRaw.toDouble()
        : double.tryParse('$latRaw') ?? 0.0;
    final lng = lngRaw is num
        ? lngRaw.toDouble()
        : double.tryParse('$lngRaw') ?? 0.0;
    final subtitleRaw = json['subtitle']?.toString().trim();
    return PassengerRecentPlace(
      placeType: json['placeType']?.toString() ?? 'origin',
      label: json['label']?.toString() ?? '',
      subtitle: subtitleRaw == null || subtitleRaw.isEmpty ? null : subtitleRaw,
      lat: lat,
      lng: lng,
    );
  }
}

class PassengerSavedPlace {
  const PassengerSavedPlace({
    required this.id,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
    required this.isFavorite,
  });

  final String id;
  final String label;
  final String address;
  final double lat;
  final double lng;
  final bool isFavorite;

  factory PassengerSavedPlace.fromJson(Map<String, dynamic> json) {
    final latRaw = json['lat'];
    final lngRaw = json['lng'];
    return PassengerSavedPlace(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      lat: latRaw is num
          ? latRaw.toDouble()
          : double.tryParse('$latRaw') ?? 0.0,
      lng: lngRaw is num
          ? lngRaw.toDouble()
          : double.tryParse('$lngRaw') ?? 0.0,
      isFavorite: json['isFavorite'] == true,
    );
  }
}

class PassengerTripHistoryResponse {
  const PassengerTripHistoryResponse({
    required this.trips,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<PassengerTripHistoryItem> trips;
  final int total;
  final int limit;
  final int offset;

  factory PassengerTripHistoryResponse.fromJson(Map<String, dynamic> json) {
    final tripsRaw = json['trips'] as List<dynamic>? ?? const [];
    final totalRaw = json['total'];
    final limitRaw = json['limit'];
    final offsetRaw = json['offset'];
    return PassengerTripHistoryResponse(
      trips: tripsRaw
          .whereType<Map>()
          .map(
            (e) =>
                PassengerTripHistoryItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(growable: false),
      total: totalRaw is num
          ? totalRaw.toInt()
          : int.tryParse('$totalRaw') ?? 0,
      limit: limitRaw is num
          ? limitRaw.toInt()
          : int.tryParse('$limitRaw') ?? 20,
      offset: offsetRaw is num
          ? offsetRaw.toInt()
          : int.tryParse('$offsetRaw') ?? 0,
    );
  }
}

class PassengerTripHistoryItem {
  const PassengerTripHistoryItem({
    required this.id,
    required this.status,
    this.estimatedPrice,
    this.finalPrice,
    this.originAddress,
    this.destinationAddress,
    this.driverIdentityUserId,
    this.driverName,
    this.driverCarModel,
    this.driverCarPlate,
    this.driverCarColor,
    this.createdAt,
    this.updatedAt,
    this.currencyCode,
  });

  final String id;
  final String status;
  final double? estimatedPrice;
  final double? finalPrice;
  final String? originAddress;
  final String? destinationAddress;
  final String? driverIdentityUserId;
  final String? driverName;
  final String? driverCarModel;
  final String? driverCarPlate;
  final String? driverCarColor;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? currencyCode;

  factory PassengerTripHistoryItem.fromJson(Map<String, dynamic> json) {
    double? parseNum(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return PassengerTripHistoryItem(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      estimatedPrice: parseNum(json['estimatedPrice']),
      finalPrice: parseNum(json['finalPrice']),
      originAddress: json['originAddress']?.toString(),
      destinationAddress: json['destinationAddress']?.toString(),
      driverIdentityUserId: json['driverIdentityUserId']?.toString(),
      driverName: json['driverName']?.toString(),
      driverCarModel: json['driverCarModel']?.toString(),
      driverCarPlate: json['driverCarPlate']?.toString(),
      driverCarColor: json['driverCarColor']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse('${json['createdAt']}')
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse('${json['updatedAt']}')
          : null,
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString(),
    );
  }
}

/// Respuesta de POST /passengers/trips
class CreateTripResponse {
  const CreateTripResponse({
    required this.tripId,
    required this.status,
    this.estimatedPrice,
    this.offers,
    this.currencyCode,
  });

  final String tripId;
  final String status;
  final double? estimatedPrice;
  final List<CreateTripOffer>? offers;
  final String? currencyCode;

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
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString(),
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
    this.driverName,
    this.carModel,
    this.carPlate,
    this.carColor,
    this.driverRating,
    this.driverRatingsCount,
    this.currencyCode,
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
  final String? driverName;
  final String? carModel;
  final String? carPlate;
  final String? carColor;
  final double? driverRating;
  final int? driverRatingsCount;
  final String? currencyCode;

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
    final rawPhoto =
        json['profilePhotoUrl']?.toString() ??
        json['picture_profile']?.toString() ??
        json['driverPhotoUrl']?.toString();
    final rawExpiresAt = json['profilePhotoExpiresAt']?.toString();
    final photo = (rawPhoto != null && rawPhoto.trim().isNotEmpty)
        ? rawPhoto.trim()
        : null;
    final expiresAt = (rawExpiresAt != null && rawExpiresAt.trim().isNotEmpty)
        ? DateTime.tryParse(rawExpiresAt.trim())
        : null;
    final driverObj = json['driver'];
    Map<String, dynamic>? driverMap;
    if (driverObj is Map) {
      driverMap = Map<String, dynamic>.from(driverObj);
    }
    String? pickStr(dynamic v) {
      final s = v?.toString().trim();
      if (s == null || s.isEmpty) return null;
      return s;
    }

    final driverName =
        pickStr(json['fullName']) ??
        pickStr(json['driverName']) ??
        pickStr(driverMap?['fullName']) ??
        pickStr(driverMap?['driverName']) ??
        pickStr(driverMap?['displayName']) ??
        pickStr(driverMap?['display_name']);
    final carModel =
        pickStr(json['carModel']) ??
        pickStr(json['car_model']) ??
        pickStr(driverMap?['carModel']) ??
        pickStr(driverMap?['car_model']) ??
        pickStr(driverMap?['model']);
    final carPlate =
        pickStr(json['carPlate']) ??
        pickStr(json['car_plate']) ??
        pickStr(json['plate']) ??
        pickStr(driverMap?['carPlate']) ??
        pickStr(driverMap?['car_plate']) ??
        pickStr(driverMap?['licensePlate']);
    final carColor =
        pickStr(json['carColor']) ??
        pickStr(json['car_color']) ??
        pickStr(driverMap?['carColor']) ??
        pickStr(driverMap?['car_color']) ??
        pickStr(driverMap?['color']);
    final ratingRaw =
        json['driverRating'] ??
        json['averageRating'] ??
        driverMap?['driverRating'];
    final ratingsCountRaw =
        json['driverRatingsCount'] ?? driverMap?['ratingsCount'];
    final driverRating = ratingRaw is num
        ? ratingRaw.toDouble()
        : double.tryParse('$ratingRaw');
    final driverRatingsCount = ratingsCountRaw is num
        ? ratingsCountRaw.toInt()
        : int.tryParse('$ratingsCountRaw');

    return TripStatusResponse(
      tripId: json['tripId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      driverLat: dLat,
      driverLng: dLng,
      driverBearing: dBearing,
      driverPhotoUrl: photo,
      driverPhotoExpiresAt: expiresAt,
      driverName: driverName,
      carModel: carModel,
      carPlate: carPlate,
      carColor: carColor,
      driverRating: driverRating,
      driverRatingsCount: driverRatingsCount,
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString(),
    );
  }
}

class CreateTripOffer {
  const CreateTripOffer({
    required this.driverId,
    this.offeredPrice,
    this.etaMinutes,
    this.currencyCode,
  });

  final int driverId;
  final double? offeredPrice;
  final int? etaMinutes;
  final String? currencyCode;

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
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString(),
    );
  }
}

class TripRatingFeedbackItem {
  const TripRatingFeedbackItem({
    required this.code,
    required this.label,
    required this.minStars,
    required this.maxStars,
  });

  final String code;
  final String label;
  final int minStars;
  final int maxStars;

  factory TripRatingFeedbackItem.fromJson(Map<String, dynamic> json) {
    final minRaw = json['minStars'];
    final maxRaw = json['maxStars'];
    return TripRatingFeedbackItem(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      minStars: minRaw is num ? minRaw.toInt() : int.tryParse('$minRaw') ?? 1,
      maxStars: maxRaw is num ? maxRaw.toInt() : int.tryParse('$maxRaw') ?? 5,
    );
  }
}
