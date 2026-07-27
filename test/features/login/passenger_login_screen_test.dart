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

    testWidgets('renderiza campos principales vía l10n (es)', (tester) async {
      await pumpLogin(tester);
      final l10n = l10nFromTester(tester, LoginScreen);

      expect(find.text(l10n.loginWelcome), findsOneWidget);
      expect(find.text(l10n.loginSubtitle), findsOneWidget);
      expect(find.text(l10n.loginContinue), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('renderiza campos principales vía l10n (en)', (tester) async {
      await pumpLogin(tester, locale: const Locale('en'));
      final l10n = l10nFromTester(tester, LoginScreen);

      expect(find.text(l10n.loginWelcome), findsOneWidget);
      expect(find.text(l10n.loginSubtitle), findsOneWidget);
      expect(find.text(l10n.loginContinue), findsOneWidget);
    });
  });
}
