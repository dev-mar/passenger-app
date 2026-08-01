import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:texi_passenger_app/core/network/passenger_api_providers.dart';
import 'package:texi_passenger_app/features/profile/widgets/passenger_profile_legal_section.dart';

import '../../support/passenger_app_test_harness.dart';

void main() {
  testWidgets('PassengerProfileLegalSection muestra enlaces legales (es)', (tester) async {
    await tester.pumpWidget(
      wrapPassengerApp(
        overrides: [
          passengerMeProfileDataProvider.overrideWith((ref) async => {}),
        ],
        child: const Scaffold(
          body: SingleChildScrollView(
            child: PassengerProfileLegalSection(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Legal y privacidad'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.text('Términos de servicio'), findsOneWidget);
    expect(find.text('Eliminar cuenta'), findsOneWidget);
  });
}
