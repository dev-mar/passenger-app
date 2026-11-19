import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/core/analytics/passenger_marketing_events.dart';

void main() {
  test('completado en vivo cuenta una sola transición', () {
    expect(
      passengerMarketingSignalForStatus(previous: 'in_trip', next: 'completed'),
      PassengerMarketingTripSignal.completed,
    );
    expect(
      passengerMarketingSignalForStatus(
        previous: 'completed',
        next: 'completed',
      ),
      PassengerMarketingTripSignal.none,
    );
  });

  test('rehidratar un viaje ya cerrado no mide', () {
    expect(
      passengerMarketingSignalForStatus(previous: null, next: 'completed'),
      PassengerMarketingTripSignal.none,
    );
    expect(
      passengerMarketingSignalForStatus(previous: '', next: 'cancelled'),
      PassengerMarketingTripSignal.none,
    );
  });

  test('cancelación en vivo sí; expirado no usa ese nombre', () {
    expect(
      passengerMarketingSignalForStatus(previous: 'searching', next: 'cancelled'),
      PassengerMarketingTripSignal.cancelled,
    );
    expect(
      passengerMarketingSignalForStatus(previous: 'searching', next: 'expired'),
      PassengerMarketingTripSignal.none,
    );
  });
}
