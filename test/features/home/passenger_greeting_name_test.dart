import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/home/home_screen.dart';

void main() {
  test('el saludo usa solo el primer nombre', () {
    expect(passengerGreetingFirstName('Marcelo Pérez'), 'Marcelo');
    expect(passengerGreetingFirstName('  ana   lucía '), 'ana');
    expect(passengerGreetingFirstName('correo@texi.com'), isNull);
    expect(passengerGreetingFirstName(''), isNull);
    expect(passengerGreetingFirstName(null), isNull);
  });
}
