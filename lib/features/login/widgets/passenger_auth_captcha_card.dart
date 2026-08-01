import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import 'passenger_auth_shell.dart';
import 'passenger_turnstile_widget.dart';

/// Marco visual unificado para Turnstile en login y step-up.
class PassengerAuthCaptchaCard extends StatelessWidget {
  const PassengerAuthCaptchaCard({
    super.key,
    required this.turnstileKey,
    required this.onToken,
    this.onError,
    this.captchaContext = PassengerCaptchaContext.loginEntry,
    this.highlightWhenReady = true,
  });

  final GlobalKey<PassengerTurnstileWidgetState> turnstileKey;
  final ValueChanged<String> onToken;
  final VoidCallback? onError;
  final PassengerCaptchaContext captchaContext;
  final bool highlightWhenReady;

  @override
  Widget build(BuildContext context) {
    return PassengerAuthGlassCard(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: highlightWhenReady
                ? AppColors.primary.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.08),
            width: 1.2,
          ),
          color: AppColors.background.withValues(alpha: 0.42),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: PassengerTurnstileWidget(
            key: turnstileKey,
            captchaContext: captchaContext,
            onToken: onToken,
            onError: onError,
          ),
        ),
      ),
    );
  }
}
