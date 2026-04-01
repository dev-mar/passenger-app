import 'package:flutter/foundation.dart';

/// Estado de visibilidad de la app pasajero para decidir notificaciones locales.
class PassengerAppVisibility {
  PassengerAppVisibility._();

  /// true cuando la app está visible (resumed).
  static final ValueNotifier<bool> isInForeground = ValueNotifier(true);
}

