import 'package:dio/dio.dart';

import '../../core/network/passenger_api_client.dart';

double _num(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class CorridorLaneOption {
  const CorridorLaneOption({
    required this.routeId,
    required this.routeName,
    required this.fromStopId,
    required this.fromName,
    required this.fromLocalityKey,
    required this.baseFare,
    this.fromLatitude = 0,
    this.fromLongitude = 0,
  });

  final String routeId;
  final String routeName;
  final String fromStopId;
  final String fromName;
  final String fromLocalityKey;
  final double baseFare;
  final double fromLatitude;
  final double fromLongitude;

  factory CorridorLaneOption.fromJson(Map<String, dynamic> json) {
    return CorridorLaneOption(
      routeId: json['routeId']?.toString() ?? '',
      routeName: json['routeName']?.toString() ?? '',
      fromStopId: json['fromStopId']?.toString() ?? '',
      fromName: json['fromName']?.toString() ?? '',
      fromLocalityKey: json['fromLocalityKey']?.toString() ?? '',
      baseFare: _num(json['baseFare']),
      fromLatitude: _num(json['fromLatitude']),
      fromLongitude: _num(json['fromLongitude']),
    );
  }
}

class CorridorCity {
  const CorridorCity({
    required this.key,
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String key;
  final String label;
  final double latitude;
  final double longitude;

  factory CorridorCity.fromJson(Map<String, dynamic> json) {
    return CorridorCity(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CorridorLocality {
  const CorridorLocality({required this.key, required this.cityKey, required this.label});

  final String key;
  final String cityKey;
  final String label;

  factory CorridorLocality.fromJson(Map<String, dynamic> json) {
    return CorridorLocality(
      key: json['key']?.toString() ?? '',
      cityKey: json['cityKey']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class CorridorDestination {
  const CorridorDestination({
    required this.cityKey,
    required this.toStopId,
    required this.toName,
    required this.toRegion,
    required this.toLocality,
    required this.options,
    this.toLatitude = 0,
    this.toLongitude = 0,
  });

  final String cityKey;
  final String toStopId;
  final String toName;
  final String toRegion;
  final String toLocality;
  final double toLatitude;
  final double toLongitude;
  final List<CorridorLaneOption> options;

  CorridorDestination copyWith({List<CorridorLaneOption>? options}) {
    return CorridorDestination(
      cityKey: cityKey,
      toStopId: toStopId,
      toName: toName,
      toRegion: toRegion,
      toLocality: toLocality,
      toLatitude: toLatitude,
      toLongitude: toLongitude,
      options: options ?? this.options,
    );
  }

  factory CorridorDestination.fromJson(Map<String, dynamic> json) {
    final raw = json['options'];
    final options = raw is List
        ? raw
            .whereType<Map>()
            .map((item) => CorridorLaneOption.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.fromStopId.isNotEmpty)
            .toList()
        : const <CorridorLaneOption>[];
    return CorridorDestination(
      cityKey: json['cityKey']?.toString() ?? '',
      toStopId: json['toStopId']?.toString() ?? '',
      toName: json['toName']?.toString() ?? '',
      toRegion: json['toRegion']?.toString() ?? '',
      toLocality: json['toLocality']?.toString() ?? '',
      toLatitude: _num(json['toLatitude']),
      toLongitude: _num(json['toLongitude']),
      options: options,
    );
  }
}

class CorridorLanes {
  const CorridorLanes({
    required this.cities,
    required this.destinations,
    this.localities = const [],
  });

  final List<CorridorCity> cities;
  final List<CorridorDestination> destinations;
  final List<CorridorLocality> localities;

  factory CorridorLanes.fromJson(Map<String, dynamic> json) {
    List<T> read<T>(Object? raw, T Function(Map<String, dynamic>) map) {
      if (raw is! List) return <T>[];
      return raw.whereType<Map>().map((item) => map(Map<String, dynamic>.from(item))).toList();
    }

    return CorridorLanes(
      cities: read(json['cities'], CorridorCity.fromJson).where((item) => item.key.isNotEmpty).toList(),
      localities: read(json['localities'], CorridorLocality.fromJson).where((item) => item.key.isNotEmpty).toList(),
      destinations: read(json['destinations'], CorridorDestination.fromJson)
          .where((item) => item.toStopId.isNotEmpty && item.options.isNotEmpty)
          .toList(),
    );
  }
}

class CorridorPlace {
  const CorridorPlace({required this.id, required this.name});

  final String id;
  final String name;

  factory CorridorPlace.fromJson(Map<String, dynamic> json) {
    return CorridorPlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class CorridorDeparture {
  const CorridorDeparture({
    required this.tripId,
    required this.routeName,
    required this.departureAt,
    required this.fareAmount,
    required this.seatsLeft,
    required this.fromStopId,
    required this.toStopId,
    required this.fromName,
    required this.toName,
    required this.givenName,
    required this.plate,
    required this.color,
    required this.model,
    this.status = 'available',
    this.fromLatitude = 0,
    this.fromLongitude = 0,
  });

  final String tripId;
  final String routeName;
  final DateTime? departureAt;
  final double fareAmount;
  final int seatsLeft;
  final String fromStopId;
  final String toStopId;
  final String fromName;
  final String toName;
  final String givenName;
  final String plate;
  final String color;
  final String model;
  final String status;
  final double fromLatitude;
  final double fromLongitude;

  bool get canBook => status == 'available';

  factory CorridorDeparture.fromJson(Map<String, dynamic> json) {
    final card = json['passengerCard'];
    final map = card is Map ? Map<String, dynamic>.from(card) : const <String, dynamic>{};
    return CorridorDeparture(
      tripId: json['tripId']?.toString() ?? '',
      routeName: json['routeName']?.toString() ?? '',
      departureAt: DateTime.tryParse(json['departureAt']?.toString() ?? ''),
      fareAmount: _num(json['fareAmount']),
      seatsLeft: _num(json['seatsLeft']).toInt(),
      fromStopId: json['fromStopId']?.toString() ?? '',
      toStopId: json['toStopId']?.toString() ?? '',
      fromName: json['fromName']?.toString() ?? '',
      toName: json['toName']?.toString() ?? '',
      givenName: map['givenName']?.toString() ?? '',
      plate: map['plate']?.toString() ?? '',
      color: map['color']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      status: json['status']?.toString() ?? 'available',
      fromLatitude: _num(json['fromLatitude']),
      fromLongitude: _num(json['fromLongitude']),
    );
  }
}

class CorridorBooking {
  const CorridorBooking({
    required this.id,
    required this.publicCode,
    required this.seatCount,
    required this.status,
    required this.fareAmount,
    required this.departureAt,
    required this.routeName,
    required this.fromName,
    required this.toName,
    this.givenName = '',
    this.plate = '',
    this.color = '',
    this.model = '',
    this.fromLatitude = 0,
    this.fromLongitude = 0,
  });

  final String id;
  final String publicCode;
  final int seatCount;
  final String status;
  final double fareAmount;
  final DateTime? departureAt;
  final String routeName;
  final String fromName;
  final String toName;
  final String givenName;
  final String plate;
  final String color;
  final String model;
  final double fromLatitude;
  final double fromLongitude;

  bool get isOpen =>
      status == 'pending' || status == 'confirmed' || status == 'boarded' || status == 'in_trip';

  factory CorridorBooking.fromJson(Map<String, dynamic> json) {
    final card = json['passengerCard'];
    final map = card is Map ? Map<String, dynamic>.from(card) : const <String, dynamic>{};
    return CorridorBooking(
      id: json['id']?.toString() ?? '',
      publicCode: json['publicCode']?.toString() ?? '',
      seatCount: _num(json['seatCount']).toInt(),
      status: json['status']?.toString() ?? '',
      fareAmount: _num(json['fareAmount']),
      departureAt: DateTime.tryParse(json['departureAt']?.toString() ?? ''),
      routeName: json['routeName']?.toString() ?? '',
      fromName: json['fromName']?.toString() ?? '',
      toName: json['toName']?.toString() ?? '',
      givenName: map['givenName']?.toString() ?? '',
      plate: map['plate']?.toString() ?? '',
      color: map['color']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      fromLatitude: _num(json['fromLatitude']),
      fromLongitude: _num(json['fromLongitude']),
    );
  }
}

class CorridorBookingCreated {
  const CorridorBookingCreated({
    required this.id,
    required this.publicCode,
    required this.seatCount,
    required this.status,
    required this.fareAmount,
  });

  final String id;
  final String publicCode;
  final int seatCount;
  final String status;
  final double fareAmount;
}

class PassengerCorridorRepository {
  PassengerCorridorRepository(this._client);

  final PassengerApiClient _client;

  Future<CorridorLanes> lanes() async {
    final response = await _client.getAuth<Map<String, dynamic>>(path: '/corridor/lanes');
    final data = PassengerApiClient.parseSuccessData(response.data);
    return CorridorLanes.fromJson(data);
  }

  Future<List<CorridorPlace>> places() async {
    final response = await _client.getAuth<Map<String, dynamic>>(path: '/corridor/places');
    final data = PassengerApiClient.parseSuccessData(response.data);
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => CorridorPlace.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<CorridorDeparture>> departures({
    required String fromStopId,
    required String toStopId,
    required String date,
  }) async {
    final response = await _client.getAuth<Map<String, dynamic>>(
      path: '/corridor/departures',
      queryParameters: {
        'fromStopId': fromStopId,
        'toStopId': toStopId,
        'date': date,
      },
    );
    final data = PassengerApiClient.parseSuccessData(response.data);
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => CorridorDeparture.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<CorridorBooking>> mine() async {
    final response = await _client.getAuth<Map<String, dynamic>>(path: '/corridor/bookings');
    final data = PassengerApiClient.parseSuccessData(response.data);
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => CorridorBooking.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CorridorBookingCreated> book({
    required String tripId,
    required String fromStopId,
    required String toStopId,
    required int seatCount,
    required String idempotencyKey,
  }) async {
    final response = await _client.postAuth<Map<String, dynamic>>(
      path: '/corridor/bookings',
      data: {
        'tripId': tripId,
        'fromStopId': fromStopId,
        'toStopId': toStopId,
        'seatCount': seatCount,
        'idempotencyKey': idempotencyKey,
      },
    );
    final data = PassengerApiClient.parseSuccessData(response.data);
    final item = data['item'];
    final map = item is Map ? Map<String, dynamic>.from(item) : const <String, dynamic>{};
    return CorridorBookingCreated(
      id: map['id']?.toString() ?? '',
      publicCode: map['publicCode']?.toString() ?? '',
      seatCount: _num(map['seatCount']).toInt(),
      status: map['status']?.toString() ?? 'confirmed',
      fareAmount: _num(map['fareAmount']),
    );
  }

  Future<void> cancel(String bookingId) async {
    final response = await _client.postAuth<Map<String, dynamic>>(
      path: '/corridor/bookings/$bookingId/cancel',
    );
    PassengerApiClient.parseSuccessData(response.data);
  }
}

String corridorErrorText(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
  }
  if (error is PassengerApiResponseException) {
    return error.message ?? fallback;
  }
  return fallback;
}
