import 'dart:async';
import 'package:dio/dio.dart';
import 'dart:math';
import '../analytics/passenger_marketing_analytics.dart';
import 'passenger_http_resilience.dart' as passenger_http;
import 'passenger_resilience_telemetry_service.dart';
import '../../data/models/nearby_driver.dart';
import '../../data/models/quote_response.dart';
import '../../data/models/passenger_trip_sync_response.dart';
import '../../features/trip/passenger_trip_vehicle_info.dart';
import '../../features/trip/trip_cancel_reason.dart';

class TripsApi {
  TripsApi({required String token})
      : _dio = passenger_http.buildPassengerTripsAuthedDio(token: token);
  static const int _defaultCreateRetryAfterMs = 1200;

  final Dio _dio;

  static int? retryAfterMsFromResponse(
    dynamic data,
    Headers? headers,
  ) =>
      passenger_http.retryAfterMsFromResponse(data, headers);

  static int retryAfterMsForCreateTrip(DioException e) {
    final fromResp = retryAfterMsFromResponse(e.response?.data, e.response?.headers);
    if (fromResp != null && fromResp > 0) return fromResp;
    return _defaultCreateRetryAfterMs;
  }

  Future<Response<T>> _requestWithRetry<T>({
    required Future<Response<T>> Function() operation,
    required String flow,
    required String endpoint,
    int maxAttempts = 3,
    int baseDelayMs = 320,
    int maxDelayMs = 4500,
  }) {
    return passenger_http.requestWithRetry<Response<T>>(
      operation: operation,
      flow: flow,
      endpoint: endpoint,
      maxAttempts: maxAttempts,
      baseDelayMs: baseDelayMs,
      maxDelayMs: maxDelayMs,
    );
  }

  Future<Response<dynamic>> _postQuoteWithRetry({
    required Map<String, dynamic> payload,
  }) async {
    const maxAttempts = 3;
    int attempt = 0;
    while (true) {
      attempt += 1;
      try {
        return await _dio.post('/passengers/trips/quote', data: payload);
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        final isRetryableStatus = status == 429 || status >= 500;
        final isTransientNetwork =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown;
        final shouldRetry =
            attempt < maxAttempts && (isRetryableStatus || isTransientNetwork);
        if (!shouldRetry) {
          unawaited(
            PassengerResilienceTelemetryService.sendEvent(
              flow: 'trip_quote',
              endpoint: '/passengers/trips/quote',
              event: 'retry_exhausted',
              attempt: attempt,
              statusCode: e.response?.statusCode,
            ),
          );
          rethrow;
        }

        final retryAfterMs = retryAfterMsFromResponse(e.response?.data, e.response?.headers);
        final backoffBase = 350 * (1 << (attempt - 1));
        final jitter = Random().nextInt(220);
        final waitMs = max(
          retryAfterMs ?? 0,
          backoffBase + jitter,
        ).clamp(300, 4000).toInt();
        final statusCode = e.response?.statusCode;
        unawaited(
          PassengerResilienceTelemetryService.sendEvent(
            flow: 'trip_quote',
            endpoint: '/passengers/trips/quote',
            event: statusCode == 429 ? 'rate_limited' : 'retry_attempt',
            attempt: attempt,
            waitMs: waitMs,
            statusCode: statusCode,
          ),
        );
        await Future<void>.delayed(Duration(milliseconds: waitMs));
      }
    }
  }

  Future<NearbyDriversResponse> getNearbyDrivers({
    required double lat,
    required double lng,
    double radiusKm = 5,
    int limit = 20,
  }) async {
    final response = await _requestWithRetry<Map<String, dynamic>>(
      flow: 'trip_discovery',
      endpoint: '/passengers/nearby-drivers',
      operation: () => _dio.get(
        '/passengers/nearby-drivers',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radiusKm': radiusKm,
          'limit': limit,
        },
      ),
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return NearbyDriversResponse.fromJson(data);
  }

