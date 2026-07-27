import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/trip/passenger_realtime_state.dart';

void main() {
  group('PassengerRealtimeState', () {
    test('initial sin viaje activo', () {
      const state = PassengerRealtimeState.initial;

      expect(state.connecting, isFalse);
      expect(state.connected, isFalse);
      expect(state.activeTripId, isNull);
      expect(state.status, isNull);
      expect(state.chatMessages, isEmpty);
    });

    test('copyWith actualiza status y conductor', () {
      const base = PassengerRealtimeState.initial;
      final active = base.copyWith(
        connected: true,
        activeTripId: 't1',
        status: 'accepted',
        driverName: 'Juan',
        driverLat: -16.5,
        driverLng: -68.15,
      );

      expect(active.connected, isTrue);
      expect(active.activeTripId, 't1');
      expect(active.status, 'accepted');
      expect(active.driverName, 'Juan');
      expect(active.driverLat, -16.5);
    });
  });

  group('passengerTripChatPhaseActive', () {
    test('solo accepted y arrived permiten chat', () {
      expect(passengerTripChatPhaseActive('accepted'), isTrue);
      expect(passengerTripChatPhaseActive('arrived'), isTrue);
      expect(passengerTripChatPhaseActive('started'), isFalse);
      expect(passengerTripChatPhaseActive('searching'), isFalse);
      expect(passengerTripChatPhaseActive(null), isFalse);
    });
  });

  group('displayDriverName', () {
    test('teléfono o vacío usa fallback', () {
      expect(displayDriverName(null), driverNameFallbackDefault);
      expect(displayDriverName(''), driverNameFallbackDefault);
      expect(displayDriverName('591 71234567'), driverNameFallbackDefault);
      expect(displayDriverName('+591 71234567'), driverNameFallbackDefault);
    });

    test('nombre legible se conserva', () {
      expect(displayDriverName('  María López  '), 'María López');
    });
  });
}
