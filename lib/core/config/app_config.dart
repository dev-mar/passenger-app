/// Configuración centralizada: un solo host `app_texi_WebSocket` (mismo que conductor).
///
/// Override: `--dart-define=TEXI_BACKEND_BASE_URL=https://bk-websockets-pre-prod.taxitexi.com`
class AppConfig {
  AppConfig._();

  static const String appName = 'Texi';
  static const String packageName = 'com.taxitexi.texi.passenger';

  /// `applicationId` Android (debe coincidir con `google-services.json` / FCM).
  static const String firebaseAndroidApplicationId =
      'com.taxitexi.texi_passenger_app';

  /// Origen HTTPS del backend (sin path de API).
  static const String backendBaseUrl = String.fromEnvironment(
    'TEXI_BACKEND_BASE_URL',
    defaultValue: 'https://bk-websockets-pre-prod.taxitexi.com',
  );

  /// REST de autenticación pasajero bajo `/api/v2`.
  static String get baseUrlAuth => '$backendBaseUrl/api/v2';

  /// REST de viajes: rutas en raíz `/passengers/...`.
  static String get baseUrlTripsRest => backendBaseUrl;

  /// Socket.IO (mismo origen; el path lo fija el cliente).
  static String get baseUrlSocket => backendBaseUrl;

  /// `POST` cuerpo: `country_code`, `phone_number` (sin `password`) o `user_name` E.164.
  static const String loginPath = '/auth/login';

  /// `POST` tras SMS OTP — ventana para [authUsersPath].
  static const String authVerifyCodePath = '/auth/verify-code';

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

  /// URL completa de login.
  static String get loginUrl => '$baseUrlAuth$loginPath';

  /// Key de Google Maps. Reemplazar por tu key o usar variable de entorno.
  /// Ver CONFIG.md en la raíz del proyecto para dónde colocarla en Android/iOS.
  static const String googleMapsApiKey = 'AIzaSyCiPWUT7LoCjEFruA6ebXaBBRwgptjQ4lQ';

  /// Fuerza visibilidad de rutas labs (p. ej. CI); no sustituye auth.
  static const bool passengerInternalToolsDartDefine = bool.fromEnvironment(
    'TEXI_PASSENGER_INTERNAL_TOOLS',
    defaultValue: false,
  );
}
