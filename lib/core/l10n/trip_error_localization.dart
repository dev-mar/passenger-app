import '../../gen_l10n/app_localizations.dart';

/// Mensajes amigables para códigos de API/socket (RBAC, sesión, etc.).
String localizedTripApiError (
  AppLocalizations l10n,
  String? code, {
  String? fallbackMessage,
}) {
  final fb = fallbackMessage;
  switch (code) {
    case 'RBAC_FORBIDDEN':
      return l10n.tripRbacForbidden;
    case 'RBAC_NO_IDENTITY':
    case 'RBAC_NO_AUTH':
      return l10n.tripRbacSession;
    case 'RBAC_RESOLVE':
    case 'RBAC_ERROR':
    case 'RBAC_CONFIG':
      return l10n.tripRbacTechnical;
    case 'CITY_NOT_SUPPORTED':
      return l10n.tripNoCoverageInZone;
    case 'NO_DRIVERS_AVAILABLE':
      return l10n.tripNoDriversAvailable;
  }
  if (fb != null && fb.isNotEmpty) return fb;
  return l10n.commonError;
}

/// Errores del realtime pasajero (`PassengerRealtimeState.errorCode`).
String localizedPassengerRealtimeError (
  AppLocalizations l10n,
  String? code,
) {
  switch (code) {
    case 'NO_TOKEN':
      return l10n.tripRealtimeNoToken;
    case 'RBAC_FORBIDDEN':
      return l10n.tripRbacForbidden;
    case 'RBAC_NO_IDENTITY':
    case 'RBAC_NO_AUTH':
      return l10n.tripRbacSession;
    case 'RBAC_RESOLVE':
    case 'RBAC_ERROR':
    case 'RBAC_CONFIG':
      return l10n.tripRbacTechnical;
    case 'UNKNOWN':
      return l10n.commonError;
    case 'SOCKET':
    default:
      return l10n.tripConnectionError;
  }
}
