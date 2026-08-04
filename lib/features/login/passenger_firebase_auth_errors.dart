import 'package:flutter/material.dart';

import '../../gen_l10n/app_localizations.dart';

enum PassengerFirebaseAuthErrorKind {
  phoneDisabled,
  notConfigured,
  shaMissing,
  rateLimited,
  smsTemporarilyBlocked,
  captchaFailed,
  network,
  googleCancelled,
  generic,
}

bool isTechnicalFirebaseAuthMessage(String? rawMessage) {
  if (rawMessage == null || rawMessage.trim().isEmpty) return false;
  final m = rawMessage.trim().toLowerCase();
  return m.contains('internal error') ||
      m.contains('error code:') ||
      m.contains('backenderror') ||
      m.contains('unknown status code') ||
      m.contains('firebaseexception');
}

/// Clasifica códigos/mensajes crudos de Firebase Auth.
PassengerFirebaseAuthErrorKind classifyPassengerFirebaseAuthError({
  String? code,
  String? rawMessage,
}) {
  final normalizedCode = (code ?? '').trim().toLowerCase();
  final normalizedMessage = (rawMessage ?? '').trim().toLowerCase();
  final combined = '$normalizedCode $normalizedMessage';

  if (normalizedCode.contains('configuration_not_found') ||
      normalizedCode.contains('configuration-not-found') ||
      combined.contains('configuration-not-found')) {
    return PassengerFirebaseAuthErrorKind.notConfigured;
  }
  if (normalizedCode.contains('operation-not-allowed') ||
      normalizedCode.contains('operation_not_allowed') ||
      combined.contains('operation-not-allowed')) {
    return PassengerFirebaseAuthErrorKind.phoneDisabled;
  }
  if (normalizedCode.contains('invalid-app-credential') ||
      normalizedCode.contains('missing-client-identifier') ||
      combined.contains('invalid-app-credential') ||
      combined.contains('missing-client-identifier')) {
    return PassengerFirebaseAuthErrorKind.shaMissing;
  }
  if (normalizedCode.contains('too-many-requests') ||
      normalizedCode.contains('quota-exceeded') ||
      combined.contains('too-many-requests') ||
      combined.contains('quota-exceeded')) {
    return PassengerFirebaseAuthErrorKind.rateLimited;
  }
  if (combined.contains('error code:39') ||
      combined.contains('error code: 39') ||
      combined.contains('17499') ||
      normalizedCode.contains('internal-error') ||
      (normalizedCode.contains('unknown') && combined.contains('39'))) {
    return PassengerFirebaseAuthErrorKind.smsTemporarilyBlocked;
  }
  if (normalizedCode.contains('captcha') ||
      normalizedCode.contains('recaptcha') ||
      combined.contains('recaptcha')) {
    return PassengerFirebaseAuthErrorKind.captchaFailed;
  }
  if (normalizedCode.contains('network-request-failed') ||
      combined.contains('network-request-failed')) {
    return PassengerFirebaseAuthErrorKind.network;
  }
  return PassengerFirebaseAuthErrorKind.generic;
}

/// Mensajes amigables para errores Firebase Auth (Phone / credenciales).
String localizedPassengerFirebaseAuthError(
  AppLocalizations l10n, {
  String? code,
  String? rawMessage,
}) {
  return passengerSmsAuthErrorPresentation(
    l10n,
    kind: classifyPassengerFirebaseAuthError(code: code, rawMessage: rawMessage),
    rawMessage: rawMessage,
  ).message;
}

class PassengerSmsAuthErrorPresentation {
  const PassengerSmsAuthErrorPresentation({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
    this.preferBackToLogin = false,
    this.suggestWhatsAppAlternative = false,
  });

  final PassengerFirebaseAuthErrorKind kind;
  final String title;
  final String message;
  final IconData icon;
  final bool preferBackToLogin;
  final bool suggestWhatsAppAlternative;
}

