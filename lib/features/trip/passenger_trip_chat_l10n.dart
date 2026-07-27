import '../../gen_l10n/app_localizations.dart';
import 'passenger_realtime_state.dart';

String? _passengerTripChatTemplateText(AppLocalizations l10n, String code) {
  switch (code.toUpperCase()) {
    case 'CANT_FIND_VEHICLE':
      return l10n.passengerTripChatTemplateCantFindVehicle;
    case 'WHERE_ARE_YOU':
      return l10n.passengerTripChatTemplateWhereAreYou;
    case 'IM_WAITING_HERE':
      return l10n.passengerTripChatTemplateWaitingHere;
    case 'I_AM_AT_PICKUP':
      return l10n.passengerTripChatDriverTemplateAtPickup;
    case 'CANNOT_FIND_PASSENGER':
      return l10n.passengerTripChatDriverTemplateCannotFind;
    case 'PLEASE_CONFIRM_LOCATION':
      return l10n.passengerTripChatDriverTemplateConfirmLocation;
    default:
      return null;
  }
}

/// Texto visible de chat según idioma de la app (plantillas por código).
String localizedPassengerTripChatMessage(
  AppLocalizations l10n,
  TripChatMessage msg,
) {
  final code = (msg.templateCode ?? '').trim();
  if (code.isNotEmpty) {
    final localized = _passengerTripChatTemplateText(l10n, code);
    if (localized != null) return localized;
  }
  if (msg.messageKind == 'template') {
    return msg.messageText;
  }
  return msg.messageText;
}
