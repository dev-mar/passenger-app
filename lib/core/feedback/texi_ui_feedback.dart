import 'package:flutter/services.dart';

final class TexiUiFeedback {
  TexiUiFeedback._();

  static final TexiUiFeedback instance = TexiUiFeedback._();

  static void lightTap() {
    HapticFeedback.selectionClick();
  }

  static void softImpact() {
    HapticFeedback.lightImpact();
  }

  Future<void> playSoftChime() async {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  Future<void> dispose() async {}
}
