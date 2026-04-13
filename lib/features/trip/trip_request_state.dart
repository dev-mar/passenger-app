import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quote_response.dart';

/// Origen o destino en el flujo de solicitud de viaje.
class TripPoint {
  const TripPoint({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

/// Estado del flujo: Origen/Destino → Cotización → Confirmar → Solicitar.
class TripRequestState {
  const TripRequestState({
    this.origin,
    this.destination,
    this.quote,
    this.selectedOption,
    this.tripId,
    this.error,
  });

  final TripPoint? origin;
  final TripPoint? destination;
  final QuoteResponse? quote;
  final QuoteOption? selectedOption;
  final String? tripId;
  final String? error;

  TripRequestState copyWith({
    TripPoint? origin,
    TripPoint? destination,
    QuoteResponse? quote,
    QuoteOption? selectedOption,
    String? tripId,
    String? error,
  }) {
    return TripRequestState(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      quote: quote ?? this.quote,
      selectedOption: selectedOption ?? this.selectedOption,
      tripId: tripId ?? this.tripId,
      error: error,
    );
  }

  TripRequestState clearError() => copyWith(error: null);
}

final tripRequestProvider =
    StateNotifierProvider<TripRequestNotifier, TripRequestState>((ref) {
  return TripRequestNotifier();
});

/// Evita repetir el mensaje de “viaje recuperado” para el mismo [tripId] en una sesión.
final tripRecoverySnackShownForTripIdProvider =
    StateProvider<String?>((ref) => null);

/// Se incrementa al limpiar la sesión de viaje fuera del mapa (p. ej. notificación con viaje ya terminal).
/// [TripRequestScreen] lo escucha para alinear pines, ruta y modo de confirmación sin recrear el widget.
final passengerTripMapUiResetTickProvider = StateProvider<int>((ref) => 0);

class TripRequestNotifier extends StateNotifier<TripRequestState> {
  TripRequestNotifier() : super(const TripRequestState());

  void setOrigin(double lat, double lng) {
    state = state.copyWith(origin: TripPoint(lat: lat, lng: lng));
  }

  void setDestination(double lat, double lng) {
    state = state.copyWith(destination: TripPoint(lat: lat, lng: lng));
  }

  void setQuote(QuoteResponse quote) {
    state = state.copyWith(quote: quote, selectedOption: null).clearError();
  }

  void selectOption(QuoteOption option) {
    state = state.copyWith(selectedOption: option);
  }

  void setTripId(String tripId) {
    state = state.copyWith(tripId: tripId).clearError();
  }

  void setError(String message) {
    state = state.copyWith(error: message);
  }

  void reset() {
    state = const TripRequestState();
  }
}
