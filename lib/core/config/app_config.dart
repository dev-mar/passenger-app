import 'passenger_app_environment.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'TEXIAPP';
  static const String packageName = 'com.taxitexi.texi_passenger_app';

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';

  static String get firebaseAndroidApplicationId =>
      PassengerAppEnvironment.firebaseAndroidApplicationId;

  static String get backendBaseUrl => PassengerAppEnvironment.backendBaseUrl;

  static String get baseUrlAuth => '$backendBaseUrl/api/v2';

  static String get baseUrlTripsRest => backendBaseUrl;

  static String get baseUrlSocket => backendBaseUrl;

  static const String loginPath = '/auth/login';

  static const String authVerifyCodePath = '/auth/verify-code';

  static const String authChallengeStatusPath = '/auth/challenge-status';

  static const String authStepUpEmailChallengePath = '/auth/step-up/email-challenge';

  static const String authStepUpCompletePath = '/auth/step-up/complete';

  static const String authUsersPath = '/auth/users';

  static const String authMePath = '/auth/me';

  static const String refreshPath = '/auth/refresh';

  static const String supportTicketsPath = '/support/tickets';
  static const String supportMyTicketsPath = '/support/tickets/me';
  static String supportTicketDetailPath(String ticketId) => '/support/tickets/$ticketId';
  static String supportTicketAttachmentPresignPath(String ticketId) => '/support/tickets/$ticketId/attachments/presign';
  static String supportTicketAttachmentRegisterPath(String ticketId) => '/support/tickets/$ticketId/attachments';

  static const String authGooglePath = '/auth/google';

  static const String authEmailLoginChallengePath = '/auth/login/email-challenge';

  static const String authEmailLoginVerifyPath = '/auth/login/email-verify';

  static const String authLogoutPath = '/auth/logout';

  static const String authPhoneLinkChallengePath = '/auth/phone/link-challenge';
  static const String authPhoneLinkVerifyPath = '/auth/phone/link-verify';

  static String get loginUrl => '$baseUrlAuth$loginPath';

  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasGoogleMapsApiKey => _googleMapsApiKey.isNotEmpty;

  static String? get googleMapsApiKeyOrNull =>
      _googleMapsApiKey.isEmpty ? null : _googleMapsApiKey;

  static String? get googleMapsRestApiKeyOrNull {
    const restKey = String.fromEnvironment(
      'GOOGLE_MAPS_REST_API_KEY',
      defaultValue: '',
    );
    if (restKey.isNotEmpty) return restKey;
    return googleMapsApiKeyOrNull;
  }

  static String get googleMapsApiKey {
    final key = googleMapsApiKeyOrNull;
    if (key == null) {
      throw StateError(
        'Falta GOOGLE_MAPS_API_KEY. Define --dart-define=GOOGLE_MAPS_API_KEY=...',
      );
    }
    return key;
  }

  static bool get passengerInternalToolsVisible =>
      PassengerAppEnvironment.showsInternalToolsByDefault;

  static String? get googleOAuthServerClientId {
    const raw = String.fromEnvironment('GOOGLE_OAUTH_SERVER_CLIENT_ID', defaultValue: '');
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool get googleAuthEnabled => googleOAuthServerClientId != null;
}
