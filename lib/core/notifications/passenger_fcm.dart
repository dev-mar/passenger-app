import 'dart:async' show unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'passenger_fcm_navigation.dart';
import 'passenger_notification_service.dart';
import 'passenger_push_token_service.dart';

/// Registrado antes de `runApp`. Ejecuta en isolate propio cuando la app está
/// en segundo plano o cerrada (mensajes data-only o sin presentación del sistema).
@pragma('vm:entry-point')
Future<void> passengerFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.notification != null) {
    // Con payload `notification`, Android suele mostrar la notificación del sistema.
    return;
  }
  await PassengerNotificationService.showFcmDataOnlyMessage(message);
}

/// Permisos, listeners y refresco de token (llamar tras [Firebase.initializeApp]).
Future<void> setupPassengerFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    unawaited(
      PassengerNotificationService.instance.showFcmForegroundMessage(message),
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen(schedulePassengerFcmNotificationOpen);

  messaging.onTokenRefresh.listen((_) {
    unawaited(PassengerPushTokenService.instance.syncTokenIfPossible());
  });
}
