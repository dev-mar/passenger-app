import 'package:dio/dio.dart';

import '../../core/network/trips_api.dart';
import '../../core/storage/trip_session_storage.dart';
import 'trip_request_trip_phase_helpers.dart';

/// Resultado al validar un `tripId` persistido contra el servidor.
enum StoredPassengerTripReconcileOutcome {
  /// No había id persistido.
  noneStored,

  /// Viaje activo/no terminal: conservar sesión local.
  keepStored,

  /// Estado terminal o 404: limpiar almacenamiento.
  clearedTerminal,

  /// Error transitorio (red/5xx): no borrar storage; rehidratar con precaución.
  keepStoredOnTransientError,
}

/// ¿Debemos restaurar el viaje persistido al abrir la app?
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

/// ¿El guard pre-create debe limpiar el storage tras fallo de red?
bool passengerActiveTripGuardShouldClearStorageOnError(Object error) {
  if (error is! DioException) return false;
  final code = error.response?.statusCode;
  return code == 404;
}
