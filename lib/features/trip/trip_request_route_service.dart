import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/maps/trip_route_tracking_policy.dart';
import '../../core/network/directions_service.dart';
import 'trip_request_trip_phase_helpers.dart';

/// Resultado de planificar ruta borrador O/D con snap opcional a la vía.
class TripRequestDraftRoutePlan {
  const TripRequestDraftRoutePlan({
    required this.points,
    required this.overviewEncoded,
    required this.snappedOrigin,
    required this.snappedDestination,
    required this.shouldUpdateOriginLabel,
    required this.shouldUpdateDestinationLabel,
  });

  final List<LatLng> points;
  final String? overviewEncoded;
  final LatLng snappedOrigin;
  final LatLng snappedDestination;
  final bool shouldUpdateOriginLabel;
  final bool shouldUpdateDestinationLabel;
}

/// Directions para borrador y ruta dinámica conductor → destino.
class TripRequestRouteService {
  TripRequestRouteService({DirectionsService? directions})
      : _directions = directions ?? DirectionsService();

  final DirectionsService _directions;

  static const double snapThresholdKm = 0.8;

  Future<TripRequestDraftRoutePlan?> planDraftRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final routeFirst = await _directions.getRouteWithOverview(
      originLat: origin.latitude,
      originLng: origin.longitude,
      destinationLat: destination.latitude,
      destinationLng: destination.longitude,
    );
    final points = routeFirst?.points;
    if (points == null || points.isEmpty) return null;

    LatLng? closestO;
    LatLng? closestD;
    double? minDO;
    double? minDD;

    for (final p in points) {
      final d1 = tripRequestDistanceKm(origin, p);
      if (minDO == null || d1 < minDO) {
        minDO = d1;
        closestO = p;
      }
      final d2 = tripRequestDistanceKm(destination, p);
      if (minDD == null || d2 < minDD) {
        minDD = d2;
        closestD = p;
      }
    }

    final shouldSnapO = closestO != null && (minDO ?? 0) <= snapThresholdKm;
    final shouldSnapD = closestD != null && (minDD ?? 0) <= snapThresholdKm;
    final snappedOrigin = closestO != null && (minDO ?? 0) <= snapThresholdKm
        ? closestO
        : origin;
    final snappedDestination =
        closestD != null && (minDD ?? 0) <= snapThresholdKm
        ? closestD
        : destination;

    final routeAligned = await _directions.getRouteWithOverview(
      originLat: snappedOrigin.latitude,
      originLng: snappedOrigin.longitude,
      destinationLat: snappedDestination.latitude,
      destinationLng: snappedDestination.longitude,
    );

    return TripRequestDraftRoutePlan(
      points: routeAligned?.points ?? points,
      overviewEncoded:
          routeAligned?.overviewEncoded ?? routeFirst?.overviewEncoded,
      snappedOrigin: snappedOrigin,
      snappedDestination: snappedDestination,
      shouldUpdateOriginLabel: shouldSnapO,
      shouldUpdateDestinationLabel: shouldSnapD,
    );
  }

  Future<List<LatLng>> planEnRouteToDestination({
    required LatLng driver,
    required LatLng destination,
  }) async {
    try {
      final route = await _directions
          .getRouteWithOverview(
            originLat: driver.latitude,
            originLng: driver.longitude,
            destinationLat: destination.latitude,
            destinationLng: destination.longitude,
          )
          .timeout(TripRouteTrackingPolicy.directionsRequestTimeout);
      final pts = route?.points;
      if (pts != null && pts.length >= 2) return pts;
      return <LatLng>[driver, destination];
    } catch (_) {
      return <LatLng>[driver, destination];
    }
  }
}
