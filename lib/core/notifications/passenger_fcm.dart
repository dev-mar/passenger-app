import 'dart:async' show unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'passenger_fcm_navigation.dart';
import 'passenger_fcm_realtime_bridge.dart';
import 'passenger_force_logout_from_push.dart';
import 'passenger_notification_service.dart';
import 'passenger_push_token_service.dart';

/// Registrado antes de `runApp`. Ejecuta en isolate propio cuando la app está
/// en segundo plano o cerrada (mensajes data-only o sin presentación del sistema).
@pragma('vm:entry-point')
Future<void> passengerFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (isPassengerForceLogoutPush(message)) {
    await clearPassengerSessionFromBackgroundPush(message);
    return;
  }
  if (message.notification != null) {
    // Con payload `notification`, Android suele mostrar la notificación del sistema.
    return;
  }
  await PassengerNotificationService.showFcmDataOnlyMessage(message);
}

/// Permisos, listeners y refresco de token (llamar tras [Firebase.initializeApp]).
Future<void> setupPassengerFirebaseMessaging() async {
  if (Firebase.apps.isEmpty) return;

  final messaging = FirebaseMessaging.instance;

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // POST_NOTIFICATIONS / FCM: solo tras divulgación in-app (ver compliance).

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (isPassengerForceLogoutPush(message)) {
      schedulePassengerForceLogoutFromPush(message);
      return;
    }
    unawaited(_showForegroundFcmDeduped(message));
  });

  FirebaseMessaging.onMessageOpenedApp.listen(schedulePassengerFcmNotificationOpen);

  messaging.onTokenRefresh.listen((_) {
    unawaited(PassengerPushTokenService.instance.syncTokenIfPossible());
  });
}

final Map<String, DateTime> _passengerFcmForegroundDedupe = {};

Future<void> _showForegroundFcmDeduped(RemoteMessage message) async {
  final id = message.messageId?.trim();
  final tripId =
      message.data['tripId']?.toString() ??
      message.data['trip_id']?.toString() ??
      '';
  final title =
      message.notification?.title ?? message.data['title']?.toString() ?? '';
  final body =
      message.notification?.body ?? message.data['body']?.toString() ?? '';
  final key = (id != null && id.isNotEmpty)
      ? 'mid:$id'
      : 'tb:$tripId|$title|$body';
  final now = DateTime.now();
  final prev = _passengerFcmForegroundDedupe[key];
  if (prev != null && now.difference(prev) < const Duration(seconds: 8)) {
    return;
  }
  _passengerFcmForegroundDedupe[key] = now;
  if (_passengerFcmForegroundDedupe.length > 40) {
    _passengerFcmForegroundDedupe.removeWhere(
      (_, t) => now.difference(t) > const Duration(minutes: 2),
    );
  }
  // Hidrata status/chat aunque el WS vaya atrasado o desconectado.
  applyPassengerForegroundPushToRealtime(message);
  await PassengerNotificationService.instance.showFcmForegroundMessage(message);
}
