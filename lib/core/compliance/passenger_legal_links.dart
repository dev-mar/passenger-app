import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/passenger_legal_config.dart';
import '../../gen_l10n/app_localizations.dart';
import 'passenger_account_deletion_service.dart';

enum PassengerAccountDeletionFlow { schedule, cancel }

String localizedPassengerAccountDeletionFailure(
  AppLocalizations l10n,
  PassengerAccountDeletionFailure failure, {
  required PassengerAccountDeletionFlow flow,
}) {
  if (failure.code == 'SESSION_EXPIRED') {
    return l10n.passengerAccountDeletionErrorSessionExpired;
  }
  final message = failure.message.trim();
  if (message.isNotEmpty) return message;
  return flow == PassengerAccountDeletionFlow.schedule
      ? l10n.passengerAccountDeletionErrorScheduleFailed
      : l10n.passengerAccountDeletionErrorCancelFailed;
}

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
