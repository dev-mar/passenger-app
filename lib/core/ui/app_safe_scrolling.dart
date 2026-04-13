import 'package:flutter/material.dart';

/// Padding inferior que respeta la barra de navegación del sistema (Android/iOS).
/// Usar en [ListView] / scrolls con acciones al final para evitar solapes.
abstract final class AppSafeScrolling {
  static double systemNavBottom(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;

  static EdgeInsets pagePadding(
    BuildContext context, {
    double horizontal = 20,
    double top = 20,
    double bottomExtra = 24,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      bottomExtra + systemNavBottom(context),
    );
  }

  static EdgeInsets paddingBottomOnly(
    BuildContext context, {
    double extra = 16,
  }) {
    return EdgeInsets.only(bottom: extra + systemNavBottom(context));
  }
}
