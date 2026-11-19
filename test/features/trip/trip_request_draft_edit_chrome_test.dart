import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/trip/trip_request_trip_phase_helpers.dart';

void main() {
  group('edición con origen y destino ya puestos', () {
    test('el buscador no devuelve las opciones del viaje', () {
      expect(
        passengerDraftEditHidesTripOptions(
          originConfirmed: true,
          hasDestination: true,
          pickingOrigin: false,
          pickingDestination: false,
          searchTargetActive: true,
        ),
        isTrue,
      );
    });

    test('confirmar en el mapa tampoco muestra las opciones', () {
      expect(
        passengerDraftEditHidesTripOptions(
          originConfirmed: true,
          hasDestination: true,
          pickingOrigin: true,
          pickingDestination: false,
          searchTargetActive: true,
        ),
        isTrue,
      );
      expect(
        passengerDraftEditHidesTripOptions(
          originConfirmed: true,
          hasDestination: true,
          pickingOrigin: false,
          pickingDestination: true,
          searchTargetActive: true,
        ),
        isTrue,
      );
    });

    test('con ambos puntos quietos sí se pueden pedir las opciones', () {
      expect(
        passengerDraftEditHidesTripOptions(
          originConfirmed: true,
          hasDestination: true,
          pickingOrigin: false,
          pickingDestination: false,
          searchTargetActive: false,
        ),
        isFalse,
      );
    });

    test('sin destino el buscador no cuenta como edición de un viaje armado', () {
      expect(
        passengerDraftEditHidesTripOptions(
          originConfirmed: true,
          hasDestination: false,
          pickingOrigin: false,
          pickingDestination: false,
          searchTargetActive: true,
        ),
        isFalse,
      );
    });
  });
}
