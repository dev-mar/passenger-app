import 'dart:math' as math;

/// ETA grosera urbana, misma idea que el share público (`~22 km/h`).
/// Solo coords ya presentes en el cliente; no llama red ni cambia contratos.
const double kPassengerTripLiveEtaSpeedKmh = 22;

enum PassengerTripLiveEtaKind { pickup, destination, atPickup }

class PassengerTripLiveEta {
  const PassengerTripLiveEta({
    required this.kind,
    this.minutes,
  });

  final PassengerTripLiveEtaKind kind;
  final int? minutes;
}

double passengerHaversineKm({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const r = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = _sin2(dLat / 2) +
      math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * _sin2(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

int? passengerEstimateEtaMinutes({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  final km = passengerHaversineKm(
    lat1: fromLat,
    lng1: fromLng,
    lat2: toLat,
    lng2: toLng,
  );
  if (!km.isFinite || km < 0) return null;
  if (km < 0.05) return 1;
  final minutes = ((km / kPassengerTripLiveEtaSpeedKmh) * 60).round();
  if (minutes < 1) return 1;
  if (minutes > 180) return 180;
  return minutes;
}

/// Recojo (`accepted`): conductor → origen.
/// En el punto (`arrived`): sin minutos.
/// Trayecto (`started`/`in_trip`): conductor → destino, o duración del quote.
PassengerTripLiveEta? resolvePassengerTripLiveEta({
  required String? status,
  double? driverLat,
  double? driverLng,
  double? pickupLat,
  double? pickupLng,
  double? destLat,
  double? destLng,
  int? quoteDurationMinutes,
}) {
  switch (status) {
    case 'accepted':
      if (driverLat == null ||
          driverLng == null ||
          pickupLat == null ||
          pickupLng == null) {
        return null;
      }
      final m = passengerEstimateEtaMinutes(
        fromLat: driverLat,
        fromLng: driverLng,
        toLat: pickupLat,
        toLng: pickupLng,
      );
      if (m == null) return null;
      return PassengerTripLiveEta(
        kind: PassengerTripLiveEtaKind.pickup,
        minutes: m,
      );
    case 'arrived':
      return const PassengerTripLiveEta(
        kind: PassengerTripLiveEtaKind.atPickup,
      );
    case 'started':
    case 'in_trip':
      int? m;
      if (driverLat != null &&
          driverLng != null &&
          destLat != null &&
          destLng != null) {
        m = passengerEstimateEtaMinutes(
          fromLat: driverLat,
          fromLng: driverLng,
          toLat: destLat,
          toLng: destLng,
        );
      }
      final quote = quoteDurationMinutes;
      m ??= (quote != null && quote > 0) ? quote.clamp(1, 180) : null;
      if (m == null) return null;
      return PassengerTripLiveEta(
        kind: PassengerTripLiveEtaKind.destination,
        minutes: m,
      );
    default:
      return null;
  }
}

double _toRad(double deg) => deg * math.pi / 180;

double _sin2(double x) {
  final s = math.sin(x);
  return s * s;
}
