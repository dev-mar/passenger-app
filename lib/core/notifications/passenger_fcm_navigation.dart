import 'dart:async' show unawaited;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../router/app_router.dart';
import '../storage/trip_session_storage.dart';
import '../../features/trip/trip_request_state.dart';
import '../../features/trip/passenger_realtime_controller.dart';

Future<void> _persistAndNavigateToTrip(String tripId) async {
  await TripSessionStorage.saveActiveTripId(tripId);

  final token = await AuthService.getValidToken();
  if (token == null || token.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppRouter.navigatorKey.currentContext != null) {
        AppRouter.router.goNamed(AppRouter.login);
      }
    });
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _applyTripRequestNavigation(tripId);
  });
}

void _applyTripRequestNavigation(String tripId) {
  final ctx = AppRouter.navigatorKey.currentContext;
  if (ctx != null) {
    try {
      final container = ProviderScope.containerOf(ctx, listen: false);
      container.read(tripRequestProvider.notifier).setTripId(tripId);
      // FCM no abre el socket: alinear estado con REST tras un tick de navegación.
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        final ctx2 = AppRouter.navigatorKey.currentContext;
        if (ctx2 == null || !ctx2.mounted) return;
        try {
          ProviderScope.containerOf(ctx2, listen: false)
              .read(passengerRealtimeProvider.notifier)
              .syncTripStatusFromApi(tripId: tripId, force: true);
        } catch (_) {}
      });
    } catch (_) {
      // TripRequestScreen hidrata desde [TripSessionStorage] si hace falta.
    }
  }
  AppRouter.router.goNamed(AppRouter.tripRequest);
}

/// FCM con `event: driver_arrived` y `tripId` (contrato backend).
Future<void> handlePassengerFcmNotificationOpen(RemoteMessage message) async {
  final event = message.data['event']?.toString();
  if (event != 'driver_arrived') return;

  final tripId = message.data['tripId']?.toString().trim();
  if (tripId == null || tripId.isEmpty) return;

  await _persistAndNavigateToTrip(tripId);
}

/// Tap en notificación local (payload = `tripId`, p. ej. conductor llegó en foreground).
Future<void> handlePassengerLocalNotificationTripTap(String? payload) async {
  final tripId = payload?.trim();
  if (tripId == null || tripId.isEmpty) return;
  await _persistAndNavigateToTrip(tripId);
}

void schedulePassengerFcmNotificationOpen(RemoteMessage message) {
  unawaited(handlePassengerFcmNotificationOpen(message));
}

void schedulePassengerLocalNotificationTripTap(String? payload) {
  unawaited(handlePassengerLocalNotificationTripTap(payload));
}
