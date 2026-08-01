import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/features/trip/widgets/passenger_trip_draft_header.dart';

import '../../support/passenger_app_test_harness.dart';

void main() {
  group('PassengerTripDraftHeader — paso inicial borrador', () {
    Future<void> pumpDraftOriginStep(
      WidgetTester tester, {
      Locale locale = const Locale('es'),
    }) async {
      final searchController = TextEditingController();
      final searchFocus = FocusNode();
      addTearDown(searchController.dispose);
      addTearDown(searchFocus.dispose);

      await tester.pumpWidget(
        wrapPassengerApp(
          locale: locale,
          child: Scaffold(
            body: PassengerTripDraftHeader(
              originConfirmed: false,
              originDisplayLine: '',
              destinationDisplayLine: '',
              hasDestinationSet: false,
              searchController: searchController,
              searchFocusNode: searchFocus,
              onSearchChanged: (_) {},
              searchFieldHint: '',
              showSuggestionsPanel: false,
              loadingSuggestions: false,
              suggestions: const [],
              onPickSuggestion: (_) {},
              recentPlaces: const [],
              onPickRecent: (_) {},
              recentSectionTitle: '',
              onMyLocationIconTap: () {},
              onSavedIconTap: () {},
              myLocationTooltip: '',
              savedPlacesTooltip: '',
              showLocationSearchChrome: true,
              highlightOrigin: false,
              highlightDestination: false,
              searchPriorityMode: false,
              searchRole: PassengerDraftSearchRole.origin,
              editStopLabel: '',
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('muestra origen, destino y lupa compacta vía l10n (es)', (tester) async {
      await pumpDraftOriginStep(tester);
      final l10n = l10nFromTester(tester, Scaffold);

      expect(find.text(l10n.tripOrigin.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.tripWhereTo.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.tripTapMapDestination), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('al pulsar la lupa se expande el campo de búsqueda', (tester) async {
      await pumpDraftOriginStep(tester);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('muestra origen, destino y lupa compacta vía l10n (en)', (tester) async {
      await pumpDraftOriginStep(tester, locale: const Locale('en'));
      final l10n = l10nFromTester(tester, Scaffold);

      expect(find.text(l10n.tripOrigin.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.tripWhereTo.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.tripTapMapDestination), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
