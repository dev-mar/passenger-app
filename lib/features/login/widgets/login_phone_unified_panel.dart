import 'package:flutter/material.dart';

import '../../../core/config/passenger_app_environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/phone/bolivia_local_phone.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../utils/login_country_flag.dart';
import 'login_auth_action_row.dart';
import 'login_phone_verification_method_panel.dart';
import 'login_whatsapp_brand_icon.dart';
import 'passenger_auth_look.dart';
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
    required this.onCaptchaToken,
    required this.onMethodSelected,
    required this.isLoading,
    this.outboundEnabled = true,
    this.classicPhoneOtp = false,
    this.linkedGoogleEmail,
  });

  final LoginCountryDial country;
  final TextEditingController phoneController;
  final GlobalKey<PassengerTurnstileWidgetState> turnstileKey;
  final bool phoneValid;
  final bool showCaptcha;
  final bool captchaReady;
  final ValueChanged<String> onCaptchaToken;
  final PhoneVerificationMethodSelected onMethodSelected;
  final bool isLoading;
  final bool outboundEnabled;
  /// Flavor/dev: un CTA a OTP `code`. Default false = UI prod (WA inbound/outbound).
  final bool classicPhoneOtp;
  final String? linkedGoogleEmail;

  bool get _captchaConfigured =>
      PassengerAppEnvironment.turnstileSiteKey.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final flag = loginCountryFlagEmoji(country.isoCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PassengerAuthHeadline(
          title: l10n.loginPhoneUnifiedTitle,
          subtitle: linkedGoogleEmail != null && linkedGoogleEmail!.isNotEmpty
              ? l10n.loginPhoneStepSubtitleGoogle(linkedGoogleEmail!)
              : null,
        ),
        const SizedBox(height: 20),
        PassengerAuthFieldPanel(
          child: SizedBox(
            height: PassengerAuthLook.fieldHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PassengerAuthDialChip(
                  flagEmoji: flag,
                  dialCode: country.dialCode,
                  countryLabel: country.label,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: phoneController,
                    enabled: !isLoading,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: passengerAuthInlineFieldDecoration(
                      hint: l10n.loginPhoneHint,
                    ),
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters:
                        passengerLocalPhoneFormatters(country.dialCode),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
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
                      style: PassengerAuthLook.sectionLabelStyle,
                    ),
                    const SizedBox(height: 8),
                    if (_captchaConfigured)
                      PassengerTurnstileWidget(
                        key: turnstileKey,
                        captchaContext: PassengerCaptchaContext.loginEntry,
                        expanded: true,
                        onToken: onCaptchaToken,
                      )
                    else
                      _DevCaptchaBypass(
                        onBypass: () => onCaptchaToken('dev-bypass-captcha'),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
        if (classicPhoneOtp)
          PassengerAuthPrimaryButton(
            label: l10n.loginContinue,
            onPressed: (!isLoading && (!phoneValid || captchaReady))
                ? () => onMethodSelected(
                      PhoneVerificationMethod.verificationCode,
                    )
                : null,
          )
        else ...[
          Text(
            l10n.loginVerifySectionLabel,
            style: PassengerAuthLook.sectionLabelStyle,
          ),
          const SizedBox(height: 10),
          LoginAuthActionRow(
            enabled: !isLoading && (!phoneValid || captchaReady),
            highlighted: true,
            accent: LoginWhatsAppBrandIcon.brandGreen,
            icon: const LoginWhatsAppBrandIcon(size: 26),
            label: l10n.loginVerifyMethodWaInboundShort,
            infoMessage: l10n.loginVerifyMethodWaInboundInfo,
            onTap: () => onMethodSelected(
              PhoneVerificationMethod.whatsAppInbound,
            ),
          ),
          if (outboundEnabled) ...[
            const SizedBox(height: 8),
            LoginAuthActionRow(
              enabled: !isLoading && (!phoneValid || captchaReady),
              highlighted: false,
              icon: Icon(
                Icons.pin_outlined,
                color: AppColors.textPrimary.withValues(alpha: 0.88),
                size: 22,
              ),
              label: l10n.loginVerifyMethodCodeShort,
              infoMessage: l10n.loginVerifyMethodCodeInfo,
              onTap: () => onMethodSelected(
                PhoneVerificationMethod.verificationCode,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _DevCaptchaBypass extends StatelessWidget {
  const _DevCaptchaBypass({required this.onBypass});

  final VoidCallback onBypass;

  @override
  Widget build(BuildContext context) {
    if (!PassengerAppEnvironment.isDev) {
      final l10n = AppLocalizations.of(context)!;
      return SizedBox(
        height: 72,
        child: Center(
          child: Text(
            l10n.loginCaptchaDevPlaceholder,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PassengerAuthLook.muted),
          ),
        ),
      );
    }
    return SizedBox(
      height: 56,
      child: Center(
        child: TextButton(onPressed: onBypass, child: const Text('Dev: captcha')),
      ),
    );
  }
}
