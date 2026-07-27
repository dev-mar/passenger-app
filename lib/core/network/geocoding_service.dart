import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'passenger_http_resilience.dart';
import 'request_policy_cache.dart';

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
  GeocodingService() : _dio = passengerGoogleMapsHttpClient();

  final Dio _dio;
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static final RequestPolicyCache<GeocodingResult?> _searchCache =
      RequestPolicyCache<GeocodingResult?>(
        defaultTtl: const Duration(minutes: 5),
      );
  static final RequestPolicyCache<String?> _reverseCache =
      RequestPolicyCache<String?>(defaultTtl: const Duration(minutes: 3));

  /// Busca una dirección y devuelve la primera coincidencia (lat, lng).
  /// [address] Ej: "Av. 16 de Julio, La Paz, Bolivia"
  Future<GeocodingResult?> searchAddress(String address) async {
    if (address.trim().isEmpty) return null;
    final normalized = address.trim().toLowerCase();
    return _searchCache.run(
      key: 's:$normalized',
      fetcher: () async {
        final encoded = Uri.encodeComponent(address.trim());
        final url =
            '$_baseUrl?address=$encoded&key=${AppConfig.googleMapsApiKey}';
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
          return GeocodingResult(
            lat: lat,
            lng: lng,
            formattedAddress: formatted,
          );
        } catch (_) {
          return null;
        }
      },
    );
  }

  /// Reverse geocoding: convierte [lat]/[lng] en una etiqueta legible.
  ///
  /// Prioriza calle/número y barrio/zona; evita códigos Plus Code como etiqueta
  /// principal cuando Google devuelve resultados alternativos más legibles.
  Future<String?> reverseGeocodeStreet({
    required double lat,
    required double lng,
  }) async {
    final key = 'r:${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    return _reverseCache.run(
      key: key,
      fetcher: () async {
        try {
          // Primer intento: pedir explícitamente calle/ruta. En puntos sobre una
          // vía visible del mapa, el reverse general puede devolver una dirección
          // cercana de otra calle; este filtro da prioridad a la vía antes de caer
          // a barrio/zona/ciudad.
          final routeFirst = await _fetchBestReverseLabel(
            lat: lat,
            lng: lng,
            resultType: 'route|street_address',
            preferStreetLevel: true,
          );
          if (routeFirst != null && routeFirst.isNotEmpty) return routeFirst;

          return _fetchBestReverseLabel(
            lat: lat,
            lng: lng,
            preferStreetLevel: false,
          );
        } catch (_) {
          return null;
        }
      },
    );
  }

  Future<String?> _fetchBestReverseLabel({
    required double lat,
    required double lng,
    String? resultType,
    required bool preferStreetLevel,
  }) async {
    final filter = resultType == null || resultType.isEmpty
        ? ''
        : '&result_type=${Uri.encodeQueryComponent(resultType)}';
    final url =
        '$_baseUrl?latlng=$lat,$lng$filter&key=${AppConfig.googleMapsApiKey}';
    final response = await _dio.get<Map<String, dynamic>>(url);
    final data = response.data;
    if (data == null) return null;

    final status = data['status'] as String?;
    if (status != 'OK') return null;

    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;
    return _bestReadableAddressFromResults(
      results,
      preferStreetLevel: preferStreetLevel,
    );
  }
}

bool _looksLikePlusCodeOnly(String formatted) {
  final head = formatted.split(',').first.trim();
  return RegExp(
    r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,}',
    caseSensitive: false,
  ).hasMatch(head);
}

String? _composeReadableAddressFromComponents(List<dynamic>? components) {
  if (components == null) return null;

  String? route;
  String? streetNumber;
  String? neighborhood;
  String? sublocality1;
  String? sublocality2;
  String? sublocality3;
  String? admin3;
  String? locality;
  String? adminArea;
  String? admin2;

  for (final c in components) {
    final comp = c as Map<String, dynamic>;
    final types = comp['types'] as List<dynamic>?;
    if (types == null) continue;
    final longName = comp['long_name'] as String?;
    if (longName == null) continue;

    if (types.contains('street_number')) streetNumber = longName;
    if (types.contains('route')) route = longName;
    if (types.contains('neighborhood')) neighborhood ??= longName;
    if (types.contains('sublocality_level_1') ||
        types.contains('sublocality')) {
      sublocality1 ??= longName;
    }
    if (types.contains('sublocality_level_2')) sublocality2 ??= longName;
    if (types.contains('sublocality_level_3')) sublocality3 ??= longName;
    if (types.contains('administrative_area_level_3')) admin3 ??= longName;
    if (types.contains('locality')) locality = longName;
    if (types.contains('administrative_area_level_2')) admin2 = longName;
    if (types.contains('administrative_area_level_1')) adminArea = longName;
  }

  final parts = <String>[];
  final seen = <String>{};

  void addIfUseful(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    // Evita mostrar niveles administrativos tipo "Departamento de X".
    if (_looksLikeDepartmentLabel(trimmed)) return;
    final normalized = trimmed.toLowerCase();
    if (seen.contains(normalized)) return;
    seen.add(normalized);
    parts.add(trimmed);
  }

  // Orden UX para destino/origen:
  // calle -> barrio/zona -> distrito/comuna/municipio
  // -> provincia/estado -> ciudad.
  // Se omite explícitamente "departamento de ...".
  if (route != null) {
    addIfUseful(streetNumber != null ? '$route $streetNumber' : route);
  }
  addIfUseful(neighborhood ?? sublocality1);
  addIfUseful(sublocality2);
  addIfUseful(sublocality3);
  addIfUseful(admin3);
  // admin2/adminArea suelen ser provincia/estado (o a veces departamento).
  // addIfUseful ya filtra "departamento de ...", por lo que aquí sí podemos
  // incluirlos sin mostrar ese nivel no deseado.
  addIfUseful(admin2);
  addIfUseful(adminArea);
  addIfUseful(locality);

  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

bool _looksLikeDepartmentLabel(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.startsWith('departamento de ') ||
      normalized.startsWith('department of ');
}

String? _bestReadableAddressFromResults(
  List<dynamic> results, {
  required bool preferStreetLevel,
}) {
  String? fallback;

  for (final raw in results) {
    final m = raw as Map<String, dynamic>;
    final formatted = m['formatted_address'] as String?;
    final composed = _composeReadableAddressFromComponents(
      m['address_components'] as List<dynamic>?,
    );
    final readable = (composed != null && composed.isNotEmpty)
        ? composed
        : (formatted != null &&
              formatted.isNotEmpty &&
              !_looksLikePlusCodeOnly(formatted))
        ? formatted
        : null;
    if (readable == null || readable.isEmpty) continue;

    fallback ??= readable;
    if (!preferStreetLevel) return readable;

    final hasRoute = _hasAddressComponentType(
      m['address_components'] as List<dynamic>?,
      'route',
    );
    if (hasRoute) return readable;
  }

  return fallback;
}

bool _hasAddressComponentType(List<dynamic>? components, String type) {
  if (components == null) return false;
  for (final c in components) {
    final comp = c as Map<String, dynamic>;
    final types = comp['types'] as List<dynamic>?;
    if (types != null && types.contains(type)) return true;
  }
  return false;
}
