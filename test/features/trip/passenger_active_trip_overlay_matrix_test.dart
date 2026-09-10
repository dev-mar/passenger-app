import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/trip/trip_request_trip_phase_helpers.dart';

/// Matriz de overlays alineada a viaje activo / matching / recuperación.
bool passengerOverlayIsSearchingDriver({
  required String? tripId,
  required String? status,
  bool searchingHoldUi = false,
  bool matchingSubmitUi = false,
}) {
  final tripAssigned =
      passengerTripIsTrackingDriver(status) || status == 'completed';
  return passengerMatchingOverlayVisible(
    tripAssigned: tripAssigned,
    searchingHoldUi: searchingHoldUi,
    matchingSubmitUi: matchingSubmitUi,
    tripId: tripId,
    status: status,
  );
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

    test('cancelled/expired no es buscando', () {
      expect(
        passengerOverlayIsSearchingDriver(tripId: tripId, status: 'cancelled'),
        isFalse,
      );
      expect(
        passengerOverlayIsSearchingDriver(tripId: tripId, status: 'expired'),
        isFalse,
      );
    });

    test('sin tripId → ningún overlay de viaje', () {
      expect(passengerOverlayIsSearchingDriver(tripId: null, status: null), isFalse);
      expect(passengerOverlayIsRecovering(tripId: null, status: null), isFalse);
      expect(passengerOverlayIsTripActive(tripId: null, status: 'accepted'), isFalse);
    });

    test('hold/submit conservan borrador si cancela matching, no si cancela el conductor', () {
      expect(
        passengerShouldKeepDraftAfterMatchingCancel(
          searchingHoldUi: true,
          keepDraftAfterMatchingCancel: false,
          matchingSubmitUi: false,
          cancelledBy: 'passenger',
        ),
        isTrue,
      );
      expect(
        passengerShouldKeepDraftAfterMatchingCancel(
          searchingHoldUi: false,
          keepDraftAfterMatchingCancel: true,
          matchingSubmitUi: false,
        ),
        isTrue,
      );
      expect(
        passengerShouldKeepDraftAfterMatchingCancel(
          searchingHoldUi: true,
          keepDraftAfterMatchingCancel: true,
          matchingSubmitUi: true,
          cancelledBy: 'driver',
        ),
        isFalse,
      );
    });

    test('submit o hold sin tripId → overlay matching (no cotización)', () {
      expect(
        passengerOverlayIsSearchingDriver(
          tripId: null,
          status: null,
          matchingSubmitUi: true,
        ),
        isTrue,
      );
      expect(
        passengerOverlayIsSearchingDriver(
          tripId: null,
          status: null,
          searchingHoldUi: true,
        ),
        isTrue,
      );
    });

    test('viaje ya asignado gana a submit/hold', () {
      expect(
        passengerOverlayIsSearchingDriver(
          tripId: tripId,
          status: 'accepted',
          matchingSubmitUi: true,
          searchingHoldUi: true,
        ),
        isFalse,
      );
    });

    test('compartir solo con viaje iniciado', () {
      expect(passengerTripCanShareLive('accepted'), isFalse);
      expect(passengerTripCanShareLive('arrived'), isFalse);
      expect(passengerTripCanShareLive('started'), isTrue);
      expect(passengerTripCanShareLive('in_trip'), isTrue);
      expect(passengerTripCanShareLive('completed'), isFalse);
    });
  });
}
