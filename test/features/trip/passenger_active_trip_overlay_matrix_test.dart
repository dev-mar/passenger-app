import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/trip/trip_request_trip_phase_helpers.dart';

/// Matriz de overlays alineada a viaje activo / matching / recuperación.
bool passengerOverlayIsSearchingDriver({
  required String? tripId,
  required String? status,
}) {
  return tripId != null && passengerTripIsAwaitingDriverMatch(status);
}

bool passengerOverlayIsRecovering({
  required String? tripId,
  required String? status,
  String? errorCode,
}) {
  return tripId != null &&
      status == null &&
      !passengerOverlayIsSearchingDriver(tripId: tripId, status: status) &&
      errorCode == null;
}

bool passengerOverlayIsTripActive({
  required String? tripId,
  required String? status,
}) {
  return tripId != null &&
      (passengerTripIsTrackingDriver(status) || status == 'completed');
}

void main() {
  const tripId = 'trip-active-1';

  group('overlay matrix — viaje activo vs matching', () {
    test('status null → recuperación (NO buscando)', () {
      expect(
        passengerOverlayIsSearchingDriver(tripId: tripId, status: null),
        isFalse,
      );
      expect(
        passengerOverlayIsRecovering(tripId: tripId, status: null),
        isTrue,
      );
      expect(
        passengerOverlayIsTripActive(tripId: tripId, status: null),
        isFalse,
      );
    });

    test('searching/requested/offered → buscando + cancel OK', () {
      for (final s in ['searching', 'requested', 'offered']) {
        expect(
          passengerOverlayIsSearchingDriver(tripId: tripId, status: s),
          isTrue,
          reason: s,
        );
        expect(
          passengerOverlayIsRecovering(tripId: tripId, status: s),
          isFalse,
          reason: s,
        );
      }
    });

    test('accepted/arrived/started/in_trip → panel activo (NO buscando)', () {
      for (final s in ['accepted', 'arrived', 'started', 'in_trip']) {
        expect(
          passengerOverlayIsSearchingDriver(tripId: tripId, status: s),
          isFalse,
          reason: s,
        );
        expect(
          passengerOverlayIsRecovering(tripId: tripId, status: s),
          isFalse,
          reason: s,
        );
        expect(
          passengerOverlayIsTripActive(tripId: tripId, status: s),
          isTrue,
          reason: s,
        );
      }
    });

    test('error + status null → no recovering (prioriza error UI)', () {
      expect(
        passengerOverlayIsRecovering(
          tripId: tripId,
          status: null,
          errorCode: 'SOCKET_TIMEOUT',
        ),
        isFalse,
      );
    });

    test('sin tripId → ningún overlay de viaje', () {
      expect(passengerOverlayIsSearchingDriver(tripId: null, status: null), isFalse);
      expect(passengerOverlayIsRecovering(tripId: null, status: null), isFalse);
      expect(passengerOverlayIsTripActive(tripId: null, status: 'accepted'), isFalse);
    });
  });
}
