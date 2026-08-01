import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/main.dart';

void main() {
  testWidgets('TexiApp arranca y monta MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TexiApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    // Splash + AuthService._readSecure (3× timeout 4 s) pueden dejar timers pendientes.
    await tester.pump(const Duration(seconds: 12));
  });
}
