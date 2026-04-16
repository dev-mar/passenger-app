import 'package:flutter/material.dart';

/// Duraciones y curvas unificadas con la app del conductor (sheets, entrada).
abstract final class AppMotion {
  AppMotion._();

  static const Duration sheetEntrance = Duration(milliseconds: 600);

  static const double slideDySubtle = 0.045;

  static const Curve standard = Curves.easeOutCubic;
}
