import 'dart:async' show unawaited;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_service.dart';
import '../auth/passenger_session_expulsion.dart';

/// True si el push indica cierre forzado de sesión / cuenta eliminada.
bool isPassengerForceLogoutPush(RemoteMessage message) {
  final event = message.data['event']?.toString().trim().toLowerCase() ?? '';
  final code = message.data['code']?.toString().trim().toUpperCase() ?? '';
  if (event == 'force_logout' || event == 'account_deleted') return true;
  return code == 'ACCOUNT_DELETED' ||
      code == 'ACCOUNT_DELETION_SCHEDULED' ||
      code == 'SESSION_SUPERSEDED';
}

/// Limpia sesión local y navega a login (si hay UI). Seguro en foreground.
Future<void> handlePassengerForceLogoutFromPush(RemoteMessage message) async {
  if (!isPassengerForceLogoutPush(message)) return;
  if (kDebugMode) {
    debugPrint(
      '[PASSENGER_FCM] force_logout code=${message.data['code']} event=${message.data['event']}',
    );
  }
  markPassengerSessionExpelled();
  try {
    await AuthService.logout();
  } catch (_) {}
  AuthService.onSessionExpired?.call();
}

/// Variante para isolate de background: solo limpia tokens locales.
Future<void> clearPassengerSessionFromBackgroundPush(RemoteMessage message) async {
  if (!isPassengerForceLogoutPush(message)) return;
  markPassengerSessionExpelled();
  try {
    await AuthService.logout();
  } catch (_) {}
}

void schedulePassengerForceLogoutFromPush(RemoteMessage message) {
  if (!isPassengerForceLogoutPush(message)) return;
  unawaited(handlePassengerForceLogoutFromPush(message));
}
