import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/core/network/passenger_http_resilience.dart';
import 'package:texi_passenger_app/core/network/trips_api.dart';
import 'package:texi_passenger_app/data/models/quote_response.dart';

void main() {
  group('QuoteResponse.fromJson', () {
    test('parsea opciones y alias legacy de moneda', () {
      final quote = QuoteResponse.fromJson({
        'city': {
          'id': 'lpz',
          'name': 'La Paz',
          'currency': 'BOB',
        },
        'currency': 'BOB',
        'distanceKm': 3.5,
        'durationMinutes': 10,
        'options': [
          {
            'serviceTypeId': '3',
            'serviceTypeName': 'Premium',
            'estimatedPrice': '42.75',
            'currency': 'BOB',
          },
        ],
      });

      expect(quote.city.id, 'lpz');
      expect(quote.city.name, 'La Paz');
      expect(quote.currencyCode, 'BOB');
      expect(quote.distanceKm, closeTo(3.5, 0.001));
      expect(quote.durationMinutes, 10);
      expect(quote.options, hasLength(1));
      expect(quote.options.first.serviceTypeId, 3);
      expect(quote.options.first.estimatedPrice, closeTo(42.75, 0.001));
    });

    test('lista vacía y defaults cuando faltan campos', () {
      final quote = QuoteResponse.fromJson({});

      expect(quote.city.id, '');
      expect(quote.currencyCode, 'BOB');
      expect(quote.distanceKm, 0);
      expect(quote.options, isEmpty);
    });
  });

  group('retryAfterMsFromResponse', () {
    test('lee retry_after_ms en envelope error', () {
      final ms = retryAfterMsFromResponse(
        {
          'error': {'retry_after_ms': 2500},
        },
        null,
      );

      expect(ms, 2500);
    });

    test('lee retry-after del header en segundos', () {
      final headers = Headers.fromMap({
        'retry-after': ['3'],
      });

      final ms = TripsApi.retryAfterMsFromResponse(null, headers);

      expect(ms, 3000);
    });

    test('devuelve null sin pistas de backoff', () {
      expect(retryAfterMsFromResponse(null, null), isNull);
      expect(retryAfterMsFromResponse({'message': 'busy'}, null), isNull);
    });
  });

  group('TripsApi.retryAfterMsForCreateTrip', () {
    test('usa default cuando la respuesta no trae retry', () {
      final ms = TripsApi.retryAfterMsForCreateTrip(
        DioException(
          requestOptions: RequestOptions(path: '/passengers/trips'),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(ms, 1200);
    });

    test('prioriza retry del payload sobre default', () {
      final ms = TripsApi.retryAfterMsForCreateTrip(
        DioException(
          requestOptions: RequestOptions(path: '/passengers/trips'),
          response: Response(
            requestOptions: RequestOptions(path: '/passengers/trips'),
            data: {'retry_after_ms': 5000},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(ms, 5000);
    });
  });
}
