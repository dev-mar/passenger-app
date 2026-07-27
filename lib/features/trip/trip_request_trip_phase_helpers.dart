import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../gen_l10n/app_localizations.dart';

/// Viaje en estado terminal (no requiere sync periódico).
bool passengerTripIsFinalStatus(String? status) {
  if (status == null) return false;
  final s = status.toLowerCase();
  return s == 'completed' || s == 'cancelled' || s == 'expired';
}

/// Fases con tracking del conductor en mapa.
bool passengerTripIsTrackingDriver(String? status) {
  final s = status?.toLowerCase();
  return s == 'accepted' ||
      s == 'arrived' ||
      s == 'started' ||
      s == 'in_trip';
}

/// Fases previas a aceptación (requested/searching/offered).
bool passengerTripIsAwaitingDriverMatch(String? status) {
  final s = status?.toLowerCase();
  return s == 'requested' || s == 'searching' || s == 'offered';
}

/// Pasajero a bordo hacia el destino.
bool passengerTripIsEnRouteToDestination(String? status) {
  final s = status?.toLowerCase();
  return s == 'started' || s == 'in_trip';
}

/// Color de polyline activa según fase del viaje.
Color passengerTripActiveRouteColor(String? status) {
  switch (status) {
    case 'accepted':
    case 'arrived':
      return const Color(0xFFF9AB00);
    case 'started':
    case 'in_trip':
      return const Color(0xFF2E7DFF);
    default:
      return AppColors.primary;
  }
}

/// Etiqueta localizada del estado del viaje para panel y chip superior.
String passengerTripStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'accepted':
      return l10n.tripStatusLabelEnRoute;
    case 'arrived':
      return l10n.tripStatusLabelArrived;
    case 'started':
      return l10n.tripStatusLabelStarted;
    case 'completed':
      return l10n.tripStatusLabelCompleted;
    default:
      return l10n.tripStatusLabelDefault;
  }
}

/// Haversine en km (origen/destino, snap a vía, zoom de cámara).
double tripRequestDistanceKm(LatLng a, LatLng b) {
  const earthRadiusKm = 6371.0;
  final dLat = (b.latitude - a.latitude) * (math.pi / 180.0);
  final dLng = (b.longitude - a.longitude) * (math.pi / 180.0);
  final lat1 = a.latitude * (math.pi / 180.0);
  final lat2 = b.latitude * (math.pi / 180.0);
  final sinDLat = math.sin(dLat / 2.0);
  final sinDLng = math.sin(dLng / 2.0);
  final h =
      sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
  return 2.0 * earthRadiusKm * math.asin(math.min(1.0, math.sqrt(h)));
}

double tripRequestEstimateZoomForDistanceKm(double distanceKm) {
  if (distanceKm < 1.0) return 15.0;
  if (distanceKm < 3.0) return 14.5;
  if (distanceKm < 8.0) return 13.5;
  return 12.8;
}
