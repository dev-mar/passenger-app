abstract final class TripRouteTrackingPolicy {
  TripRouteTrackingPolicy._();

  static const Duration directionsHttpCacheTtl = Duration(seconds: 20);

  static const int directionsCacheCoordinateDecimals = 4;

  static const Duration mapRouteRefreshDebounce = Duration(milliseconds: 420);

  static const Duration navigationCameraMinGap = Duration(milliseconds: 1000);

  static const Duration directionsRequestTimeout = Duration(seconds: 4);
}
