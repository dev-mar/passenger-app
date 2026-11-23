import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/trips_api.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../data/models/quote_response.dart';
import 'passenger_realtime_controller.dart';
import 'trip_recovery_feedback.dart';
import 'trip_request_state.dart';
import 'trip_request_trip_phase_helpers.dart';

enum ActiveTripGuardResult {

  allowCreateNew,

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

      ref.read(tripRequestProvider.notifier).clearTripIdKeepingRoute();
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
    await TripSessionStorage.clearActiveTripId();
    clearTripRecoverySnackTracking(ref);
    ref.read(passengerRealtimeProvider.notifier).disconnect();
    ref.read(tripRequestProvider.notifier).clearTripIdKeepingRoute();
    return ActiveTripGuardResult.allowCreateNew;
  }
}
