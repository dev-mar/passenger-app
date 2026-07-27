import 'package:flutter/material.dart';

class PassengerLegalConfig {
  PassengerLegalConfig._();

  static const String _privacyUrlRaw = String.fromEnvironment(
    'TEXI_PRIVACY_POLICY_URL',
    defaultValue: '',
  );
  static const String _termsUrlRaw = String.fromEnvironment(
    'TEXI_TERMS_URL',
    defaultValue: '',
  );
  static const String _accountDeletionUrlRaw = String.fromEnvironment(
    'TEXI_ACCOUNT_DELETION_URL',
    defaultValue: '',
  );

  static const String _privacyEsDefault =
      'https://www.taxitexi.com/es/privacy/passenger';
  static const String _privacyEnDefault =
      'https://www.taxitexi.com/en/privacy/passenger';
  static const String _termsEsDefault =
      'https://www.taxitexi.com/es/terms/passenger';
  static const String _termsEnDefault =
      'https://www.taxitexi.com/en/terms/passenger';
  static const String _accountDeletionEsDefault =
      'https://www.taxitexi.com/es/account-deletion/passenger';
  static const String _accountDeletionEnDefault =
      'https://www.taxitexi.com/en/account-deletion/passenger';

  static String privacyPolicyUrl(Locale locale) {
    final override = _privacyUrlRaw.trim();
    if (override.isNotEmpty) return override;
    return _isSpanish(locale) ? _privacyEsDefault : _privacyEnDefault;
  }

  static String termsUrl(Locale locale) {
    final override = _termsUrlRaw.trim();
    if (override.isNotEmpty) return override;
    return _isSpanish(locale) ? _termsEsDefault : _termsEnDefault;
  }

  static String accountDeletionUrl(Locale locale) {
    final override = _accountDeletionUrlRaw.trim();
    if (override.isNotEmpty) return override;
    return _isSpanish(locale)
        ? _accountDeletionEsDefault
        : _accountDeletionEnDefault;
  }

  static bool _isSpanish(Locale locale) {
    return locale.languageCode.toLowerCase().startsWith('es');
  }
}
