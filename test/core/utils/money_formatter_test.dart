import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/core/utils/money_formatter.dart';

void main() {
  group('roundTripAmount', () {
    test('entero exacto se queda', () {
      expect(roundTripAmount(12), 12.0);
      expect(roundTripAmount(12.0), 12.0);
    });

    test('entre .0 y .5 inclusive usa .5', () {
      expect(roundTripAmount(12.01), 12.5);
      expect(roundTripAmount(12.36), 12.5);
      expect(roundTripAmount(12.5), 12.5);
      expect(roundTripAmount(12.53), 12.5);
    });

    test('si pasa .5 sube al entero siguiente', () {
      expect(roundTripAmount(12.55), 13.0);
      expect(roundTripAmount(12.67), 13.0);
      expect(roundTripAmount(12.99), 13.0);
    });
  });

  group('formatTripMoney', () {
    test('un decimal y símbolo Bs', () {
      expect(formatTripMoney(12.36), 'Bs 12.5');
      expect(formatTripMoney(12.53), 'Bs 12.5');
      expect(formatTripMoney(12.67), 'Bs 13.0');
      expect(formatTripMoney(12), 'Bs 12.0');
    });
  });
}
