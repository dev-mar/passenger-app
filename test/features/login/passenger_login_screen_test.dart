import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/login/login_screen.dart';

import '../../support/passenger_app_test_harness.dart';

void main() {
  group('LoginScreen', () {
    Future<void> pumpLogin(
      WidgetTester tester, {
      Locale locale = const Locale('es'),
    }) async {
      await tester.pumpWidget(
        wrapPassengerApp(
          locale: locale,
          child: const LoginScreen(),
        ),
      );
      await tester.pump();
    }

    testWidgets('en debug (OTP clásico) muestra teléfono y continuar, sin Google/WhatsApp', (tester) async {
      await pumpLogin(tester);
      final l10n = l10nFromTester(tester, LoginScreen);

      expect(find.text(l10n.loginPhoneUnifiedTitle), findsOneWidget);
      expect(find.text(l10n.loginContinue), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text(l10n.loginMethodGoogleTitle), findsNothing);
      expect(find.text(l10n.loginVerifyMethodWaInboundShort), findsNothing);
    });

    testWidgets('en debug (OTP clásico) muestra teléfono y continuar (en)', (tester) async {
      await pumpLogin(tester, locale: const Locale('en'));
      final l10n = l10nFromTester(tester, LoginScreen);

      expect(find.text(l10n.loginPhoneUnifiedTitle), findsOneWidget);
      expect(find.text(l10n.loginContinue), findsOneWidget);
      expect(find.text(l10n.loginVerifyMethodWaInboundShort), findsNothing);
    });
  });
}
