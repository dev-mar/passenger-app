import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/core/config/passenger_app_environment.dart';

void main() {
  test('dev default backend apunta a api.dev cuando no hay override', () {
    expect(PassengerAppEnvironment.isDev, isTrue);
    expect(
      PassengerAppEnvironment.backendBaseUrl,
      PassengerAppEnvironment.devBackendDefault,
    );
  });

  test('showsInternalToolsByDefault true en dev sin dart-define', () {
    expect(PassengerAppEnvironment.showsInternalToolsByDefault, isTrue);
  });

  test('firebaseAndroidApplicationId dev incluye suffix .dev', () {
    expect(
      PassengerAppEnvironment.firebaseAndroidApplicationId,
      'com.taxitexi.texi_passenger_app.dev',
    );
  });
}
