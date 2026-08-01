import 'passenger_app_environment.dart';

/// Configuración centralizada: un solo host `app_texi_WebSocket` (mismo que conductor).
///
/// Entorno dev/prod: `--dart-define=TEXI_APP_ENV=dev|prod`
/// Override URL: `--dart-define=TEXI_BACKEND_BASE_URL=...`
/// Humo WA en dev: `--dart-define=TEXI_PASSENGER_MULTICHANNEL_AUTH=true`
class AppConfig {
  AppConfig._();

  static const String appName = 'TEXIAPP';
  static const String packageName = 'com.taxitexi.texi_passenger_app';

  /// `applicationId` Android (debe coincidir con `google-services.json` / FCM).
  static String get firebaseAndroidApplicationId =>
      PassengerAppEnvironment.firebaseAndroidApplicationId;

  /// Origen HTTPS del backend (sin path de API).
  static String get backendBaseUrl => PassengerAppEnvironment.backendBaseUrl;

  /// REST de autenticación pasajero bajo `/api/v2`.
  static String get baseUrlAuth => '$backendBaseUrl/api/v2';

  /// REST de viajes: rutas en raíz `/passengers/...`.
  static String get baseUrlTripsRest => backendBaseUrl;

  /// Socket.IO (mismo origen; el path lo fija el cliente).
  static String get baseUrlSocket => backendBaseUrl;

  /// `POST` cuerpo: `country_code`, `phone_number` (sin `password`) o `user_name` E.164.
  static const String loginPath = '/auth/login';

  /// `POST` tras código de verificación — ventana para [authUsersPath].
  static const String authVerifyCodePath = '/auth/verify-code';

  /// `GET` polling estado challenge WA inbound (`phone_e164`, `challenge_id`).
  static const String authChallengeStatusPath = '/auth/challenge-status';

  /// Fase 2 — emisión código email step-up anti-abuso.
  static const String authStepUpEmailChallengePath = '/auth/step-up/email-challenge';

  /// Fase 2 — completar step-up (email + captcha).
  static const String authStepUpCompletePath = '/auth/step-up/complete';

  /// `POST` completar nombre + foto opcional; devuelve `token` + `refresh_token` + `expires_in`.
  static const String authUsersPath = '/auth/users';

  /// `GET` perfil pasajero (Bearer access); datos básicos + URL de foto si existe.
  static const String authMePath = '/auth/me';

  /// `POST` cuerpo plano de respuesta: `{ token, refresh_token, expires_in }`.
  static const String refreshPath = '/auth/refresh';

  /// Soporte pasajero (ticketing básico).
  static const String supportTicketsPath = '/support/tickets';
  static const String supportMyTicketsPath = '/support/tickets/me';
  static String supportTicketDetailPath(String ticketId) => '/support/tickets/$ticketId';
  static String supportTicketAttachmentPresignPath(String ticketId) => '/support/tickets/$ticketId/attachments/presign';
  static String supportTicketAttachmentRegisterPath(String ticketId) => '/support/tickets/$ticketId/attachments';

  /// `POST` Google Sign-In pasajero — body `{ id_token }`.
  static const String authGooglePath = '/auth/google';

  /// URL completa de login.
  static String get loginUrl => '$baseUrlAuth$loginPath';

  /// Key de Google Maps consumida por servicios HTTP (Directions/Geocoding).
  /// Configurar con:
  /// `--dart-define=GOOGLE_MAPS_API_KEY=...`
  static String get googleMapsApiKey {
    const key = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
    if (key.isEmpty) {
      throw StateError(
        'Falta GOOGLE_MAPS_API_KEY. Define --dart-define=GOOGLE_MAPS_API_KEY=...'
      );
    }
    return key;
  }

  /// Fuerza visibilidad de rutas labs (p. ej. CI); no sustituye auth.
  static bool get passengerInternalToolsVisible =>
      PassengerAppEnvironment.showsInternalToolsByDefault;

  /// Web client ID de OAuth (Firebase/Google Cloud) para `google_sign_in` + backend.
  /// `--dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=...`
  static String? get googleOAuthServerClientId {
    const raw = String.fromEnvironment('GOOGLE_OAUTH_SERVER_CLIENT_ID', defaultValue: '');
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool get googleAuthEnabled => googleOAuthServerClientId != null;
}
