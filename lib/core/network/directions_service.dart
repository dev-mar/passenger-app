import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';

/// Decodifica una polyline codificada (formato Google).
/// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
List<LatLng> decodePolyline(String encoded) {
  final list = <LatLng>[];
  int index = 0;
  int lat = 0;
  int lng = 0;

  while (index < encoded.length) {
    int b;
    int shift = 0;
    int result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    list.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return list;
}

/// Cliente para Google Directions API.
/// Requiere habilitar "Directions API" en Google Cloud (mismo proyecto que Maps).
class DirectionsService {
  DirectionsService() : _dio = Dio();

  final Dio _dio;
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Obtiene la ruta por calles entre origen y destino (mejor ruta).
  /// Devuelve la lista de puntos de la polyline o null si falla.
  Future<List<LatLng>?> getRoutePoints({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final origin = '$originLat,$originLng';
    final destination = '$destinationLat,$destinationLng';
    final url = '$_baseUrl?origin=$origin&destination=$destination'
        '&key=${AppConfig.googleMapsApiKey}';
    try {
      final response = await _dio.get<Map<String, dynamic>>(url);
      final data = response.data;
      if (data == null) return null;
      if (data['status'] != 'OK') return null;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final overview = route['overview_polyline'] as Map<String, dynamic>?;
      final encoded = overview?['points'] as String?;
      if (encoded == null || encoded.isEmpty) return null;
      return decodePolyline(encoded);
    } catch (_) {
      return null;
    }
  }
}
