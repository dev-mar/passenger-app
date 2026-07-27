import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/passenger_legal_config.dart';

Future<bool> openPassengerExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> openPassengerPrivacyPolicy(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return openPassengerExternalUrl(PassengerLegalConfig.privacyPolicyUrl(locale));
}

Future<bool> openPassengerTerms(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return openPassengerExternalUrl(PassengerLegalConfig.termsUrl(locale));
}

Future<bool> openPassengerAccountDeletionInfo(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return openPassengerExternalUrl(PassengerLegalConfig.accountDeletionUrl(locale));
}
