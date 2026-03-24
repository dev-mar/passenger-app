import 'package:flutter/services.dart';

/// Feedback háptico + audio suave reutilizable (SnackBars, éxitos discretos).
///
/// El sonido usa [SystemSound] (sin plugins nativos extra), compatible con Windows
/// (proyecto en distinta unidad que el pub cache) y evita fallos del compilador Kotlin.
final class TexiUiFeedback {
  TexiUiFeedback._();

  static final TexiUiFeedback instance = TexiUiFeedback._();

  /// Pulso háptico ligero (botones primarios).
  static void lightTap() {
    HapticFeedback.selectionClick();
  }

  /// Impacto suave (confirmaciones).
  static void softImpact() {
    HapticFeedback.lightImpact();
  }

  /// Sonido de confirmación muy discreto (depende del SO).
  Future<void> playSoftChime() async {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  Future<void> dispose() async {}
}
