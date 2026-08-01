import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'passenger_http_resilience.dart';
import 'request_policy_cache.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
  });

  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullText;
}

class PlaceDetailsResult {
  const PlaceDetailsResult({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
  });

  final double lat;
  final double lng;
  final String formattedAddress;
}

/// Cliente para Google Places Autocomplete + Place Details.
/// Requiere habilitar "Places API" (legacy) en Google Cloud.
class PlacesAutocompleteService {
  PlacesAutocompleteService() : _dio = passengerGoogleMapsHttpClient();

  final Dio _dio;
  static final RequestPolicyCache<List<PlaceSuggestion>> _suggestionsCache =
      RequestPolicyCache<List<PlaceSuggestion>>(
        defaultTtl: const Duration(seconds: 20),
      );
  static final RequestPolicyCache<PlaceDetailsResult?> _detailsCache =
      RequestPolicyCache<PlaceDetailsResult?>(
        defaultTtl: const Duration(minutes: 10),
      );
  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Mínimo de caracteres antes de consultar Places (control de peticiones).
  static const int minQueryLength = 3;

  Future<List<PlaceSuggestion>> fetchSuggestions({
    required String query,
    required String sessionToken,
    double? nearLat,
    double? nearLng,
  }) async {
    final q = query.trim();
    if (q.length < minQueryLength) return const [];
    final locationBucket = nearLat != null && nearLng != null
        ? '${nearLat.toStringAsFixed(3)},${nearLng.toStringAsFixed(3)}'
        : 'none';
    final key = 's:$q:$locationBucket';
    return _suggestionsCache.run(
      key: key,
      fetcher: () async {
        try {
          final params = <String, dynamic>{
            'input': q,
            'key': AppConfig.googleMapsApiKey,
            'language': 'es',
            'sessiontoken': sessionToken,
            // Bolivia; el bias de ubicación prioriza la zona del mapa.
            'components': 'country:bo',
          };
          if (nearLat != null && nearLng != null) {
            params['location'] = '$nearLat,$nearLng';
            // Bias suave (sin strictbounds): ranking local sin descartar POIs útiles.
            params['radius'] = 50000;
          }
          // Sin `types=geocode`: permite direcciones + establecimientos / puntos.

          final response = await _dio.get<Map<String, dynamic>>(
            _autocompleteUrl,
            queryParameters: params,
          );
          final data = response.data;
          if (data == null || data['status'] != 'OK') return const [];
          final preds = data['predictions'] as List<dynamic>?;
          if (preds == null || preds.isEmpty) return const [];
          final queryLower = q.toLowerCase();
          final tokens = queryLower
              .split(RegExp(r'\s+'))
              .where((t) => t.length >= 2)
              .toList(growable: false);
          return preds
              .map((raw) {
                final item = raw as Map<String, dynamic>;
                final structured =
                    item['structured_formatting'] as Map<String, dynamic>?;
                final main = structured?['main_text']?.toString() ?? '';
                final secondary =
                    structured?['secondary_text']?.toString() ?? '';
                final description = item['description']?.toString() ?? '';
                return PlaceSuggestion(
                  placeId: item['place_id']?.toString() ?? '',
                  mainText: main,
                  secondaryText: secondary,
                  fullText: description,
                );
              })
              .where((e) => e.placeId.isNotEmpty)
              .where((e) {
                // Filtro suave: al menos un token relevante (Google ya rankea).
                final hay =
                    '${e.mainText} ${e.secondaryText} ${e.fullText}'
                        .toLowerCase();
                if (tokens.isEmpty) {
                  return hay.contains(queryLower);
                }
                return tokens.any((t) => hay.contains(t));
              })
              .toList(growable: false);
        } catch (_) {
          return const [];
        }
      },
    );
  }

  Future<PlaceDetailsResult?> fetchPlaceDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    if (placeId.trim().isEmpty) return null;
    return _detailsCache.run(
      key: 'd:${placeId.trim()}',
      fetcher: () async {
        try {
          final response = await _dio.get<Map<String, dynamic>>(
            _detailsUrl,
            queryParameters: {
              'place_id': placeId,
              'fields': 'geometry/location,formatted_address',
              'key': AppConfig.googleMapsApiKey,
              'language': 'es',
              'sessiontoken': sessionToken,
            },
          );
          final data = response.data;
          if (data == null || data['status'] != 'OK') return null;
          final result = data['result'] as Map<String, dynamic>?;
          final geometry = result?['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          final lat = (location?['lat'] as num?)?.toDouble();
          final lng = (location?['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) return null;
          final formatted =
              result?['formatted_address']?.toString().trim().isNotEmpty == true
              ? result!['formatted_address'].toString()
              : '';
          return PlaceDetailsResult(
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
}
