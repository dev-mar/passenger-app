import 'dart:async' show unawaited;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../network/trips_api.dart';
import '../router/app_router.dart';
import '../storage/trip_session_storage.dart';
import '../../features/trip/trip_request_state.dart';
import '../../features/trip/passenger_realtime_controller.dart';
import 'passenger_notification_trip_reconcile.dart';

final ValueNotifier<int> passengerTripChatOpenBump = ValueNotifier<int>(0);
String? _pendingPassengerChatTripIdFromNotification;

String? takePendingPassengerChatTripIdFromNotification() {
  final id = _pendingPassengerChatTripIdFromNotification;
  _pendingPassengerChatTripIdFromNotification = null;
  return id;
}

({String? tripId, bool openChat}) _parsePassengerNotificationPayload(
  String? raw,
) {
  final payload = raw?.trim() ?? '';
  if (payload.isEmpty) return (tripId: null, openChat: false);
  if (payload.startsWith('ops:')) {
    return (tripId: null, openChat: false);
  }
  if (payload.startsWith('chat:')) {
    final tripId = payload.substring(5).trim();
    return (tripId: tripId.isEmpty ? null : tripId, openChat: true);
  }
  return (tripId: payload, openChat: false);
}

Future<void> _persistAndNavigateToTrip(String tripId) async {
  final token = await AuthService.getValidToken();
  if (token == null || token.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppRouter.navigatorKey.currentContext != null) {
        AppRouter.router.goNamed(AppRouter.login);
      }
    });
    return;
  }

  TripStatusResponse? remoteStatus;
  try {
    final api = TripsApi(token: token);
    remoteStatus = await api.getPassengerTripStatus(tripId: tripId);
  } catch (_) {
    remoteStatus = null;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final ctx = AppRouter.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    try {
      final container = ProviderScope.containerOf(ctx, listen: false);
      if (remoteStatus != null &&
          passengerTripStatusIsTerminal(remoteStatus.status)) {
        await clearPassengerTripSessionFromContainer(
          container,
          tripId,
          remoteStatus.status,
        );
        AppRouter.router.goNamed(AppRouter.tripRequest);
        return;
      }
    } catch (_) {} // ignore: empty_catches

    await TripSessionStorage.saveActiveTripId(tripId);
    _applyTripRequestNavigation(tripId);
  });
}

void _applyTripRequestNavigation(String tripId) {
  final ctx = AppRouter.navigatorKey.currentContext;
  if (ctx != null) {
    try {
      final container = ProviderScope.containerOf(ctx, listen: false);
      container.read(tripRequestProvider.notifier).setTripId(tripId);

      Future<void>.delayed(const Duration(milliseconds: 500), () {
        final ctx2 = AppRouter.navigatorKey.currentContext;
        if (ctx2 == null || !ctx2.mounted) return;
        try {
          ProviderScope.containerOf(ctx2, listen: false)
              .read(passengerRealtimeProvider.notifier)
              .syncTripStatusFromApi(tripId: tripId, force: true);
        } catch (_) {}
      });
    } catch (_) {} // ignore: empty_catches
  }
  AppRouter.router.goNamed(AppRouter.tripRequest);
}

void _markPendingPassengerChatOpen(String tripId) {
  _pendingPassengerChatTripIdFromNotification = tripId;
  passengerTripChatOpenBump.value = passengerTripChatOpenBump.value + 1;
}

void _goToPassengerNotices(String? campaignId) {
  final id = campaignId?.trim() ?? '';
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (AppRouter.navigatorKey.currentContext == null) return;
    AppRouter.router.go(
      id.isEmpty ? '/notices' : '/notices?id=${Uri.encodeQueryComponent(id)}',
    );
  });
}

String? _opsCampaignIdFromPayload(String? raw) {
  final payload = raw?.trim() ?? '';
  if (!payload.startsWith('ops:')) return null;
  final id = payload.substring(4).trim();
  return id.isEmpty ? null : id;
}

Future<void> handlePassengerFcmNotificationOpen(RemoteMessage message) async {
  final event = message.data['event']?.toString();
  if (event == 'ops_notice') {
    _goToPassengerNotices(message.data['campaignId']?.toString());
    return;
  }
  if (event != 'driver_arrived' &&
      event != 'trip_chat' &&
      event != 'pickup_grace') {
    return;
  }

  final tripId = message.data['tripId']?.toString().trim();
  if (tripId == null || tripId.isEmpty) return;

  await _persistAndNavigateToTrip(tripId);
  if (event == 'trip_chat') {
    _markPendingPassengerChatOpen(tripId);
  }
}

Future<void> handlePassengerLocalNotificationTripTap(String? payload) async {
  final raw = payload?.trim() ?? '';
  if (raw.startsWith('ops:')) {
    _goToPassengerNotices(_opsCampaignIdFromPayload(raw));
    return;
  }
  final parsed = _parsePassengerNotificationPayload(payload);
  final tripId = parsed.tripId;
  if (tripId == null || tripId.isEmpty) return;
  await _persistAndNavigateToTrip(tripId);
  if (parsed.openChat) {
    _markPendingPassengerChatOpen(tripId);
  }
}

void schedulePassengerFcmNotificationOpen(RemoteMessage message) {
  unawaited(handlePassengerFcmNotificationOpen(message));
}

void schedulePassengerLocalNotificationTripTap(String? payload) {
  unawaited(handlePassengerLocalNotificationTripTap(payload));
}
