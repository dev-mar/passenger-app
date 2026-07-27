import 'package:flutter/foundation.dart';

/// Indica si el sheet de chat del viaje está abierto (omitir sonido/notif duplicados).
class PassengerTripChatVisibility {
  PassengerTripChatVisibility._();

  static final ValueNotifier<String?> openTripId = ValueNotifier<String?>(null);

  static bool isOpenForTrip(String tripId) {
    final open = openTripId.value;
    return open != null && open == tripId;
  }

  static void setOpen(String? tripId) {
    openTripId.value = tripId;
  }
}
