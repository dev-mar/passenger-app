import 'package:dio/dio.dart';

import '../../gen_l10n/app_localizations.dart';
import '../network/passenger_http_resilience.dart';
import '../network/texi_backend_error.dart';

/// Contexto de fallo en el flujo pedir viaje (copy distinto: precio vs enviar).
enum PassengerTripFailureContext { quote, create }

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
    case 'FARES_NOT_CONFIGURED':
      return l10n.tripFaresNotConfigured;
    case 'INVALID_COORDINATES':
      return l10n.tripInvalidCoordinates;
    case 'SERVICE_TYPE_NOT_AVAILABLE':
      return l10n.tripServiceTypeUnavailable;
    case 'INVALID_PAYLOAD':
    case 'TRIP_NOT_ELIGIBLE':
    case 'INVALID_TRIP_ID':
      return l10n.tripRequestInvalid;
    case 'TRIP_CREATE_RATE_LIMITED':
      return l10n.tripCreateRateLimited;
    case 'NO_DRIVERS_AVAILABLE':
      return l10n.tripNoDriversAvailable;
    case 'SESSION_SUPERSEDED':
      return l10n.loginErrorSessionSuperseded;
    case 'PASS_AUTH_PHONE_REQUIRED':
      return l10n.tripPhoneRequired;
    case 'PASS_AUTH_SMS_EMAIL_REQUIRED':
    case 'PASS_AUTH_SMS_GOOGLE_REQUIRED':
    case 'PASS_AUTH_GOOGLE_TOKEN_INVALID':
    case 'PASS_AUTH_GOOGLE_EMAIL_UNVERIFIED':
      return l10n.verifySmsGoogleRequired;
    case 'PASS_AUTH_SMS_NOT_CONFIGURED':
      return l10n.loginErrorVerificationServiceUnavailable;
    case 'PASS_AUTH_SMS_TOKEN_INVALID':
    case 'PASS_AUTH_SMS_PHONE_MISMATCH':
      return l10n.verifyCodeErrorValidateCode;
    case 'PASS_AUTH_SMS_RATE_LIMIT':
      return l10n.loginAttemptsLimitBody;
    case 'TRIP_OPERATIONAL_LOCK':
      return l10n.loginErrorTripOperationalLock;
  }
  if (fb != null && fb.isNotEmpty) {
    final safe = TexiBackendError.userSafeMessage(fb);
    if (safe != null) return safe;
  }
  return l10n.commonError;
}

/// Copy de usuario para cotizar o crear viaje. No expone textos técnicos.
String localizedPassengerTripFailure (
  AppLocalizations l10n, {
  required PassengerTripFailureContext failureContext,
  Object? error,
  String? code,
  String? fallbackMessage,
}) {
  final networkMessage = failureContext == PassengerTripFailureContext.quote
      ? l10n.tripQuoteNetworkError
      : l10n.tripRequestNetworkError;
  final unavailableMessage = failureContext == PassengerTripFailureContext.quote
      ? l10n.tripQuoteUnavailable
      : l10n.tripRequestUnavailable;

  if (error is DioException) {
    if (error.type == DioExceptionType.cancel) {
      return unavailableMessage;
    }
    if (networkErrorCodeFromDio(error) != null ||
        error.response == null ||
        error.type == DioExceptionType.connectionError) {
      return networkMessage;
    }
    if (unavailableBackendCodeFromDio(error) != null) {
      return unavailableMessage;
    }
    code ??= TexiBackendError.codeFromResponse(error.response?.data);
    fallbackMessage ??=
        TexiBackendError.messageFromResponse(error.response?.data);
  }

  if (code == 'INTERNAL_ERROR') {
    return unavailableMessage;
  }
  if (code == 'UNAUTHORIZED' || code == 'INVALID_TOKEN') {
    return l10n.tripRbacSession;
  }

  final mapped = localizedTripApiError(
    l10n,
    code,
    fallbackMessage: fallbackMessage,
  );
  if (mapped != l10n.commonError) return mapped;
  return unavailableMessage;
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
    case 'SOCKET':
    default:
      return l10n.tripConnectionError;
  }
}
