import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/trip/trip_request_trip_phase_helpers.dart';

void main() {
  group('pines del mapa al iniciar el viaje', () {
    test('antes de iniciar se ve el auto del conductor', () {
      for (final status in ['accepted', 'arrived']) {
        expect(
          passengerShouldDrawDriverVehiclePin(
            hasTrip: true,
            hasDriverPosition: true,
            status: status,
          ),
          isTrue,
        );
        expect(
          passengerShouldDrawAboardCarPin(
            status: status,
            hasPassengerPosition: true,
          ),
          isFalse,
        );
      }
    });

    test('en camino el auto del conductor se oculta y pasa al pasajero', () {
      for (final status in ['started', 'in_trip']) {
        expect(
          passengerShouldDrawDriverVehiclePin(
            hasTrip: true,
            hasDriverPosition: true,
            status: status,
          ),
          isFalse,
        );
        expect(
          passengerShouldDrawAboardCarPin(
            status: status,
            hasPassengerPosition: true,
          ),
          isTrue,
        );
        expect(
          passengerShouldDrawNativeLocationDot(
            gpsDotEnabled: true,
            aboardCarVisible: true,
          ),
          isFalse,
        );
      }
    });

    test('sin posición del pasajero se conserva el punto azul', () {
      expect(
        passengerShouldDrawAboardCarPin(
          status: 'started',
          hasPassengerPosition: false,
        ),
        isFalse,
      );
      expect(
        passengerShouldDrawNativeLocationDot(
          gpsDotEnabled: true,
          aboardCarVisible: false,
        ),
        isTrue,
      );
    });
  });
}
