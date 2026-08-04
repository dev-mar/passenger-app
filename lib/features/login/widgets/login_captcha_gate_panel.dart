import 'package:flutter/material.dart';

import '../../../core/config/passenger_app_environment.dart';
import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'passenger_turnstile_widget.dart';

class LoginCaptchaGatePanel extends StatelessWidget {
  const LoginCaptchaGatePanel({
    super.key,
    required this.turnstileKey,
    required this.captchaReady,
    required this.onCaptchaToken,
    required this.onContinue,
    required this.isLoading,
    this.forGoogle = false,
    this.onCaptchaError,
  });

  final GlobalKey<PassengerTurnstileWidgetState> turnstileKey;
  final bool captchaReady;
  final ValueChanged<String> onCaptchaToken;
  final VoidCallback onContinue;
  final bool isLoading;
  final bool forGoogle;
  final VoidCallback? onCaptchaError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final captchaConfigured =
        PassengerAppEnvironment.turnstileSiteKey.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          forGoogle ? l10n.loginGoogleCaptchaTitle : l10n.loginCaptchaTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            height: 1.15,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          forGoogle
              ? l10n.loginGoogleCaptchaSubtitle
              : l10n.loginCaptchaSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.92),
            height: 1.5,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 28),
        if (captchaConfigured)
          PassengerTurnstileWidget(
            key: turnstileKey,
            captchaContext: PassengerCaptchaContext.loginEntry,
            expanded: true,
            onToken: onCaptchaToken,
            onError: onCaptchaError,
          )
        else
          _DevCaptchaPlaceholder(
            message: l10n.loginCaptchaDevPlaceholder,
            onBypass: () => onCaptchaToken('dev-bypass-captcha'),
          ),
        const SizedBox(height: 26),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: TexiScalePress(
            child: FilledButton(
              onPressed: (isLoading || (!captchaReady && captchaConfigured))
                  ? null
                  : () {
                      TexiUiFeedback.softImpact();
                      onContinue();
                    },
              style: FilledButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
              ),
              child: Text(
                l10n.loginContinue,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DevCaptchaPlaceholder extends StatelessWidget {
  const _DevCaptchaPlaceholder({
    required this.message,
    required this.onBypass,
  });

  final String message;
  final VoidCallback onBypass;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        color: const Color(0xFF1A1814),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppColors.primary.withValues(alpha: 0.85),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (PassengerAppEnvironment.isDev) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onBypass, child: const Text('Dev: continuar')),
          ],
        ],
      ),
    );
  }
}
