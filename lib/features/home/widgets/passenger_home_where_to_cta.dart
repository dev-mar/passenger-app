import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_motion.dart';
import '../../../core/ui/texi_scale_press.dart';
import 'passenger_home_look.dart';

/// Pregunta + CTA premium con resplandor que pulsa suavemente.
class PassengerHomeWhereToCta extends StatefulWidget {
  const PassengerHomeWhereToCta({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onPressed,
    this.greeting,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  /// Saludo con el primer nombre. Si no hay nombre, no se muestra.
  final String? greeting;

  @override
  State<PassengerHomeWhereToCta> createState() =>
      _PassengerHomeWhereToCtaState();
}

class _PassengerHomeWhereToCtaState extends State<PassengerHomeWhereToCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: TexiMotion.pulseLoop)
      ..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _pulse, curve: TexiMotion.pulseCurve);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.greeting != null && widget.greeting!.trim().isNotEmpty) ...[
          Text(
            widget.greeting!.trim(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: PassengerHomeLook.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: widget.greeting == null
                ? PassengerHomeLook.ink
                : PassengerHomeLook.muted,
            fontWeight: widget.greeting == null
                ? FontWeight.w800
                : FontWeight.w600,
            letterSpacing: -0.2,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxx),
        AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            final t = _glow.value;
            final glow = Color.lerp(
              AppColors.primary.withValues(alpha: 0.18),
              AppColors.primary.withValues(alpha: 0.58),
              t,
            )!;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.dialog),
                boxShadow: [
                  BoxShadow(
                    color: glow,
                    blurRadius: 10 + (t * 18),
                    spreadRadius: 0.6 + (t * 1.8),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.04 + t * 0.08),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: TexiScalePress(
            minScale: 0.98,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onPressed();
                },
                borderRadius: BorderRadius.circular(AppRadii.dialog),
                child: Ink(
                  height: AppSizes.buttonHeight + 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.dialog),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A2410), Color(0xFF16130A)],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.72),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.near_me_rounded,
                          color: AppColors.primary,
                          size: AppIconSizes.lg,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Text(
                        widget.actionLabel,
                        style: const TextStyle(
                          color: PassengerHomeLook.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
