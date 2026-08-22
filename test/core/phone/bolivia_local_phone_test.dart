import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/core/phone/bolivia_local_phone.dart';

void main() {
  group('isValidBoliviaLocalMobile', () {
    test('acepta 8 dígitos que inician en 5, 6 o 7', () {
      expect(isValidBoliviaLocalMobile('71234567'), isTrue);
      expect(isValidBoliviaLocalMobile('60000000'), isTrue);
      expect(isValidBoliviaLocalMobile('59999999'), isTrue);
      expect(isValidBoliviaLocalMobile('7 123 4567'), isTrue);
    });

    test('rechaza largo distinto de 8 o prefijo distinto de 5/6/7', () {
      expect(isValidBoliviaLocalMobile(''), isFalse);
      expect(isValidBoliviaLocalMobile('7123456'), isFalse);
      expect(isValidBoliviaLocalMobile('712345678'), isFalse);
      expect(isValidBoliviaLocalMobile('41234567'), isFalse);
      expect(isValidBoliviaLocalMobile('81234567'), isFalse);
      expect(isValidBoliviaLocalMobile('01234567'), isFalse);
      expect(isValidBoliviaLocalMobile('abc'), isFalse);
    });
  });

  group('isValidPassengerLocalPhone', () {
    test('en +591 exige móvil BO', () {
      expect(
        isValidPassengerLocalPhone(dialCode: '+591', localNumber: '72909911'),
        isTrue,
      );
      expect(
        isValidPassengerLocalPhone(dialCode: '+591', localNumber: '41234567'),
        isFalse,
      );
    });
  });

  group('BoliviaLocalPhoneInputFormatter', () {
    const formatter = BoliviaLocalPhoneInputFormatter();

    TextEditingValue apply(String text) {
      return formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: text),
      );
    }

    test('recorta a 8 dígitos y descarta no dígitos', () {
      expect(apply('7123456789').text, '71234567');
      expect(apply('7-123-4567').text, '71234567');
      expect(apply('7abc123').text, '7123');
    });

    test('si pegan 591 + local, deja el número local', () {
      expect(apply('59171234567').text, '71234567');
    });
  });
}
