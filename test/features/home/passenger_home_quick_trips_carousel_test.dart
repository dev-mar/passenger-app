import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/home/home_quick_slots.dart';
import 'package:texi_passenger_app/features/home/widgets/passenger_home_quick_trips_carousel.dart';

import '../../support/passenger_app_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCard(
    WidgetTester tester,
    PassengerHomeQuickTripCardData card,
  ) async {
    await tester.pumpWidget(
      wrapPassengerApp(
        child: Scaffold(body: PassengerHomeQuickTripsCarousel(cards: [card])),
      ),
    );
    await tester.pump();
  }

  testWidgets('el lápiz edita y el resto de la tarjeta pide el viaje', (
    tester,
  ) async {
    var trips = 0;
    var edits = 0;
    await pumpCard(
      tester,
      PassengerHomeQuickTripCardData(
        kind: HomeQuickSlotKind.work,
        title: 'Ir al trabajo',
        subtitle: 'Oficina',
        configured: true,
        onTap: () => trips++,
        onEdit: () => edits++,
      ),
    );

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    expect(edits, 1);
    expect(trips, 0);

    await tester.tap(find.text('Pedir ahora'));
    await tester.pump();
    expect(trips, 1);
    expect(edits, 1);

    await tester.tap(find.text('Ir al trabajo'));
    await tester.pump();
    expect(trips, 2);
    expect(edits, 1);
  });

  testWidgets('sin ubicación el + no edita y la tarjeta abre el guardado', (
    tester,
  ) async {
    var trips = 0;
    await pumpCard(
      tester,
      PassengerHomeQuickTripCardData(
        kind: HomeQuickSlotKind.home,
        title: 'Ir a casa',
        subtitle: 'Casa',
        configured: false,
        onTap: () => trips++,
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    await tester.tap(find.text('Pedir ahora'));
    await tester.pump();
    expect(trips, 1);
  });

  testWidgets('el aeropuerto no muestra + ni lápiz', (tester) async {
    var trips = 0;
    await pumpCard(
      tester,
      PassengerHomeQuickTripCardData(
        kind: HomeQuickSlotKind.airport,
        title: 'Aeropuerto',
        subtitle: 'Viru Viru',
        configured: true,
        onTap: () => trips++,
        onEdit: () => fail('el aeropuerto no se edita'),
      ),
    );

    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    await tester.tap(find.text('Pedir ahora'));
    await tester.pump();
    expect(trips, 1);
  });
}
