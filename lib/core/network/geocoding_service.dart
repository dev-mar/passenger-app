import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Respuesta de una búsqueda de dirección (Google Geocoding API).
class GeocodingResult {
  const GeocodingResult({
    required this.lat,
    required this.lng,
    this.formattedAddress,
  });

  final double lat;
  final double lng;
  final String? formattedAddress;
}

/// Cliente para Google Geocoding API.
/// Requiere habilitar "Geocoding API" en Google Cloud (mismo proyecto que Maps).
class GeocodingService {
  GeocodingService() : _dio = Dio();

  final Dio _dio;
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Busca una dirección y devuelve la primera coincidencia (lat, lng).
  /// [address] Ej: "Av. 16 de Julio, La Paz, Bolivia"
  Future<GeocodingResult?> searchAddress(String address) async {
    if (address.trim().isEmpty) return null;
    final encoded = Uri.encodeComponent(address.trim());
    final url = '$_baseUrl?address=$encoded&key=${AppConfig.googleMapsApiKey}';
    try {
      final response = await _dio.get<Map<String, dynamic>>(url);
      final data = response.data;
      if (data == null) return null;
      final status = data['status'] as String?;
      if (status != 'OK') return null;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) return null;
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final formatted = first['formatted_address'] as String?;
      return GeocodingResult(lat: lat, lng: lng, formattedAddress: formatted);
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocoding: convierte [lat]/[lng] en una etiqueta legible.
  ///
  /// Devuelve principalmente nombre de calle (route) + número (street_number)
  /// cuando está disponible. Si no, usa [formatted_address] de Google.
  Future<String?> reverseGeocodeStreet({
    required double lat,
    required double lng,
  }) async {
    final url = '$_baseUrl?latlng=$lat,$lng&key=${AppConfig.googleMapsApiKey}';
    try {
      final response = await _dio.get<Map<String, dynamic>>(url);
      final data = response.data;
      if (data == null) return null;

      final status = data['status'] as String?;
      if (status != 'OK') return null;

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final formatted = first['formatted_address'] as String?;

      final components = first['address_components'] as List<dynamic>?;
      if (components == null) return formatted;

      String? route;
      String? streetNumber;

      for (final c in components) {
        final comp = c as Map<String, dynamic>;
        final types = comp['types'] as List<dynamic>?;
        if (types == null) continue;

        final longName = comp['long_name'] as String?;
        if (longName == null) continue;

        if (types.contains('route')) route = longName;
        if (types.contains('street_number')) streetNumber = longName;
      }

      if (route == null) return formatted;
      if (streetNumber == null) return route;
      return '$streetNumber $route';
    } catch (_) {
      return null;
    }
  }
}
