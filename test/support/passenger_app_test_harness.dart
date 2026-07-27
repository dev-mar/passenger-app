import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/gen_l10n/app_localizations.dart';

/// Envuelve widgets bajo prueba con Riverpod + l10n (sin depender de strings fijos).
Widget wrapPassengerApp({
  required Widget child,
  List<Override> overrides = const [],
  Locale locale = const Locale('es'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

AppLocalizations l10nFromTester(WidgetTester tester, Type rootType) {
  return AppLocalizations.of(tester.element(find.byType(rootType)))!;
}
