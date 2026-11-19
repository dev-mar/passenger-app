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

    testWidgets('muestra origen, destino y lupa compacta vía l10n (es)', (
      tester,
    ) async {
      await pumpDraftOriginStep(tester);
      final l10n = l10nFromTester(tester, Scaffold);

      expect(find.text(l10n.tripOrigin.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.tripWhereTo), findsOneWidget);
      expect(find.text(l10n.tripTapMapDestination), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
    });

    testWidgets('el buscador de direcciones sigue abriéndose al activarlo', (
      tester,
    ) async {
      final searchController = TextEditingController();
      final searchFocus = FocusNode();
      addTearDown(searchController.dispose);
      addTearDown(searchFocus.dispose);

      Widget header({required int expandToken}) {
        return wrapPassengerApp(
          child: Scaffold(
            body: PassengerTripDraftHeader(
              originConfirmed: true,
              originDisplayLine: 'Av. Blanco Galindo',
              destinationDisplayLine: '',
              hasDestinationSet: false,
              searchController: searchController,
              searchFocusNode: searchFocus,
              onSearchChanged: (_) {},
              searchFieldHint: 'Buscar',
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
              searchRole: PassengerDraftSearchRole.destination,
              searchExpandToken: expandToken,
              editStopLabel: '',
            ),
          ),
        );
      }

      await tester.pumpWidget(header(expandToken: 0));
      await tester.pump();
      expect(find.byType(TextField), findsNothing);

      await tester.pumpWidget(header(expandToken: 1));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets('con origen y destino listos el encabezado queda compacto', (
      tester,
    ) async {
      final searchController = TextEditingController();
      final searchFocus = FocusNode();
      addTearDown(searchController.dispose);
      addTearDown(searchFocus.dispose);

      await tester.pumpWidget(
        wrapPassengerApp(
          child: Scaffold(
            body: PassengerTripDraftHeader(
              originConfirmed: true,
              originDisplayLine: 'Av. Blanco Galindo',
              destinationDisplayLine: 'Cine Center · Av. Ramón Rivero',
              hasDestinationSet: true,
              searchController: searchController,
              searchFocusNode: searchFocus,
              onSearchChanged: (_) {},
              searchFieldHint: 'Buscar',
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
              showLocationSearchChrome: false,
              highlightOrigin: false,
              highlightDestination: false,
              searchPriorityMode: false,
              searchRole: PassengerDraftSearchRole.destination,
              settledCompact: true,
              editStopLabel: 'Editar',
              onEditOrigin: () {},
              onEditDestination: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final l10n = l10nFromTester(tester, Scaffold);
      expect(find.text(l10n.tripWhereTo), findsNothing);
      expect(find.text(l10n.tripOrigin.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.tripDestination.toUpperCase()), findsOneWidget);
      expect(find.text('Cine Center · Av. Ramón Rivero'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
    });

    testWidgets(
      'el primer paso de origen a destino abre el buscador sin segundo toque',
      (tester) async {
        final searchController = TextEditingController();
        final searchFocus = FocusNode();
        addTearDown(searchController.dispose);
        addTearDown(searchFocus.dispose);

        Widget header({
          required bool originConfirmed,
          required PassengerDraftSearchRole role,
          required int expandToken,
        }) {
          return wrapPassengerApp(
            child: Scaffold(
              body: PassengerTripDraftHeader(
                originConfirmed: originConfirmed,
                originDisplayLine: 'Av. Blanco Galindo',
                destinationDisplayLine: '',
                hasDestinationSet: false,
                searchController: searchController,
                searchFocusNode: searchFocus,
                onSearchChanged: (_) {},
                searchFieldHint: 'Buscar',
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
                searchRole: role,
                searchExpandToken: expandToken,
                editStopLabel: '',
                onSearchOnMap: () {},
                searchOnMapLabel: 'Buscar en el mapa',
              ),
            ),
          );
        }

        await tester.pumpWidget(
          header(
            originConfirmed: false,
            role: PassengerDraftSearchRole.origin,
            expandToken: 0,
          ),
        );
        await tester.pump();
        expect(find.byType(TextField), findsNothing);

        await tester.pumpWidget(
          header(
            originConfirmed: true,
            role: PassengerDraftSearchRole.destination,
            expandToken: 1,
          ),
        );
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Buscar en el mapa'), findsOneWidget);
      },
    );

    testWidgets('muestra origen, destino y lupa compacta vía l10n (en)', (
      tester,
    ) async {
      await pumpDraftOriginStep(tester, locale: const Locale('en'));
      final l10n = l10nFromTester(tester, Scaffold);

      expect(find.text(l10n.tripOrigin.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.tripWhereTo), findsOneWidget);
      expect(find.text(l10n.tripTapMapDestination), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('pulsar el bloque de destino dispara la acción', (
      tester,
    ) async {
      var taps = 0;
      final searchController = TextEditingController();
      final searchFocus = FocusNode();
      addTearDown(searchController.dispose);
      addTearDown(searchFocus.dispose);

      await tester.pumpWidget(
        wrapPassengerApp(
          child: Scaffold(
            body: PassengerTripDraftHeader(
              originConfirmed: false,
              originDisplayLine: 'Av. Blanco Galindo',
              destinationDisplayLine: '',
              hasDestinationSet: false,
              searchController: searchController,
              searchFocusNode: searchFocus,
              onSearchChanged: (_) {},
              searchFieldHint: 'Buscar',
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
              attractDestinationTap: true,
              searchPriorityMode: false,
              searchRole: PassengerDraftSearchRole.origin,
              editStopLabel: '',
              onOpenSearchDestination: () => taps++,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Toca aquí para elegir tu destino'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('el buscador de destino ofrece buscar en el mapa', (
      tester,
    ) async {
      var mapTaps = 0;
      final searchController = TextEditingController();
      final searchFocus = FocusNode();
      addTearDown(searchController.dispose);
      addTearDown(searchFocus.dispose);

      Widget header({required int expandToken}) {
        return wrapPassengerApp(
          child: Scaffold(
            body: PassengerTripDraftHeader(
              originConfirmed: true,
              originDisplayLine: 'Av. Blanco Galindo',
              destinationDisplayLine: '',
              hasDestinationSet: false,
              searchController: searchController,
              searchFocusNode: searchFocus,
              onSearchChanged: (_) {},
              searchFieldHint: 'Buscar',
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
              searchRole: PassengerDraftSearchRole.destination,
              searchExpandToken: expandToken,
              editStopLabel: '',
              onSearchOnMap: () => mapTaps++,
              searchOnMapLabel: 'Buscar en el mapa',
            ),
          ),
        );
      }

      await tester.pumpWidget(header(expandToken: 0));
      await tester.pump();
      expect(find.text('Buscar en el mapa'), findsNothing);

      await tester.pumpWidget(header(expandToken: 1));
      await tester.pumpAndSettle();

      expect(find.text('Buscar en el mapa'), findsOneWidget);
      await tester.tap(find.text('Buscar en el mapa'));
      await tester.pump();

      expect(mapTaps, 1);
    });
  });
}
