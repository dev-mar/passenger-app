import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/core/utils/service_type_display.dart';
import 'package:texi_passenger_app/features/trip/trip_service_addon_policy.dart';

void main() {
  group('serviceTypeIconKey por serviceTypeId', () {
    test('id 4 es moto aunque el label no lo diga', () {
      expect(
        serviceTypeIconKey('Servicio', serviceTypeId: 4),
        'two_wheeler',
      );
      expect(
        serviceTypeIconKey('Dos ruedas', serviceTypeId: 4),
        'two_wheeler',
      );
    });

    test('ids de auto no se confunden con moto', () {
      expect(serviceTypeIconKey('Dos ruedas', serviceTypeId: 1), 'standard');
      expect(serviceTypeIconKey('', serviceTypeId: 2), 'comfort');
      expect(serviceTypeIconKey('', serviceTypeId: 3), 'premium');
    });

    test('sin id, el label legacy Dos ruedas sigue siendo moto', () {
      expect(serviceTypeIconKey('Dos ruedas'), 'two_wheeler');
      expect(serviceTypeSeatCapacity('Dos ruedas'), 1);
    });
  });

  group('passengerServiceFamily', () {
    test('id 4 es motorbike y bloquea extras', () {
      expect(
        passengerServiceFamily(serviceTypeId: 4, serviceTypeName: 'Servicio'),
        TripPassengerServiceFamily.motorbike,
      );
      expect(
        allowedExtrasForFamily(TripPassengerServiceFamily.motorbike),
        isEmpty,
      );
    });

    test('id 1 es economy aunque el nombre sea ambiguo', () {
      expect(
        passengerServiceFamily(serviceTypeId: 1, serviceTypeName: 'Dos ruedas'),
        TripPassengerServiceFamily.economy,
      );
    });
  });
}
