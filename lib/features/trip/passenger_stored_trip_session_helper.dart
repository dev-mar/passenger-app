import 'package:dio/dio.dart';

import '../../core/network/trips_api.dart';
import '../../core/storage/trip_session_storage.dart';
import 'trip_request_trip_phase_helpers.dart';

enum StoredPassengerTripReconcileOutcome {

  noneStored,

  keepStored,

  clearedTerminal,

  keepStoredOnTransientError,
}

Future<StoredPassengerTripReconcileOutcome> reconcileStoredPassengerTripId({
  required String? storedTripId,
  required String token,
}) async {
  final tid = storedTripId?.trim();
  if (tid == null || tid.isEmpty) {
    return StoredPassengerTripReconcileOutcome.noneStored;
  }

  try {
    final api = TripsApi(token: token);
    final st = await api.getPassengerTripStatus(tripId: tid);
    if (passengerTripIsFinalStatus(st.status)) {
      await TripSessionStorage.clearActiveTripId();
      return StoredPassengerTripReconcileOutcome.clearedTerminal;
    }
    return StoredPassengerTripReconcileOutcome.keepStored;
  } on DioException catch (e) {
    final code = e.response?.statusCode;
    if (code == 404) {
      await TripSessionStorage.clearActiveTripId();
      return StoredPassengerTripReconcileOutcome.clearedTerminal;
    }
    return StoredPassengerTripReconcileOutcome.keepStoredOnTransientError;
  } catch (_) {
    return StoredPassengerTripReconcileOutcome.keepStoredOnTransientError;
  }
}

bool passengerActiveTripGuardShouldClearStorageOnError(Object error) {
  if (error is! DioException) return false;
  final code = error.response?.statusCode;
  return code == 404;
}
