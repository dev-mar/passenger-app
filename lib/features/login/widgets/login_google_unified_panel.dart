import 'package:flutter/material.dart';

import '../../../core/config/passenger_app_environment.dart';
import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../core/widgets/premium_state_view.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'login_auth_info_button.dart';
import 'login_google_brand_icon.dart';
import 'passenger_auth_shell.dart';
import 'passenger_turnstile_widget.dart';

class LoginGoogleUnifiedPanel extends StatelessWidget {
  const LoginGoogleUnifiedPanel({
    super.key,
    required this.emailController,
    required this.turnstileKey,
    required this.captchaReady,
    required this.onCaptchaToken,
    required this.onContinueManualEmail,
    required this.onSignInWithGoogle,
    required this.isLoading,
    required this.googleAuthEnabled,
    this.errorMessage,
  });

  final TextEditingController emailController;
  final GlobalKey<PassengerTurnstileWidgetState> turnstileKey;
  final bool captchaReady;
  final ValueChanged<String> onCaptchaToken;
  final VoidCallback onContinueManualEmail;
  final VoidCallback onSignInWithGoogle;
  final bool isLoading;
  final bool googleAuthEnabled;
  final String? errorMessage;

  bool get _captchaConfigured =>
      PassengerAppEnvironment.turnstileSiteKey.trim().isNotEmpty;

  bool get _emailValid {
    final email = emailController.text.trim();
    return email.contains('@') && email.length > 5;
  }

  bool get _captchaOk =>
      captchaReady || !PassengerAppEnvironment.turnstileSiteKey.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canContinueManual =
        _emailValid && _captchaOk && !isLoading;
    final canGoogleSignIn = googleAuthEnabled && _captchaOk && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.loginGoogleUnifiedTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 22),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            color: const Color(0xFF1A1814),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: passengerAuthFieldDecoration(
                      label: l10n.loginGoogleEmailHint,
                      hint: l10n.loginGoogleEmailHint,
                    ).copyWith(
                      labelText: null,
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                LoginAuthInfoButton(
                  message: l10n.loginGoogleEmailInfo,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.loginCaptchaTitle,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (_captchaConfigured)
          PassengerTurnstileWidget(
            key: turnstileKey,
            captchaContext: PassengerCaptchaContext.loginEntry,
            expanded: true,
            onToken: onCaptchaToken,
          )
        else if (PassengerAppEnvironment.isDev)
          SizedBox(
            height: 96,
            child: Center(
              child: TextButton(
                onPressed: () => onCaptchaToken('dev-bypass-captcha'),
                child: const Text('Dev: captcha'),
              ),
            ),
          ),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: TexiScalePress(
            child: FilledButton(
              onPressed: canContinueManual
                  ? () {
                      TexiUiFeedback.softImpact();
                      onContinueManualEmail();
                    }
                  : null,
              style: FilledButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
              ),
              child: Text(
                l10n.loginGoogleContinue,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
            ),
          ),
        ),
        if (googleAuthEnabled) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.14),
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.loginGoogleOrDivider,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.14),
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: TexiScalePress(
              child: OutlinedButton(
                onPressed: canGoogleSignIn
                    ? () {
                        TexiUiFeedback.softImpact();
                        onSignInWithGoogle();
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LoginGoogleBrandIcon(size: 20),
                    const SizedBox(width: 12),
                    Text(
                      l10n.loginGoogleSignInButton,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          PremiumStateView(
            icon: Icons.info_outline_rounded,
            title: l10n.loginReviewDataTitle,
            message: errorMessage!,
          ),
        ],
      ],
    );
  }
}
