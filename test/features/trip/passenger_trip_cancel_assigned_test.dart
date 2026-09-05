import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/trip/trip_cancel_reason.dart';

void main() {
  test('panel activo cancela assigned en accepted/arrived/started/in_trip', () {
    expect(passengerTripCanCancelAssigned('accepted'), isTrue);
    expect(passengerTripCanCancelAssigned('arrived'), isTrue);
    expect(passengerTripCanCancelAssigned('searching'), isFalse);
    expect(passengerTripCanCancelAssigned('offered'), isFalse);
    expect(passengerTripCanCancelAssigned('started'), isTrue);
    expect(passengerTripCanCancelAssigned('in_trip'), isTrue);
    expect(passengerTripCanCancelAssigned('completed'), isFalse);
    expect(passengerTripCanCancelAssigned(null), isFalse);
  });

  test('parsea catálogo aditivo', () {
    final item = TripCancelReasonItem.fromJson({
      'code': 'passenger_eta_too_long',
      'label': 'El conductor tarda demasiado',
      'confirmText': 'El conductor ya viene hacia ti.',
      'requiresNote': false,
      'sortOrder': 20,
    });
    expect(item.code, 'passenger_eta_too_long');
    expect(item.requiresNote, isFalse);
  });
}
