import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/passenger_auth_lockout_storage.dart';
import '../login_controller.dart';
import '../models/passenger_auth_lockout.dart';
import 'login_attempts_limit_dialog.dart';
import 'passenger_play_review_credentials.dart';

/// Códigos de bloqueo duro (pantalla persistente o diálogo legacy).
bool isLoginAuthRateLimitCode(String? code) {
  return PassengerAuthLockout.isLockoutCode(code);
}

Future<void> navigateToPassengerAuthLockout(
  BuildContext context, {
  required PassengerAuthLockout lockout,
  required String countryCode,
  required String phoneNumber,
}) async {
  if (PassengerPlayReviewCredentials.isAllowlistedPhone(
    countryCode: countryCode,
    phoneNumber: phoneNumber,
  )) {
    await PassengerAuthLockoutStorage.clear();
    return;
  }
  await PassengerAuthLockoutStorage.save(lockout);
  if (!context.mounted) return;
  context.goNamed(
    'auth_lockout',
    queryParameters: {
      'cc': countryCode,
      'phone': phoneNumber,
    },
  );
}

PassengerAuthLockout? lockoutFromAuthResponse({
  required String? code,
  dynamic responseData,
  String? message,
  String? countryCode,
  String? phoneNumber,
}) {
  return PassengerAuthLockout.tryParse(
    code: code,
    responseData: responseData,
    message: message,
    countryCode: countryCode,
    phoneNumber: phoneNumber,
  );
}

/// Muestra pantalla de lockout o overlay legacy; devuelve `true` si aplicó.
Future<bool> showLoginAuthRateLimitIfNeeded(
  BuildContext context, {
  required String? code,
  dynamic responseData,
  String? message,
  String? countryCode,
  String? phoneNumber,
  String? email,
  bool navigateToLoginOnDismiss = false,
}) async {
  if (PassengerPlayReviewCredentials.shouldBypassClientLockout(
    countryCode: countryCode,
    phoneNumber: phoneNumber,
    email: email,
  )) {
    await PassengerAuthLockoutStorage.clear();
    return false;
  }
  final lockout = lockoutFromAuthResponse(
    code: code,
    responseData: responseData,
    message: message,
    countryCode: countryCode,
    phoneNumber: phoneNumber,
  );
  if (lockout != null &&
      countryCode != null &&
      phoneNumber != null &&
      countryCode.isNotEmpty) {
    await navigateToPassengerAuthLockout(
      context,
      lockout: lockout,
      countryCode: countryCode,
      phoneNumber: phoneNumber,
    );
    return true;
  }
  if (!isLoginAuthRateLimitCode(code)) return false;
  await showLoginAttemptsLimitDialog(
    context,
    navigateToLoginOnDismiss: navigateToLoginOnDismiss,
  );
  return true;
}

Future<void> handleLoginNextStepLockout(
  BuildContext context, {
  required LoginNextStep next,
  required String countryCode,
  required String phoneNumber,
  PassengerAuthLockout? lockout,
}) async {
  if (next == LoginNextStep.authLockout && lockout != null) {
    await navigateToPassengerAuthLockout(
      context,
      lockout: lockout,
      countryCode: countryCode,
      phoneNumber: phoneNumber,
    );
    return;
  }
  if (next == LoginNextStep.attemptsLimitReached) {
    await showLoginAttemptsLimitDialog(
      context,
      navigateToLoginOnDismiss: false,
    );
  }
}
