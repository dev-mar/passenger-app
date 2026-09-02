import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/core/privacy/mask_contact_display.dart';

void main() {
  group('maskPassengerPhoneDisplay', () {
    test('muestra país y últimos 4 dígitos', () {
      expect(
        maskPassengerPhoneDisplay(
          dialCode: '+591',
          localNumber: '71234567',
        ),
        '+591 ***4567',
      );
    });

    test('no duplica el código de país si ya viene en el número', () {
      expect(
        maskPassengerPhoneDisplay(
          dialCode: '591',
          localNumber: '59171234567',
        ),
        '+591 ***4567',
      );
    });

    test('sin número local no inventa un destino', () {
      expect(
        maskPassengerPhoneDisplay(dialCode: '+591', localNumber: ''),
        '+591',
      );
    });
  });

  group('maskPassengerEmailDisplay', () {
    test('deja primeras y últimas letras del local', () {
      expect(
        maskPassengerEmailDisplay('juan.perez@gmail.com'),
        'ju***ez@gmail.com',
      );
    });

    test('en local corto deja primera y última letra', () {
      expect(maskPassengerEmailDisplay('abc@correo.com'), 'a***c@correo.com');
    });

    test('en una sola letra no inventa un sufijo', () {
      expect(maskPassengerEmailDisplay('a@correo.com'), 'a***@correo.com');
    });
  });
}