PassengerSmsAuthErrorPresentation passengerSmsAuthErrorPresentation(
  AppLocalizations l10n, {
  required PassengerFirebaseAuthErrorKind kind,
  String? rawMessage,
}) {
  switch (kind) {
    case PassengerFirebaseAuthErrorKind.phoneDisabled:
      return PassengerSmsAuthErrorPresentation(
        kind: kind,
        title: l10n.verifySmsErrorTitleSmsUnavailable,
        message: l10n.verifySmsFirebasePhoneDisabled,
        icon: Icons.sms_failed_outlined,
        preferBackToLogin: true,
      );
    case PassengerFirebaseAuthErrorKind.notConfigured:
    case PassengerFirebaseAuthErrorKind.shaMissing:
      return PassengerSmsAuthErrorPresentation(
        kind: kind,
        title: l10n.verifySmsErrorTitleSmsUnavailable,
        message: kind == PassengerFirebaseAuthErrorKind.shaMissing
            ? l10n.verifySmsFirebaseShaMissing
            : l10n.verifySmsFirebaseNotConfigured,
        icon: Icons.phonelink_setup_outlined,
        preferBackToLogin: true,
      );
    case PassengerFirebaseAuthErrorKind.rateLimited:
      return PassengerSmsAuthErrorPresentation(
        kind: kind,
        title: l10n.verifySmsErrorTitleRateLimited,
        message: l10n.verifySmsFirebaseRateLimited,
        icon: Icons.hourglass_top_rounded,
        suggestWhatsAppAlternative: true,
      );
    case PassengerFirebaseAuthErrorKind.smsTemporarilyBlocked:
      return PassengerSmsAuthErrorPresentation(
        kind: kind,
        title: l10n.verifySmsErrorTitleSmsBlocked,
        message: l10n.verifySmsFirebaseError39,
        icon: Icons.shield_outlined,
        suggestWhatsAppAlternative: true,
      );
    case PassengerFirebaseAuthErrorKind.captchaFailed:
      return PassengerSmsAuthErrorPresentation(
        kind: kind,
        title: l10n.verifySmsErrorTitleCaptcha,
        message: l10n.verifySmsFirebaseCaptchaFailed,
        icon: Icons.verified_user_outlined,
        suggestWhatsAppAlternative: true,
      );
    case PassengerFirebaseAuthErrorKind.network:
      return PassengerSmsAuthErrorPresentation(
        kind: kind,
        title: l10n.verifySmsErrorTitleNetwork,
        message: l10n.verifyCodeErrorNetwork,
        icon: Icons.wifi_off_rounded,
      );
    case PassengerFirebaseAuthErrorKind.googleCancelled:
      return PassengerSmsAuthErrorPresentation(
        kind: kind,
        title: l10n.verifySmsErrorTitleGoogleCancelled,
        message: l10n.verifySmsGoogleCancelled,
        icon: Icons.account_circle_outlined,
      );
    case PassengerFirebaseAuthErrorKind.generic:
      final fallback = rawMessage?.trim();
      final safeMessage = (fallback != null &&
              fallback.isNotEmpty &&
              !isTechnicalFirebaseAuthMessage(fallback))
          ? fallback
          : l10n.verifyCodeSmsFailed;
      return PassengerSmsAuthErrorPresentation(
        kind: kind,
        title: l10n.verifySmsErrorTitleGeneric,
        message: safeMessage,
        icon: Icons.info_outline_rounded,
        suggestWhatsAppAlternative: isTechnicalFirebaseAuthMessage(fallback),
      );
  }
}

PassengerSmsAuthErrorPresentation passengerSmsGenericErrorPresentation(
  AppLocalizations l10n, {
  required String message,
}) {
  return PassengerSmsAuthErrorPresentation(
    kind: PassengerFirebaseAuthErrorKind.generic,
    title: l10n.verifySmsErrorTitleGeneric,
    message: message,
    icon: Icons.info_outline_rounded,
  );
}
