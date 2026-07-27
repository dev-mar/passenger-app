import 'dart:async' show unawaited;
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../gen_l10n/app_localizations.dart';
import '../notifications/passenger_notification_service.dart';
import '../notifications/passenger_push_token_service.dart';

/// Divulgaciones Play antes de permisos sensibles (viaje / mapa).
Future<bool> passengerEnsurePlayDisclosuresBeforeTripFlow(
  BuildContext context,
  AppLocalizations l10n,
) async {
  if (!context.mounted) return false;

  if (Platform.isAndroid || defaultTargetPlatform == TargetPlatform.iOS) {
    final notifOk = await passengerEnsureNotificationDisclosureForTripUpdates(
      context,
      l10n,
    );
    if (!notifOk || !context.mounted) return false;
  }

  if (!kIsWeb &&
      (Platform.isAndroid || defaultTargetPlatform == TargetPlatform.iOS)) {
    final locOk = await _ensureForegroundLocationDisclosure(context, l10n);
    if (!locOk || !context.mounted) return false;
  }

  return true;
}

/// Solo notificaciones (viaje activo, chat, llegada del conductor).
Future<bool> passengerEnsureNotificationDisclosureForTripUpdates(
  BuildContext context,
  AppLocalizations l10n,
) async {
  return _ensureNotificationDisclosure(context, l10n);
}

Future<bool> _notificationPermissionsGranted() async {
  if (!Platform.isAndroid && defaultTargetPlatform != TargetPlatform.iOS) {
    return true;
  }

  await PassengerNotificationService.instance.initialize();
  final fcmSettings = await FirebaseMessaging.instance.getNotificationSettings();
  final fcmOk = _notificationAuthorized(fcmSettings);

  if (Platform.isAndroid) {
    final androidOk =
        await PassengerNotificationService.instance
            .areAndroidNotificationsEnabled();
    return fcmOk && androidOk;
  }

  return fcmOk;
}

Future<bool> _ensureNotificationDisclosure(
  BuildContext context,
  AppLocalizations l10n,
) async {
  if (!Platform.isAndroid && defaultTargetPlatform != TargetPlatform.iOS) {
    return true;
  }

  if (await _notificationPermissionsGranted()) {
    return true;
  }

  if (!context.mounted) return false;
  final proceed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.passengerPlayNotificationDisclosureTitle),
        content: Text(l10n.passengerPlayNotificationDisclosureBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.passengerPlayDisclosureContinue),
          ),
        ],
      );
    },
  );
  if (proceed != true) return false;

  await PassengerNotificationService.instance
      .requestAndroidPostNotificationsPermission();
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  unawaited(PassengerPushTokenService.instance.syncTokenIfPossible());

  return _notificationPermissionsGranted();
}

Future<bool> _ensureForegroundLocationDisclosure(
  BuildContext context,
  AppLocalizations l10n,
) async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always) {
    return true;
  }
  if (permission == LocationPermission.deniedForever) {
    return false;
  }

  if (!context.mounted) return false;
  final proceed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.passengerPlayLocationDisclosureTitle),
        content: Text(l10n.passengerPlayLocationDisclosureBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.passengerPlayDisclosureContinue),
          ),
        ],
      );
    },
  );
  if (proceed != true) return false;

  await Geolocator.requestPermission();
  return true;
}

bool _notificationAuthorized(NotificationSettings settings) {
  final s = settings.authorizationStatus;
  return s == AuthorizationStatus.authorized ||
      s == AuthorizationStatus.provisional;
}
