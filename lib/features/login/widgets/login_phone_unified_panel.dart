import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/passenger_app_environment.dart';
import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/widgets/premium_state_view.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../utils/login_country_flag.dart';
import 'login_auth_action_row.dart';
import 'login_phone_verification_method_panel.dart';
import 'login_whatsapp_brand_icon.dart';
import 'passenger_auth_shell.dart';
import 'passenger_turnstile_widget.dart';

class LoginPhoneUnifiedPanel extends StatelessWidget {
  const LoginPhoneUnifiedPanel({
    super.key,
    required this.country,
    required this.phoneController,
    required this.turnstileKey,
    required this.phoneValid,
    required this.showCaptcha,
    required this.captchaReady,
    required this.showVerifyActions,
    required this.onCaptchaToken,
    required this.onMethodSelected,
    required this.isLoading,
    this.outboundEnabled = true,
    this.errorMessage,
    this.linkedGoogleEmail,
  });

  final LoginCountryDial country;
  final TextEditingController phoneController;
  final GlobalKey<PassengerTurnstileWidgetState> turnstileKey;
  final bool phoneValid;
  final bool showCaptcha;
  final bool captchaReady;
  final bool showVerifyActions;
  final ValueChanged<String> onCaptchaToken;
  final PhoneVerificationMethodSelected onMethodSelected;
  final bool isLoading;
  final bool outboundEnabled;
  final String? errorMessage;
  final String? linkedGoogleEmail;

  bool get _captchaConfigured =>
      PassengerAppEnvironment.turnstileSiteKey.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final flag = loginCountryFlagEmoji(country.isoCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.loginPhoneUnifiedTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            height: 1.15,
          ),
        ),
        if (linkedGoogleEmail != null && linkedGoogleEmail!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.loginPhoneStepSubtitleGoogle(linkedGoogleEmail!),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.88),
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 22),
        _FullWidthAuthField(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CountryDialChip(
                flagEmoji: flag,
                dialCode: country.dialCode,
                countryLabel: country.label,
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: TextFormField(
                  controller: phoneController,
                  enabled: !isLoading,
                    decoration: passengerAuthFieldDecoration(
                      label: l10n.loginPhone,
                      hint: l10n.loginPhoneHint,
                    ).copyWith(
                    labelText: null,
                    hintText: l10n.loginPhoneHint,
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: showCaptcha
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    else
                      _DevCaptchaBypass(onBypass: () => onCaptchaToken('dev-bypass-captcha')),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: showVerifyActions
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 22),
                    Text(
                      l10n.loginVerifySectionLabel,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LoginAuthActionRow(
                      enabled: !isLoading && captchaReady,
                      highlighted: true,
                      accent: LoginWhatsAppBrandIcon.brandGreen,
                      icon: const LoginWhatsAppBrandIcon(size: 28),
                      label: l10n.loginVerifyMethodWaInboundShort,
                      infoMessage: l10n.loginVerifyMethodWaInboundInfo,
                      onTap: () => onMethodSelected(
                        PhoneVerificationMethod.whatsAppInbound,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LoginAuthActionRow(
                      enabled: !isLoading && captchaReady,
                      highlighted: false,
                      icon: Icon(
                        Icons.pin_outlined,
                        color: AppColors.textPrimary.withValues(alpha: 0.88),
                        size: 22,
                      ),
                      label: l10n.loginVerifyMethodCodeShort,
                      badge: outboundEnabled ? null : l10n.loginMethodGoogleBadge,
                      infoMessage: l10n.loginVerifyMethodCodeInfo,
                      onTap: outboundEnabled
                          ? () => onMethodSelected(
                                PhoneVerificationMethod.verificationCode,
                              )
                          : () {
                              TexiUiFeedback.softImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    l10n.loginVerifyMethodCodeComingSoon,
                                  ),
                                ),
                              );
                            },
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
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

class _FullWidthAuthField extends StatelessWidget {
  const _FullWidthAuthField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        color: const Color(0xFF1A1814),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: child,
      ),
    );
  }
}

class _CountryDialChip extends StatelessWidget {
  const _CountryDialChip({
    required this.flagEmoji,
    required this.dialCode,
    required this.countryLabel,
  });

  final String flagEmoji;
  final String dialCode;
  final String countryLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: countryLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flagEmoji.isNotEmpty) ...[
              Text(flagEmoji, style: const TextStyle(fontSize: 18, height: 1)),
              const SizedBox(width: 6),
            ],
            Text(
              dialCode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevCaptchaBypass extends StatelessWidget {
  const _DevCaptchaBypass({required this.onBypass});

  final VoidCallback onBypass;

  @override
  Widget build(BuildContext context) {
    if (!PassengerAppEnvironment.isDev) {
      return const SizedBox(
        height: 96,
        child: Center(
          child: Text(
            'Turnstile',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return SizedBox(
      height: 96,
      child: Center(
        child: TextButton(onPressed: onBypass, child: const Text('Dev: captcha')),
      ),
    );
  }
}
