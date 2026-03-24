/// Configuración centralizada de la app.
/// Cambiar aquí: URLs, nombre de la app, keys. El resto del código usa estos valores.
class AppConfig {
  AppConfig._();

  static const String appName = 'Texi';
  static const String packageName = 'com.taxitexi.texi.passenger';

  /// Base URL del API de autenticación (login).
  /// Ej.: https://tu-dominio.com/api/v1
  static const String baseUrlAuth =
      'http://ec2-3-151-19-233.us-east-2.compute.amazonaws.com/api/v1';

  /// Base URL del backend `app_texi_WebSocket` para REST de pasajeros.
  ///
  /// En código del backend las rutas cuelgan de **raíz**: `/passengers/...`
  /// (sin `/api/v1`). Ej.: `GET /passengers/nearby-drivers`, `POST /passengers/trips/quote`.
  /// Si un proxy añade `/api/v1` por delante, Infra debe indicarlo; la app no lo asume.
  static const String baseUrlTripsRest = 'https://bk-websockets-pre-prod.taxitexi.com';

  /// Fallback opcional (p. ej. otro host o gateway con prefijo distinto).
  /// Solo aplica si ese host expone las mismas rutas `/passengers/...` o equivalentes.
  static const String baseUrlTripsRestFallback = baseUrlAuth;

  /// Base URL del backend de Socket.IO (tiempo real).
  ///
  /// OJO: esto NO incluye "/socket.io/"; el path se define en el cliente de socket.
  static const String baseUrlSocket = 'https://bk-websockets-pre-prod.taxitexi.com';

  /// Path del endpoint de login (se concatena a [baseUrlAuth]).
  static const String loginPath = '/auth/login';

  /// Path para refrescar el token (backend debe devolver refresh_token en login y exponer POST /auth/refresh).
  static const String refreshPath = '/auth/refresh';

  /// URL completa de login.
  static String get loginUrl => '$baseUrlAuth$loginPath';

  /// Key de Google Maps. Reemplazar por tu key o usar variable de entorno.
  /// Ver CONFIG.md en la raíz del proyecto para dónde colocarla en Android/iOS.
  static const String googleMapsApiKey = 'AIzaSyCiPWUT7LoCjEFruA6ebXaBBRwgptjQ4lQ';
}
