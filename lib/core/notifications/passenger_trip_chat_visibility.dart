import 'package:flutter/foundation.dart';

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
