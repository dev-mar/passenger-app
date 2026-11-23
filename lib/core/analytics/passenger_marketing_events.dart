enum PassengerMarketingTripSignal { none, completed, cancelled }

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
