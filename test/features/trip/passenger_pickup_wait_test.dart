import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/trip/passenger_pickup_wait.dart';

void main() {
  final arrived = DateTime.utc(2026, 9, 4, 12);

  TripPickupWaitSpec spec() => TripPickupWaitSpec(
    arrivedAt: arrived,
    waitSec: 300,
    waitGraceSec: 120,
  );

  group('computePickupWaitView', () {
    test('waiting mientras corre la espera', () {
      final view = computePickupWaitView(
        spec(),
        now: arrived.add(const Duration(seconds: 60)),
      );
      expect(view.phase, PickupWaitPhase.waiting);
      expect(view.remainingSec, 240);
    });

    test('gracia después de wait_sec', () {
      final view = computePickupWaitView(
        spec(),
        now: arrived.add(const Duration(seconds: 310)),
      );
      expect(view.phase, PickupWaitPhase.grace);
      expect(view.remainingSec, 110);
    });

    test('eligible al cumplir espera+gracia; no cancela solo', () {
      final view = computePickupWaitView(
        spec(),
        now: arrived.add(const Duration(seconds: 421)),
      );
      expect(view.phase, PickupWaitPhase.eligible);
      expect(view.remainingSec, 0);
    });
  });

  group('pickupWaitSpecFromFields', () {
    test('solo en arrived con arrivedAt', () {
      expect(
        pickupWaitSpecFromFields(status: 'accepted', arrivedAt: arrived),
        isNull,
      );
      expect(
        pickupWaitSpecFromFields(status: 'arrived', arrivedAt: null),
        isNull,
      );
      expect(
        pickupWaitSpecFromFields(status: 'arrived', arrivedAt: arrived),
        isNotNull,
      );
    });
  });
}
