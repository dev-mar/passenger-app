import 'package:flutter/foundation.dart';

/// Entorno compile-time pasajero (espejo conductor).
///
/// Matriz credenciales: `.cursor/functional-modules/passenger-trip-request/passenger-app-credentials-matrix.md`
enum PassengerAppEnvironmentKind {
  dev,
  prod,
}

class PassengerAppEnvironment {
  PassengerAppEnvironment._();

  static const String _appEnvRaw = String.fromEnvironment(
    'TEXI_APP_ENV',
    defaultValue: '',
  );

  static const String _backendUrlRaw = String.fromEnvironment(
    'TEXI_BACKEND_BASE_URL',
    defaultValue: '',
  );

  static const bool internalToolsDartDefine = bool.fromEnvironment(
    'TEXI_PASSENGER_INTERNAL_TOOLS',
    defaultValue: false,
  );

  static const String devBackendDefault = 'https://api.dev.taxitexi.com';

  /// API prod canónica (REST + Socket.IO). No confundir con `api-prod` (panel admin).
  static const String prodBackendCanonical =
      'https://api-prodtx.taxitexi.com';

  static PassengerAppEnvironmentKind get kind {
    final normalized = _appEnvRaw.trim().toLowerCase();
    if (normalized == 'prod' || normalized == 'production') {
      return PassengerAppEnvironmentKind.prod;
    }
    if (normalized == 'dev' || normalized == 'development') {
      return PassengerAppEnvironmentKind.dev;
    }
    return kDebugMode
        ? PassengerAppEnvironmentKind.dev
        : PassengerAppEnvironmentKind.prod;
  }

  static bool get isDev => kind == PassengerAppEnvironmentKind.dev;

  static bool get isProd => kind == PassengerAppEnvironmentKind.prod;

  static String get backendBaseUrl {
    final override = _backendUrlRaw.trim();
    if (override.isNotEmpty) {
      final resolved = _resolveProdBackendOverride(override);
      _assertValidBackendUrl(resolved);
      return resolved;
    }
    if (isDev) {
      return devBackendDefault;
    }
    throw StateError(
      'Falta TEXI_BACKEND_BASE_URL en build prod. '
      'Usa --dart-define=TEXI_BACKEND_BASE_URL=https://HOST_API_PROD',
    );
  }

  static bool get showsInternalToolsByDefault =>
      internalToolsDartDefine || isDev;

  /// Auth multicanal (WA inbound Fase 1): activo en prod; dev mantiene OTP manual.
  static bool get multichannelAuthEnabled => isProd;

  static String get firebaseAndroidApplicationId => isDev
      ? 'com.taxitexi.texi_passenger_app.dev'
      : 'com.taxitexi.texi_passenger_app';

  static void _assertValidBackendUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      throw StateError('TEXI_BACKEND_BASE_URL inválida: $url');
    }
    if (parsed.scheme != 'https' && !(isDev && parsed.scheme == 'http')) {
      throw StateError(
        'TEXI_BACKEND_BASE_URL debe usar HTTPS (HTTP solo en dev): $url',
      );
    }
    if (isProd && _looksLikeDevHost(parsed.host)) {
      throw StateError(
        'Build prod no puede apuntar a host de desarrollo: $url',
      );
    }
    if (isProd && _isInvalidProdBackendHost(parsed.host)) {
      throw StateError(
        'Host no válido para API backend en prod: $url. '
        'Usa $prodBackendCanonical',
      );
    }
  }

  /// En prod, corrige hosts legacy compilados por error al canónico `api-prodtx`.
  static String _resolveProdBackendOverride(String url) {
    final trimmed = url.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.host.isEmpty) return trimmed;
    if (isProd && _isInvalidProdBackendHost(parsed.host)) {
      return prodBackendCanonical;
    }
    return trimmed;
  }

  /// Rechaza panel admin y hosts prod con punto (convención descartada).
  static bool _isInvalidProdBackendHost(String host) {
    final h = host.toLowerCase();
    if (h == 'api-prod.taxitexi.com') return true;
    return h.startsWith('api.prod');
  }

  static bool _looksLikeDevHost(String host) {
    final h = host.toLowerCase();
    return h.contains('api.dev.') ||
        h.contains('.dev.') ||
        h.contains('localhost') ||
        h.contains('127.0.0.1') ||
        h.endsWith('.local');
  }
}
