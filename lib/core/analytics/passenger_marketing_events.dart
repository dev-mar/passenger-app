/// Señal de medición a partir de un cambio de estado ya aplicado.
/// No usa identificadores: el viaje solo sirve para no contar dos veces en memoria.
enum PassengerMarketingTripSignal { none, completed, cancelled }

/// `completed` y `cancelled` solo si el estado anterior era un viaje en curso.
/// Rehidratar uno ya cerrado (anterior vacío o ya terminal) no genera señal.
PassengerMarketingTripSignal passengerMarketingSignalForStatus({
  required String? previous,
  required String? next,
}) {
  final prev = previous?.trim().toLowerCase() ?? '';
  final nxt = next?.trim().toLowerCase() ?? '';
  if (prev.isEmpty || prev == nxt || _terminal(prev)) {
    return PassengerMarketingTripSignal.none;
  }
  if (nxt == 'completed') return PassengerMarketingTripSignal.completed;
  if (nxt == 'cancelled') return PassengerMarketingTripSignal.cancelled;
  return PassengerMarketingTripSignal.none;
}

bool _terminal(String status) =>
    status == 'completed' || status == 'cancelled' || status == 'expired';
