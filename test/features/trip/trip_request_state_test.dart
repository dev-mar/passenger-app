import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/data/models/quote_response.dart';
import 'package:texi_passenger_app/features/trip/trip_request_state.dart';

void main() {
  group('TripRequestNotifier', () {
    late TripRequestNotifier notifier;

    setUp(() {
      notifier = TripRequestNotifier();
    });

    test('estado inicial vacío', () {
      expect(notifier.state.origin, isNull);
      expect(notifier.state.destination, isNull);
      expect(notifier.state.quote, isNull);
      expect(notifier.state.tripId, isNull);
    });

    test('setOrigin y setDestination fijan puntos', () {
      notifier.setOrigin(-16.5, -68.15);
      notifier.setDestination(-16.52, -68.12);

      expect(notifier.state.origin?.lat, -16.5);
      expect(notifier.state.origin?.lng, -68.15);
      expect(notifier.state.destination?.lat, -16.52);
      expect(notifier.state.destination?.lng, -68.12);
    });

    test('setQuote limpia error y selectedOption', () {
      notifier.setError('fallo previo');
      final quote = QuoteResponse.fromJson({
        'city': {'id': 'lpz', 'name': 'La Paz', 'currencyCode': 'BOB'},
        'currencyCode': 'BOB',
        'distanceKm': 4.2,
        'durationMinutes': 12,
        'options': [
          {
            'serviceTypeId': 1,
            'serviceTypeName': 'Económico',
            'estimatedPrice': 25.5,
            'currencyCode': 'BOB',
          },
        ],
      });

      notifier.setQuote(quote);

      expect(notifier.state.quote, quote);
      expect(notifier.state.selectedOption, isNull);
      expect(notifier.state.error, isNull);
    });

    test('selectOption y setTripId conservan cotización', () {
      final quote = QuoteResponse.fromJson({
        'city': {'id': 'lpz', 'name': 'La Paz'},
        'distanceKm': 2,
        'durationMinutes': 8,
        'options': [
          {
            'serviceTypeId': 2,
            'serviceTypeName': 'Comfort',
            'estimatedPrice': 30,
          },
        ],
      });
      notifier.setQuote(quote);
      final option = quote.options.first;

      notifier.selectOption(option);
      notifier.setTripId('trip-abc');

      expect(notifier.state.selectedOption, option);
      expect(notifier.state.tripId, 'trip-abc');
      expect(notifier.state.quote, quote);
    });

    test('clearQuote conserva origen, destino y tripId', () {
      notifier.setOrigin(1, 2);
      notifier.setDestination(3, 4);
      notifier.setQuote(
        QuoteResponse.fromJson({
          'city': {'id': 'x'},
          'options': [],
        }),
      );
      notifier.setTripId('trip-keep');

      notifier.clearQuote();

      expect(notifier.state.origin?.lat, 1);
      expect(notifier.state.destination?.lng, 4);
      expect(notifier.state.tripId, 'trip-keep');
      expect(notifier.state.quote, isNull);
      expect(notifier.state.selectedOption, isNull);
    });

    test('reset vuelve al estado inicial', () {
      notifier.setOrigin(1, 2);
      notifier.setDestination(3, 4);
      notifier.setTripId('trip-x');
      notifier.setError('err');

      notifier.reset();

      expect(notifier.state, const TripRequestState());
    });
  });
}
