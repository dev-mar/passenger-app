/// Parámetros alineados entre **conductor** y **pasajero** para seguimiento de ruta
/// en mapa durante un viaje (Directions HTTP, debounce y cámara).
///
/// Documentación: `.cursor/functional-modules/trip-realtime-tracking/trip-map-route-phases.md`
abstract final class TripRouteTrackingPolicy {
  TripRouteTrackingPolicy._();

  /// TTL del cache en memoria de [DirectionsService] (ambas apps).
  static const Duration directionsHttpCacheTtl = Duration(seconds: 20);

  /// Decimales al armar la clave de cache Directions (`lat,lng` redondeados).
  static const int directionsCacheCoordinateDecimals = 4;

  /// Anti-ráfaga: tiempo mínimo entre recálculos de ruta al mover el vehículo.
  static const Duration mapRouteRefreshDebounce = Duration(milliseconds: 280);

  /// Mínimo entre recentrados automáticos (bounds conductor–objetivo inmediato).
  static const Duration navigationCameraMinGap = Duration(milliseconds: 700);

  /// Timeout de una petición Directions en mapa de viaje; fallo → fallback local.
  static const Duration directionsRequestTimeout = Duration(seconds: 4);
}
