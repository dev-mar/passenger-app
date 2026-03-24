import 'package:flutter/material.dart';

/// Paleta centralizada. Cambiar solo aquí para que toda la app use los nuevos colores.
class AppColors {
  AppColors._();

  // --- Colores definidos (editar solo estos 4 para mantener coherencia) ---
  static const Color primary = Color(0xFFFFD600);   // Amarillo Texi
  static const Color secondary = Color(0xFFFFFFFF); // Blanco
  static const Color background = Color(0xFF000000); // Fondo oscuro
  static const Color surface = Color(0xFF333026);   // Cards, sheets

  // --- Derivados (se ajustan solos; opcional editarlos) ---
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color border = Color(0xFF454545);
  static const Color onPrimary = Color(0xFF000000); // Texto sobre botón amarillo
}
