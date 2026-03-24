/// Rutas de assets. Cambiar solo aquí si renombras o mueves archivos.
///
/// Assets requeridos en `assets/images/`:
/// - [loginBackground]: background4.jpg (fondo de pantalla de login).
/// - [appIcon]: X_amarillo_blanco@2x.png (icono de la app; generar con `dart run flutter_launcher_icons`).
///
/// Uso:
/// - [logo] / [splashLogo]: Splash y AppBar (fondo oscuro → amarillo o blanco).
/// - [logoDark]: Fondos claros (por si en el futuro hay pantallas en claro).
/// - [appIcon]: Icono de la app (launcher).
/// - [logoSvg]: Si existe, se usa en Splash/logo para mejor nitidez; si no, se usa [logo] PNG.
class AppAssets {
  AppAssets._();

  // --- Logo principal (splash, app bar). Fondo oscuro → usar amarillo o blanco.
  /// Logo para fondo oscuro (amarillo). Usado en Splash y donde haga falta.
  static const String logo = 'assets/images/TEXI_ama@2x.png';
  static const String splashLogo = 'assets/images/TEXI_ama@2x.png';

  /// Logo en SVG (mejor calidad a cualquier tamaño). Renombra "Mesa de trabajo 1.svg" → logo.svg.
  static const String logoSvg = 'assets/images/logo.svg';

  // --- Variantes de logo (usar según fondo: claro/oscuro).
  static const String logoAmaNegro = 'assets/images/TEXI_ama_negro@2x.png';
  /// Logo blanco para fondos oscuros (login, etc.). Acepta TEXI_ama_blanco2x.png o TEXI_ama_blanco@2x.png.
  static const String logoAmaBlanco = 'assets/images/TEXI_ama_blanco2x.png';
  static const String logoPositivo = 'assets/images/TEXI_positivo@2x.png';
  static const String logoNegativo = 'assets/images/pTEXI_negativo@2x.png';
  static const String logoNegroBlanco = 'assets/images/TEXI_negro_blanco@2x.png';

  /// Para fondos claros (por si se usa en alguna pantalla).
  static const String logoDark = 'assets/images/TEXI_negro_blanco@2x.png';

  // --- Icono de la app (launcher). Usar X_amarillo_blanco@2x.png.
  static const String appIcon = 'assets/images/X_amarillo_blanco@2x.png';

  /// Fondo de pantalla de login (geométrico oscuro).
  static const String loginBackground = 'assets/images/backgrount_texi1.jpg';

  // --- Pines del mapa (origen y destino).
  static const String pinOrigen = 'assets/images/pinOrigen.png';
  static const String pinDestino = 'assets/images/pinDestino.png';
  static const String pinOrigenSvg = 'assets/images/pinOrigen.svg';
  static const String pinDestinoSvg = 'assets/images/pinDestino.svg';
}
