import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/auth/passenger_session_expulsion.dart';
import '../../core/app_lifecycle/passenger_app_visibility.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/passenger_locale_holder.dart';
import '../../core/notifications/passenger_notification_service.dart';
import '../../core/notifications/passenger_trip_chat_visibility.dart';
import '../../core/network/trips_api.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../data/models/quote_response.dart';
import 'passenger_trip_chat_l10n.dart';
import 'passenger_trip_vehicle_info.dart';
import 'passenger_realtime_state.dart';
import 'trip_request_trip_phase_helpers.dart';

export 'passenger_realtime_state.dart';

part 'passenger_realtime_controller.tracking.dart';
part 'passenger_realtime_controller.socket.dart';
part 'passenger_realtime_controller.chat.dart';

String _localizedArrivalReminderMessage() {
  return PassengerLocaleHolder.l10n().passengerNotifyArrivalReminder;
}

final passengerRealtimeProvider =
    StateNotifierProvider<PassengerRealtimeController, PassengerRealtimeState>(
      (ref) => PassengerRealtimeController(),
    );

/// Orquestador realtime pasajero: socket + sync REST + chat (part files).
class PassengerRealtimeController extends StateNotifier<PassengerRealtimeState>
    with
        _PassengerRealtimeTrackingMixin,
        _PassengerRealtimeSocketMixin,
        _PassengerRealtimeChatMixin {
  PassengerRealtimeController() : super(PassengerRealtimeState.initial);

  io.Socket? _socket;
  StreamSubscription? _reconnectSub;
  DateTime? _lastTripSyncApiAt;
  static const _tripSyncMinGap = Duration(seconds: 2);
  Timer? _driverLocationDebounceTimer;
  Timer? _driverMarkerLerpTimer;
  Timer? _connectTimeoutTimer;
  DateTime? _connectStartedAt;
  double? _pendingDriverLat;
  double? _pendingDriverLng;
  double? _pendingDriverBearing;
  bool _tearDown = false;
  static const _connectStuckAfter = Duration(seconds: 12);
  static const _connectHardTimeout = Duration(seconds: 25);
  static const _minDriverDeltaDegrees = 0.00002;
  static const _minBearingDelta = 4.0;
  static const _driverLerpTotalSteps = 6;
  static const _driverLerpStepDuration = Duration(milliseconds: 55);

  void disconnect() {
    _tearDown = true;
    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = null;
    _connectStartedAt = null;
    _driverLocationDebounceTimer?.cancel();
    _driverLocationDebounceTimer = null;
    _driverMarkerLerpTimer?.cancel();
    _driverMarkerLerpTimer = null;
    _pendingDriverLat = null;
    _pendingDriverLng = null;
    _pendingDriverBearing = null;
    _lastTripSyncApiAt = null;
    _reconnectSub?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _tearDown = false;
    state = PassengerRealtimeState.initial;
  }

  @override
  void dispose() {
    _tearDown = true;
    _connectTimeoutTimer?.cancel();
    _driverLocationDebounceTimer?.cancel();
    _driverMarkerLerpTimer?.cancel();
    _reconnectSub?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}
