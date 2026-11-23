import 'dart:async';

import 'package:flutter/material.dart';

import '../feedback/texi_ui_feedback.dart';
import '../theme/app_colors.dart';
import '../theme/app_ui_tokens.dart';
import 'texi_motion.dart';

abstract final class PassengerSuccessToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_rounded,
    Color accent = AppColors.success,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    hide();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    TexiUiFeedback.softImpact();
    unawaited(TexiUiFeedback.instance.playSoftChime());

    final entry = OverlayEntry(
      builder: (ctx) {
        return _PassengerSlideToast(
          message: message,
          icon: icon,
          accent: accent,
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _PassengerSlideToast extends StatefulWidget {
  const _PassengerSlideToast({
    required this.message,
    required this.icon,
    required this.accent,
  });

  final String message;
  final IconData icon;
  final Color accent;

  @override
  State<_PassengerSlideToast> createState() => _PassengerSlideToastState();
}

class _PassengerSlideToastState extends State<_PassengerSlideToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: TexiMotion.emphasized,
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: TexiMotion.standard));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: const Alignment(0, -0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xF21A1A1A),
                        borderRadius: BorderRadius.circular(AppRadii.lg + 4),
                        border: Border.all(
                          color: widget.accent.withValues(alpha: 0.42),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.38),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
