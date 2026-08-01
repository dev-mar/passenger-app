import 'package:flutter/material.dart';

/// Duraciones y curvas unificadas con la app del conductor (sheets, entrada).
abstract final class AppMotion {
  AppMotion._();

  static const Duration sheetEntrance = Duration(milliseconds: 600);

  /// Entrada suave de pantallas de auth (login / OTP / perfil).
  static const Duration screenEntrance = Duration(milliseconds: 700);

  /// Colapso / expansión del buscador borrador (cabecera viaje).
  static const Duration draftSearchChromeReveal = Duration(milliseconds: 280);

  static const double slideDySubtle = 0.045;

  static const Curve standard = Curves.easeOutCubic;
}
