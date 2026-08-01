import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/trips_api.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../data/models/quote_response.dart';
import 'passenger_realtime_controller.dart';
import 'passenger_stored_trip_session_helper.dart';
import 'trip_recovery_feedback.dart';
import 'trip_request_state.dart';
import 'trip_request_trip_phase_helpers.dart';

/// Resultado de comprobar si ya hay un viaje activo antes de crear otro.
enum ActiveTripGuardResult {
  /// No hay viaje pendiente en servidor (o era inválido): se puede llamar a `POST /passengers/trips`.
  allowCreateNew,

  /// Había un viaje aún vigente: se rehidrató `tripId`, quote mínimo y socket; no crear otro viaje.
  recoveredExisting,
}

Future<void> _recoverExistingPassengerTrip({
  required WidgetRef ref,
  required String tid,
  QuoteResponse? quoteForSocket,
}) async {
  ref.read(tripRequestProvider.notifier).setTripId(tid);
  final existingQuote = ref.read(tripRequestProvider).quote;
  final q = existingQuote ?? quoteForSocket;
  if (existingQuote == null && quoteForSocket != null) {
    ref.read(tripRequestProvider.notifier).setQuote(quoteForSocket);
  }

  ref.read(passengerRealtimeProvider.notifier).disconnect();
  ref.read(passengerRealtimeProvider.notifier).connect(
        tripId: tid,
        quote: q,
      );
  await ref.read(passengerRealtimeProvider.notifier).syncTripStatusFromApi(
        tripId: tid,
      );
}

/// Evita un segundo `POST /passengers/trips` cuando el pasajero ya tiene un viaje en curso
/// (p. ej. cerró la app en "buscando conductor" y el `tripId` sigue en almacenamiento).
///
/// - Si `GET /passengers/trips/:id` indica estado final, limpia almacenamiento y provider.
/// - Cualquier otro estado no final → [recoveredExisting] (reconectar socket, no duplicar).
/// - Error de red/5xx → [recoveredExisting] sin borrar storage (evita duplicar viaje).
Future<ActiveTripGuardResult> reconcileActiveTripBeforeCreateTrip({
  required WidgetRef ref,
  required TripsApi api,
  QuoteResponse? quoteForSocket,
}) async {
  final fromProvider = ref.read(tripRequestProvider).tripId;
  final fromStorage = await TripSessionStorage.getActiveTripId();
  final tid = (fromProvider != null && fromProvider.isNotEmpty)
      ? fromProvider
      : (fromStorage != null && fromStorage.isNotEmpty ? fromStorage : null);

  if (tid == null || tid.isEmpty) {
    return ActiveTripGuardResult.allowCreateNew;
  }

  try {
    final st = await api.getPassengerTripStatus(tripId: tid);
    final s = st.status;

    if (passengerTripIsFinalStatus(s)) {
      await TripSessionStorage.clearActiveTripId();
      clearTripRecoverySnackTracking(ref);
      ref.read(tripRequestProvider.notifier).reset();
      ref.read(passengerRealtimeProvider.notifier).disconnect();
      return ActiveTripGuardResult.allowCreateNew;
    }

    await _recoverExistingPassengerTrip(
      ref: ref,
      tid: tid,
      quoteForSocket: quoteForSocket,
    );
    return ActiveTripGuardResult.recoveredExisting;
  } catch (e) {
    if (passengerActiveTripGuardShouldClearStorageOnError(e)) {
      await TripSessionStorage.clearActiveTripId();
      clearTripRecoverySnackTracking(ref);
      ref.read(passengerRealtimeProvider.notifier).disconnect();
      ref.read(tripRequestProvider.notifier).reset();
      return ActiveTripGuardResult.allowCreateNew;
    }

    await _recoverExistingPassengerTrip(
      ref: ref,
      tid: tid,
      quoteForSocket: quoteForSocket,
    );
    return ActiveTripGuardResult.recoveredExisting;
  }
}
