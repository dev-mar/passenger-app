import 'package:flutter/material.dart';

abstract final class TexiMotion {
  TexiMotion._();

  static const Duration fast = Duration(milliseconds: 120);

  static const Duration medium = Duration(milliseconds: 240);

  static const Duration emphasized = Duration(milliseconds: 420);

  static const Duration pulseLoop = Duration(milliseconds: 1600);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.elasticOut;
  static const Curve pulseCurve = Curves.easeInOut;
}
