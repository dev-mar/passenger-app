import 'package:flutter/widgets.dart';

import '../../gen_l10n/app_localizations.dart';

/// Locale activo de la app (MaterialApp) para servicios sin [BuildContext].
class PassengerLocaleHolder {
  PassengerLocaleHolder._();

  static Locale? appLocale;

  static Locale _resolvedLocale(Locale? raw) {
    final code = (raw ?? WidgetsBinding.instance.platformDispatcher.locale)
        .languageCode
        .toLowerCase();
    return code == 'en' ? const Locale('en') : const Locale('es');
  }

  static AppLocalizations l10n() {
    return lookupAppLocalizations(_resolvedLocale(appLocale));
  }
}
