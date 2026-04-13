import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/trip_session_storage.dart';
import '../../features/trip/passenger_realtime_controller.dart';
import '../../features/trip/trip_recovery_feedback.dart';
import '../../features/trip/trip_request_state.dart';

/// Estados finales conocidos del viaje en pasajero (REST / socket).
bool passengerTripStatusIsTerminal(String status) {
  final s = status.toLowerCase();
  return s == 'completed' || s == 'cancelled' || s == 'expired';
}

/// Limpia providers y almacenamiento como al cerrar un viaje terminado desde la pantalla de mapa.
/// [terminalStatus] debe ser `completed`, `cancelled` o `expired` (según [passengerTripStatusIsTerminal]).
Future<void> clearPassengerTripSessionFromContainer(
  ProviderContainer container,
  String tripId,
  String terminalStatus,
) async {
  final s = terminalStatus.toLowerCase();
  container.read(passengerRealtimeProvider.notifier).disconnect();
  clearTripRecoverySnackTrackingForContainer(container);
  container.read(tripRequestProvider.notifier).reset();
  if (s == 'completed') {
    await TripSessionStorage.setRatingDone(tripId, true);
  }
  await TripSessionStorage.clearActiveTripId();
  container.read(passengerTripMapUiResetTickProvider.notifier).state++;
}
