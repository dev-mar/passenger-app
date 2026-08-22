import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quote_response.dart';
import 'trip_passenger_extras.dart';
import 'trip_passenger_specials.dart';
import 'trip_payment_method.dart';
import 'trip_service_addon_policy.dart';

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
    this.paymentMethod = TripPaymentMethod.cash,
    this.extras = TripPassengerExtras.empty,
    this.specials = TripPassengerSpecials.empty,
  });

  final TripPoint? origin;
  final TripPoint? destination;
  final QuoteResponse? quote;
  final QuoteOption? selectedOption;
  final String? tripId;
  final String? error;
  final String paymentMethod;
  final TripPassengerExtras extras;
  final TripPassengerSpecials specials;

  double get specialSurchargePct =>
      quote?.specialRequirementSurchargePct ?? 50;

  double? get quotedBasePrice => selectedOption?.estimatedPrice;

  double? get previewTotalPrice {
    final base = quotedBasePrice;
    if (base == null) return null;
    return applySpecialsSurcharge(
      basePrice: base,
      specialsCount: specials.selectedCount,
      surchargePct: specialSurchargePct,
    );
  }

  TripRequestState copyWith({
    TripPoint? origin,
    TripPoint? destination,
    QuoteResponse? quote,
    QuoteOption? selectedOption,
    String? tripId,
    String? error,
    String? paymentMethod,
    TripPassengerExtras? extras,
    TripPassengerSpecials? specials,
  }) {
    return TripRequestState(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      quote: quote ?? this.quote,
      selectedOption: selectedOption ?? this.selectedOption,
      tripId: tripId ?? this.tripId,
      error: error,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      extras: extras ?? this.extras,
      specials: specials ?? this.specials,
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

  TripPassengerServiceFamily get _family => passengerServiceFamily(
        serviceTypeId: state.selectedOption?.serviceTypeId,
        serviceTypeName: state.selectedOption?.serviceTypeName,
      );

  void _pruneAddonsForFamily(TripPassengerServiceFamily family) {
    state = state.copyWith(
      extras: state.extras.prunedTo(allowedExtrasForFamily(family)),
      specials: state.specials.prunedTo(allowedSpecialsForFamily(family)),
    );
  }

  void setOrigin(double lat, double lng) {
    state = state.copyWith(origin: TripPoint(lat: lat, lng: lng));
  }

  void setDestination(double lat, double lng) {
    state = state.copyWith(destination: TripPoint(lat: lat, lng: lng));
  }

  void setQuote(QuoteResponse quote) {
    state = state.copyWith(quote: quote, selectedOption: null).clearError();
  }

  /// Limpia cotización y opción (p. ej. al recalcular ruta en el borrador).
  void clearQuote() {
    state = TripRequestState(
      origin: state.origin,
      destination: state.destination,
      tripId: state.tripId,
      paymentMethod: state.paymentMethod,
      extras: state.extras,
      specials: state.specials,
    );
  }

  void selectOption(QuoteOption option) {
    state = state.copyWith(selectedOption: option);
    _pruneAddonsForFamily(
      passengerServiceFamily(
        serviceTypeId: option.serviceTypeId,
        serviceTypeName: option.serviceTypeName,
      ),
    );
  }

  void setTripId(String tripId) {
    state = state.copyWith(tripId: tripId).clearError();
  }

  /// Limpia solo el tripId (p. ej. matching expirado antes de reintentar).
  void clearTripIdKeepingRoute() {
    state = TripRequestState(
      origin: state.origin,
      destination: state.destination,
      quote: state.quote,
      selectedOption: state.selectedOption,
      paymentMethod: state.paymentMethod,
      extras: state.extras,
      specials: state.specials,
    );
  }

  void setError(String message) {
    state = state.copyWith(error: message);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: TripPaymentMethod.normalize(method));
  }

  void toggleExtra(String code) {
    if (!allowedExtrasForFamily(_family).contains(code)) return;
    state = state.copyWith(extras: state.extras.toggled(code));
  }

  void toggleSpecial(String code) {
    if (!allowedSpecialsForFamily(_family).contains(code)) return;
    state = state.copyWith(specials: state.specials.toggled(code));
  }

  void reset() {
    state = const TripRequestState();
  }
}