  Future<PassengerTripSyncResponse?> syncPassengerTrip(String tripId) async {
    final response = await _requestWithRetry<Map<String, dynamic>>(
      flow: 'trip_sync',
      endpoint: '/passengers/trips/:tripId',
      operation: () => _dio.get('/passengers/trips/$tripId'),
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    if (data.isEmpty) return null;
    return PassengerTripSyncResponse.fromJson(data);
  }

  Future<QuoteResponse> quoteTrip({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String? deviceId,
    String? promoCode,
  }) async {
    final response = await _postQuoteWithRetry(
      payload: {
        'origin': {'lat': originLat, 'lng': originLng},
        'destination': {'lat': destinationLat, 'lng': destinationLng},
        if (deviceId != null && deviceId.trim().isNotEmpty)
          'deviceId': deviceId.trim(),
        if (promoCode != null && promoCode.trim().isNotEmpty)
          'promoCode': promoCode.trim(),
      },
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return QuoteResponse.fromJson(data);
  }

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
    String paymentMethod = 'cash',
    List<String> tripExtras = const [],
    List<String> tripSpecials = const [],
    String? deviceId,
    String? promoCode,
    double? passengerOfferAmount,
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
      'paymentMethod': paymentMethod.trim().isEmpty ? 'cash' : paymentMethod.trim(),
      'tripExtras': tripExtras,
      'tripSpecials': tripSpecials,
      if (deviceId != null && deviceId.trim().isNotEmpty)
        'deviceId': deviceId.trim(),
      if (promoCode != null && promoCode.trim().isNotEmpty)
        'promoCode': promoCode.trim(),
      if (passengerOfferAmount != null) 'passengerOfferAmount': passengerOfferAmount,
    };
    final response = await _dio.post('/passengers/trips', data: payload);
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final created = CreateTripResponse.fromJson(data);
    if (created.tripId.trim().isNotEmpty) {
      PassengerMarketingAnalytics.logRideRequest();
    }
    return created;
  }

