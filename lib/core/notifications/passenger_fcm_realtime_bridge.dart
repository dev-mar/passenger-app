import 'dart:async' show unawaited;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../../features/trip/passenger_realtime_controller.dart';
import '../../features/trip/trip_request_state.dart';

/// Aplica pushes en foreground al estado realtime (status/chat) sin esperar solo WS.
void applyPassengerForegroundPushToRealtime(RemoteMessage message) {
  final event = message.data['event']?.toString().trim();
  final tripId =
      message.data['tripId']?.toString().trim() ??
      message.data['trip_id']?.toString().trim();
  if (tripId == null || tripId.isEmpty) return;
  if (event != 'trip_status' &&
      event != 'driver_arrived' &&
      event != 'trip_chat') {
    return;
  }

  final ctx = AppRouter.navigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;

  ProviderContainer container;
  try {
    container = ProviderScope.containerOf(ctx, listen: false);
  } catch (_) {
    return;
  }

  final rt = container.read(passengerRealtimeProvider.notifier);
  final active =
      container.read(tripRequestProvider).tripId ??
      container.read(passengerRealtimeProvider).activeTripId;
  if (active != null && active.isNotEmpty && active != tripId) return;

  if (container.read(tripRequestProvider).tripId == null) {
    container.read(tripRequestProvider.notifier).setTripId(tripId);
  }

  if (event == 'trip_status' || event == 'driver_arrived') {
    final status = (event == 'driver_arrived')
        ? 'arrived'
        : (message.data['status']?.toString().trim() ?? '');
    if (status.isNotEmpty) {
      rt.applyStatusHintFromPush(tripId: tripId, status: status);
    }
    unawaited(rt.syncTripStatusFromApi(tripId: tripId, force: true));
    unawaited(rt.ensureSocketConnected(tripId: tripId));
    return;
  }

  if (event == 'trip_chat') {
    final body =
        message.notification?.body?.toString() ??
        message.data['body']?.toString() ??
        '';
    if (body.trim().isNotEmpty) {
      rt.ingestChatFromPush(tripId: tripId, messageText: body);
    }
    // Si aún estaba en matching, el ingest ya promueve accepted.
    unawaited(rt.syncTripStatusFromApi(tripId: tripId, force: true));
    unawaited(rt.ensureSocketConnected(tripId: tripId));
  }
}
