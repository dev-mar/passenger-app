import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/passenger_app_environment.dart';
import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/input/passenger_text_limits.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../passenger_device_email.dart';
import 'login_auth_info_button.dart';
import 'login_google_brand_icon.dart';
import 'passenger_auth_look.dart';
import 'passenger_auth_shell.dart';
import 'passenger_turnstile_widget.dart';

class LoginGoogleUnifiedPanel extends StatefulWidget {
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
  });

  final TextEditingController emailController;
  final GlobalKey<PassengerTurnstileWidgetState> turnstileKey;
  final bool captchaReady;
  final ValueChanged<String> onCaptchaToken;
  final VoidCallback onContinueManualEmail;
  final VoidCallback onSignInWithGoogle;
  final bool isLoading;
  final bool googleAuthEnabled;

  @override
  State<LoginGoogleUnifiedPanel> createState() => _LoginGoogleUnifiedPanelState();
}

class _LoginGoogleUnifiedPanelState extends State<LoginGoogleUnifiedPanel> {
  final _emailFocus = FocusNode();
  bool _pickingEmail = false;

  bool get _captchaConfigured =>
      PassengerAppEnvironment.turnstileSiteKey.trim().isNotEmpty;

  bool get _emailValid {
    final email = widget.emailController.text.trim();
    return email.contains('@') && email.length > 5;
  }

  bool get _captchaOk =>
      widget.captchaReady ||
      !PassengerAppEnvironment.turnstileSiteKey.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    widget.emailController.removeListener(_onEmailChanged);
    _emailFocus.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickFromDevice() async {
    if (_pickingEmail || widget.isLoading) return;
    setState(() => _pickingEmail = true);
    try {
      final picked = await pickPassengerDeviceEmail();
      if (!mounted) return;
      if (picked != null) {
        final email = clampPassengerText(picked, kPassengerEmailMaxLength);
        widget.emailController.text = email;
        widget.emailController.selection =
            TextSelection.collapsed(offset: email.length);
        return;
      }
      _emailFocus.requestFocus();
    } finally {
      if (mounted) setState(() => _pickingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canContinueManual = _emailValid && _captchaOk && !widget.isLoading;
    final canGoogleSignIn =
        widget.googleAuthEnabled && _captchaOk && !widget.isLoading;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PassengerAuthHeadline(title: l10n.loginGoogleUnifiedTitle),
          const SizedBox(height: 20),
          PassengerAuthFieldPanel(
            padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
            child: SizedBox(
              height: PassengerAuthLook.fieldHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: widget.emailController,
                      focusNode: _emailFocus,
                      enabled: !widget.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      enableSuggestions: true,
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: passengerEmailInputFormatters(),
                      maxLength: kPassengerEmailMaxLength,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: passengerAuthInlineFieldDecoration(
                        hint: l10n.loginGoogleEmailHint,
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.loginEmailPickFromDevice,
                    onPressed: (widget.isLoading || _pickingEmail)
                        ? null
                        : () => unawaited(_pickFromDevice()),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(40, 40),
                    ),
                    icon: _pickingEmail
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_drop_down_rounded, size: 26),
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
            style: PassengerAuthLook.sectionLabelStyle,
          ),
          const SizedBox(height: 8),
          if (_captchaConfigured)
            PassengerTurnstileWidget(
              key: widget.turnstileKey,
              captchaContext: PassengerCaptchaContext.loginEntry,
              expanded: true,
              onToken: widget.onCaptchaToken,
            )
          else if (PassengerAppEnvironment.isDev)
            SizedBox(
              height: 56,
              child: Center(
                child: TextButton(
                  onPressed: () => widget.onCaptchaToken('dev-bypass-captcha'),
                  child: const Text('Dev: captcha'),
                ),
              ),
            ),
          const SizedBox(height: 20),
          PassengerAuthPrimaryButton(
            label: l10n.loginGoogleContinue,
            onPressed: canContinueManual
                ? () {
                    TexiUiFeedback.softImpact();
                    widget.onContinueManualEmail();
                  }
                : null,
          ),
          if (widget.googleAuthEnabled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: PassengerAuthLook.hairlineStrong,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.loginGoogleOrDivider,
                    style: PassengerAuthLook.sectionLabelStyle,
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: PassengerAuthLook.hairlineStrong,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: PassengerAuthLook.actionHeight,
              width: double.infinity,
              child: TexiScalePress(
                child: OutlinedButton(
                  onPressed: canGoogleSignIn
                      ? () {
                          TexiUiFeedback.softImpact();
                          widget.onSignInWithGoogle();
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: PassengerAuthLook.hairlineStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LoginGoogleBrandIcon(size: 20),
                      const SizedBox(width: 10),
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
        ],
      ),
    );
  }
}
