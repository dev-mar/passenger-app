import 'package:flutter/material.dart';

abstract final class AppMotion {
  AppMotion._();

  static const Duration sheetEntrance = Duration(milliseconds: 600);

  static const Duration screenEntrance = Duration(milliseconds: 700);

  static const Duration draftSearchChromeReveal = Duration(milliseconds: 280);

  static const double slideDySubtle = 0.045;

  static const Curve standard = Curves.easeOutCubic;
}
