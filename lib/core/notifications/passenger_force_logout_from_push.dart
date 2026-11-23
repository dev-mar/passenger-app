import 'dart:async' show unawaited;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_service.dart';
import '../auth/passenger_session_expulsion.dart';

bool isPassengerForceLogoutPush(RemoteMessage message) {
  final event = message.data['event']?.toString().trim().toLowerCase() ?? '';
  final code = message.data['code']?.toString().trim().toUpperCase() ?? '';
  if (event == 'force_logout' || event == 'account_deleted') return true;
  return code == 'ACCOUNT_DELETED' ||
      code == 'ACCOUNT_DELETION_SCHEDULED' ||
      code == 'SESSION_SUPERSEDED';
}

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