  Future<Map<String, dynamic>> listFareBids(String tripId) async {
    final response = await _dio.get('/passengers/trips/$tripId/bids');
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<void> acceptFareBid({
    required String tripId,
    required String negotiationId,
  }) async {
    await _dio.post('/passengers/trips/$tripId/bids/$negotiationId/accept');
  }

  Future<void> declineFareBid({
    required String tripId,
    required String negotiationId,
  }) async {
    await _dio.post('/passengers/trips/$tripId/bids/$negotiationId/decline');
  }

  Future<void> raiseFareOffer({
    required String tripId,
    required double amount,
  }) async {
    await _dio.post('/passengers/trips/$tripId/offer', data: {'amount': amount});
  }

  Future<TripStatusResponse> getPassengerTripStatus({
    required String tripId,
  }) async {
    final response = await _requestWithRetry<Map<String, dynamic>>(
      flow: 'trip_sync',
      endpoint: '/passengers/trips/:tripId',
      operation: () => _dio.get('/passengers/trips/$tripId'),
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return TripStatusResponse.fromJson(data);
  }

  Future<void> cancelPassengerTrip({
    required String tripId,
    String? cancelScope,
    String? reasonCode,
    String? reasonNote,
  }) async {
    final scope = cancelScope?.trim();
    final code = reasonCode?.trim();
    final note = reasonNote?.trim();
    final data = <String, dynamic>{
      if (scope != null && scope.isNotEmpty) 'cancelScope': scope,
      if (code != null && code.isNotEmpty) 'reasonCode': code,
      if (note != null && note.isNotEmpty) 'reasonNote': note,
    };
    await _dio.post(
      '/passengers/trips/$tripId/cancel',
      data: data,
    );
    PassengerMarketingAnalytics.logRideCancelled(tripId);
  }

  Future<List<TripCancelReasonItem>> getPassengerTripCancelReasons({
    required String tripId,
    String? locale,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/passengers/trips/$tripId/cancel-reasons',
      queryParameters: <String, dynamic>{
        if (locale != null && locale.trim().isNotEmpty) 'locale': locale.trim(),
      },
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'];
    if (data is! Map) return const [];
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((m) => TripCancelReasonItem.fromJson(Map<String, dynamic>.from(m)))
        .where((e) => e.code.isNotEmpty)
        .toList(growable: false);
  }

  Future<PassengerTripShareLink> createOrReuseTripShareLink({
    required String tripId,
  }) async {
    try {
      final response = await _dio.post('/passengers/trips/$tripId/share-link');
      final body = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      final shareUrl = data['shareUrl']?.toString() ?? '';
      if (shareUrl.isEmpty) {
        throw StateError('SHARE_URL_EMPTY');
      }
      return PassengerTripShareLink(
        token: data['token']?.toString() ?? '',
        shareUrl: shareUrl,
        expiresAt: data['expiresAt']?.toString(),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map
          ? (data['code'] ?? data['error']?.toString())
          : null;
      final message = data is Map
          ? (data['message'] ?? data['error']?['message'])
          : null;
      throw StateError(
        'SHARE_LINK_FAILED status=${e.response?.statusCode} '
        'code=${code ?? e.type} msg=${message ?? e.message}',
      );
    }
  }

  Future<PassengerTripRatingResult> submitPassengerTripRating({
    required String tripId,
    required int stars,
    String? commentText,
    List<String>? feedbackCodes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/passengers/trips/$tripId/rating',
      data: {
        'stars': stars,
        if (commentText != null && commentText.trim().isNotEmpty)
          'commentText': commentText.trim(),
        'feedbackCodes': ?feedbackCodes,
      },
    );
    final data = response.data?['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    return PassengerTripRatingResult(
      claimEligible: map['claimEligible'] == true || map['claim_eligible'] == true,
      claimMaxStars: map['claimMaxStars'] is num
          ? (map['claimMaxStars'] as num).toInt()
          : (map['claim_max_stars'] is num ? (map['claim_max_stars'] as num).toInt() : 2),
    );
  }

  Future<void> submitPassengerTripClaim({
    required String tripId,
    required String message,
    int? stars,
    List<String>? feedbackCodes,
  }) async {
    await _dio.post(
      '/passengers/trips/$tripId/claim',
      data: {
        'message': message,
        'stars': ?stars,
        if (feedbackCodes?.isNotEmpty ?? false) 'feedbackCodes': feedbackCodes,
      },
    );
  }

  Future<({int cooldownSec, String sentAt})> postPassengerEnRoute({
    required String tripId,
  }) async {
    final response = await _requestWithRetry<Map<String, dynamic>>(
      flow: 'trip_en_route',
      endpoint: '/passengers/trips/:tripId/passenger-en-route',
      maxAttempts: 1,
      operation: () => _dio.post('/passengers/trips/$tripId/passenger-en-route'),
    );
    final data = response.data?['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    final cooldown = map['cooldownSec'] is num
        ? (map['cooldownSec'] as num).toInt()
        : int.tryParse('${map['cooldownSec']}') ?? 45;
    return (
      cooldownSec: cooldown.clamp(15, 300),
      sentAt: '${map['sentAt'] ?? ''}',
    );
  }

  Future<List<TripRatingFeedbackItem>> getPassengerRatingFeedbackCatalog({
    required int stars,
  }) async {
    final response = await _requestWithRetry<Map<String, dynamic>>(
      flow: 'trip_rating',
      endpoint: '/passengers/trips/rating-feedback-catalog',
      maxAttempts: 1,
      operation: () => _dio.get(
        '/passengers/trips/rating-feedback-catalog',
        queryParameters: {'stars': stars},
      ),
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final itemsRaw = data['items'] as List<dynamic>? ?? const [];
    return itemsRaw
        .whereType<Map>()
        .map(
          (e) => TripRatingFeedbackItem.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList(growable: false);
  }

  Future<List<PassengerRecentPlace>> getPassengerRecentPlaces({
    int limit = 5,
  }) async {
    final response = await _requestWithRetry<Map<String, dynamic>>(
      flow: 'saved_places',
      endpoint: '/passengers/trips/recent-places',
      operation: () => _dio.get(
        '/passengers/trips/recent-places',
        queryParameters: {'limit': limit},
      ),
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    final placesRaw = data['places'] as List<dynamic>? ?? const [];
    return placesRaw
        .whereType<Map>()
        .map((e) => PassengerRecentPlace.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PassengerHomeHub> getPassengerHomeHub({
    double? lat,
    double? lng,
    String? locale,
  }) async {
    final response = await _requestWithRetry<Map<String, dynamic>>(
      flow: 'passenger_home',
      endpoint: '/passengers/home',
      operation: () => _dio.get(
        '/passengers/home',
        queryParameters: {
          'lat': ?lat,
          'lng': ?lng,
          if (locale != null && locale.isNotEmpty) 'locale': locale,
        },
      ),
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return PassengerHomeHub.fromJson(data);
  }

  Future<PassengerTripHistoryResponse> getPassengerTripHistory({
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _requestWithRetry<Map<String, dynamic>>(
      flow: 'trip_history',
      endpoint: '/passengers/trips/history',
      operation: () => _dio.get(
        '/passengers/trips/history',
        queryParameters: {
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
          'limit': limit,
          'offset': offset,
        },
      ),
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return PassengerTripHistoryResponse.fromJson(data);
  }

  Future<List<PassengerSavedPlace>> getPassengerSavedPlaces({
    int limit = 12,
  }) async {
    final response = await _requestWithRetry<Map<String, dynamic>>(
      flow: 'saved_places',
      endpoint: '/passengers/places/saved',
      operation: () => _dio.get(
        '/passengers/places/saved',
        queryParameters: {'limit': limit},
      ),
    );
    final body = response.data ?? const <String, dynamic>{};
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

class PassengerHomeBanner {
  const PassengerHomeBanner({
    required this.id,
    required this.imageUrl,
    this.imageExpiresAt,
  });

  final String id;
  final String imageUrl;
  final String? imageExpiresAt;

  factory PassengerHomeBanner.fromJson(Map<String, dynamic> json) {
    return PassengerHomeBanner(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      imageExpiresAt: json['imageExpiresAt']?.toString() ??
          json['image_expires_at']?.toString(),
    );
  }
}

class PassengerHomeAirport {
  const PassengerHomeAirport({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.code,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String? code;
  final double lat;
  final double lng;
  final double? distanceKm;

  factory PassengerHomeAirport.fromJson(Map<String, dynamic> json) {
    final latRaw = json['lat'];
    final lngRaw = json['lng'];
    final distRaw = json['distanceKm'] ?? json['distance_km'];
    return PassengerHomeAirport(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      lat: latRaw is num ? latRaw.toDouble() : double.tryParse('$latRaw') ?? 0,
      lng: lngRaw is num ? lngRaw.toDouble() : double.tryParse('$lngRaw') ?? 0,
      distanceKm: distRaw is num
          ? distRaw.toDouble()
          : double.tryParse('$distRaw'),
    );
  }
}

class PassengerHomeHub {
  const PassengerHomeHub({
    required this.banners,
    this.landingUrl,
    this.nearestAirport,
  });

  final List<PassengerHomeBanner> banners;
  final String? landingUrl;
  final PassengerHomeAirport? nearestAirport;

  factory PassengerHomeHub.fromJson(Map<String, dynamic> json) {
    final raw = json['banners'] as List<dynamic>? ?? const [];
    return PassengerHomeHub(
      banners: raw
          .whereType<Map>()
          .map((e) => PassengerHomeBanner.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty && e.imageUrl.isNotEmpty)
          .toList(growable: false),
      landingUrl: json['landingUrl']?.toString() ?? json['landing_url']?.toString(),
      nearestAirport: json['nearestAirport'] is Map
          ? PassengerHomeAirport.fromJson(
              Map<String, dynamic>.from(json['nearestAirport'] as Map),
            )
          : json['nearest_airport'] is Map
              ? PassengerHomeAirport.fromJson(
                  Map<String, dynamic>.from(json['nearest_airport'] as Map),
                )
              : null,
    );
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

  final String placeType;
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
    this.claimEligible = false,
    this.claimSubmitted = false,
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
  final bool claimEligible;
  final bool claimSubmitted;

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
      claimEligible: json['claimEligible'] == true || json['claim_eligible'] == true,
      claimSubmitted: json['claimSubmitted'] == true || json['claim_submitted'] == true,
    );
  }
}

class CreateTripResponse {
  const CreateTripResponse({
    required this.tripId,
    required this.status,
    this.estimatedPrice,
    this.offers,
    this.currencyCode,
    this.cashDuePassenger,
    this.companyGuaranteeToDriver,
  });

  final String tripId;
  final String status;
  final double? estimatedPrice;
  final List<CreateTripOffer>? offers;
  final String? currencyCode;
  final double? cashDuePassenger;
  final double? companyGuaranteeToDriver;

  factory CreateTripResponse.fromJson(Map<String, dynamic> json) {
    final offersList = json['offers'] as List<dynamic>? ?? [];
    final rawPrice = json['estimatedPrice'];
    double? estimatedPrice;
    if (rawPrice is num) estimatedPrice = rawPrice.toDouble();
    if (rawPrice is String) estimatedPrice = double.tryParse(rawPrice);
    final promo = parseTripPromoAmounts(json);
    return CreateTripResponse(
      tripId: json['tripId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      estimatedPrice: estimatedPrice,
      offers: offersList
          .map((e) => CreateTripOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString(),
      cashDuePassenger: promo?.cashDuePassenger,
      companyGuaranteeToDriver: promo?.companyGuaranteeToDriver,
    );
  }
}

class PassengerTripShareLink {
  const PassengerTripShareLink({
    required this.token,
    required this.shareUrl,
    this.expiresAt,
  });

  final String token;
  final String shareUrl;
  final String? expiresAt;
}

class TripPromoAmounts {
  const TripPromoAmounts({
    required this.cashDuePassenger,
    required this.companyGuaranteeToDriver,
  });

  final double cashDuePassenger;
  final double companyGuaranteeToDriver;
}

double? _parseTripMoneyNum(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

TripPromoAmounts? parseTripPromoAmounts(Map<String, dynamic> json) {
  Map<String, dynamic>? snap;
  final raw = json['promoSnapshot'] ?? json['promo_snapshot'];
  if (raw is Map) snap = Map<String, dynamic>.from(raw);
  final src = snap ?? json;
  final cash = _parseTripMoneyNum(
    src['cashDuePassenger'] ??
        src['cash_due_passenger'] ??
        json['cashDuePassenger'] ??
        json['cash_due_passenger'],
  );
  final guarantee = _parseTripMoneyNum(
    src['companyGuaranteeToDriver'] ??
        src['company_guarantee_to_driver'] ??
        json['companyGuaranteeToDriver'] ??
        json['company_guarantee_to_driver'],
  );
  if (cash == null || guarantee == null || guarantee <= 0) return null;
  return TripPromoAmounts(
    cashDuePassenger: cash,
    companyGuaranteeToDriver: guarantee,
  );
}

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
    this.estimatedPrice,
    this.paymentMethod,
    this.tripExtras = const [],
    this.tripSpecials = const [],
    this.arrivedAt,
    this.waitSec,
    this.waitGraceSec,
    this.cashDuePassenger,
    this.companyGuaranteeToDriver,
  });

  final String tripId;
  final String status;

  final double? driverLat;
  final double? driverLng;
  final double? driverBearing;

  final String? driverPhotoUrl;
  final DateTime? driverPhotoExpiresAt;
  final String? driverName;
  final String? carModel;
  final String? carPlate;
  final String? carColor;
  final double? driverRating;
  final int? driverRatingsCount;
  final String? currencyCode;
  final double? estimatedPrice;
  final String? paymentMethod;
  final List<String> tripExtras;
  final List<String> tripSpecials;
  final DateTime? arrivedAt;
  final int? waitSec;
  final int? waitGraceSec;
  final double? cashDuePassenger;
  final double? companyGuaranteeToDriver;

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
    final carModel = resolvePassengerTripCarModel(json);
    final carPlate = resolvePassengerTripCarPlate(json);
    final carColor = resolvePassengerTripCarColor(json);
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
    final rawPrice = json['estimatedPrice'] ?? json['estimated_price'];
    double? estimatedPrice;
    if (rawPrice is num) estimatedPrice = rawPrice.toDouble();
    if (rawPrice is String) estimatedPrice = double.tryParse(rawPrice);
    final payRaw =
        json['paymentMethod'] ?? json['payment_method'];
    final paymentMethod = payRaw?.toString().trim();
    final promo = parseTripPromoAmounts(json);

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
      estimatedPrice: estimatedPrice,
      paymentMethod: (paymentMethod != null && paymentMethod.isNotEmpty)
          ? paymentMethod
          : null,
      tripExtras: _stringListFromJson(
        json['tripExtras'] ?? json['passenger_extras'],
      ),
      tripSpecials: _stringListFromJson(
        json['tripSpecials'] ?? json['passenger_specials'],
      ),
      arrivedAt: DateTime.tryParse(
        '${json['arrivedAt'] ?? json['arrived_at'] ?? ''}',
      ),
      waitSec: _optionalInt(json['waitSec'] ?? json['wait_sec']),
      waitGraceSec: _optionalInt(
        json['waitGraceSec'] ?? json['wait_grace_sec'],
      ),
      cashDuePassenger: promo?.cashDuePassenger,
      companyGuaranteeToDriver: promo?.companyGuaranteeToDriver,
    );
  }
}

int? _optionalInt(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toInt();
  return int.tryParse('$raw');
}

List<String> _stringListFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => e.toString().trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
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

class PassengerTripRatingResult {
  const PassengerTripRatingResult({
    required this.claimEligible,
    this.claimMaxStars = 2,
  });

  final bool claimEligible;
  final int claimMaxStars;
}
