/// Respuesta de GET /passengers/nearby-drivers.
class NearbyDriversResponse {
  const NearbyDriversResponse({required this.drivers});
  final List<NearbyDriver> drivers;

  factory NearbyDriversResponse.fromJson(Map<String, dynamic> json) {
    final list = json['drivers'] as List<dynamic>? ?? [];
    return NearbyDriversResponse(
      drivers: list
          .map((e) => NearbyDriver.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Un conductor cercano (para marcador en el mapa).
class NearbyDriver {
  const NearbyDriver({
    required this.driverId,
    required this.lat,
    required this.lng,
    required this.distanceKm,
  });

  final String driverId;
  final double lat;
  final double lng;
  final double distanceKm;

  factory NearbyDriver.fromJson(Map<String, dynamic> json) {
    return NearbyDriver(
      driverId: json['driverId'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
    );
  }
}
