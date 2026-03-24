import 'package:flutter/material.dart';

/// Tokens de movimiento para mantener una UX coherente en toda la app pasajero.
abstract final class TexiMotion {
  TexiMotion._();

  /// Micro-interacciones (botones, chips).
  static const Duration fast = Duration(milliseconds: 120);

  /// Transiciones de panel / sheet.
  static const Duration medium = Duration(milliseconds: 240);

  /// Entradas destacadas (SnackBars, banners).
  static const Duration emphasized = Duration(milliseconds: 420);

  /// Pulso sutil en iconos de estado.
  static const Duration pulseLoop = Duration(milliseconds: 1600);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.elasticOut;
  static const Curve pulseCurve = Curves.easeInOut;
}
