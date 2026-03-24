import 'package:flutter/material.dart';

/// Tokens de layout, forma, tipografía y elevación para evitar números mágicos duplicados.
/// Preferir estos valores en UI nueva; alinear gradualmente pantallas existentes.
class AppRadii {
  AppRadii._();

  /// Puntos de conexión entre paradas (p. ej. 6px con radio 3).
  static const double micro = 3;
  static const double xs = 2;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double snackBar = 18;
  static const double dialog = 24;
  /// Esquinas superiores de bottom sheets modales (alineado con [AppTheme]).
  static const double sheetTop = 28;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();

  /// Separación mínima entre líneas de texto (p. ej. label / valor).
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 14;
  static const double xxx = 16;
  static const double xxxx = 18;
  static const double sheetH = 20;
  static const double sheetV = 24;
  static const double section = 28;
  /// Offset vertical del panel de cotización respecto al botón cerrar.
  static const double quoteSheetTopMargin = 26;
  /// Padding vertical generoso en tarjetas flotantes / overlays.
  static const double sheetBodyV = 32;
}

class AppSizes {
  AppSizes._();

  static const double buttonHeight = 48;
  static const double circleButton = 48;
  static const double iconButtonMin = 40;
  static const double closeOrb = 50;
  /// Indicador "asa" de arrastre (ancho estándar).
  static const double dragHandleW = 36;
  static const double dragHandleQuoteW = 48;
  static const double dragHandleH = 4;
  static const double dragHandleQuoteH = 5;
  static const double stopRowBubble = 36;
  static const double tileLeading = 44;
  static const double avatarTripStatus = 52;
  static const double progressSm = 16;
  static const double progressBtn = 22;
  static const double searchingRadarArea = 110;
  static const double searchingInnerCircle = 56;
  static const double searchingBase = 80;
  static const double stopConnectorDot = 6;
  static const double connectorLineHeight = 12;
  /// Altura máxima del panel de cotización como fracción de la pantalla.
  static const double quoteSheetMaxHeightFactor = 0.7;
}

class AppIconSizes {
  AppIconSizes._();

  static const double sm = 16;
  static const double md = 18;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 26;
  static const double hero = 30;
  static const double sheet = 48;
  /// Icono principal en tarjetas de estado ([PremiumStateView]).
  static const double stateHero = 46;
}

class AppTypography {
  AppTypography._();

  static const double caption = 11;
  static const double captionAlt = 12;
  static const double bodySmall = 13;
  static const double body = 14;
  static const double bodyLarge = 15;
  static const double title = 16;
  static const double headlineSm = 21;
}

class AppBorders {
  AppBorders._();

  static const double thin = 1;
  static const double emphasis = 1.5;
  static const double strong = 2;
  static const double radarRing = 2.5;
}

class AppElevation {
  AppElevation._();

  static const double closeOrb = 16;
}

class AppDurations {
  AppDurations._();

  static const Duration searchingPulse = Duration(milliseconds: 2000);
}

/// Sombras reutilizables (opacidad fija para poder usar `const`).
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sheetLiftStrong = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 26,
      offset: Offset(0, -10),
    ),
  ];

  static const List<BoxShadow> overlayFloating = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> overlayRaised = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];
}
