import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../core/widgets/premium_state_view.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../utils/login_country_flag.dart';
import 'passenger_auth_shell.dart';

class LoginPhoneEntryPanel extends StatelessWidget {
  const LoginPhoneEntryPanel({
    super.key,
    required this.country,
    required this.phoneController,
    required this.errorMessage,
    required this.isLoading,
    required this.onSubmit,
    this.linkedGoogleEmail,
  });

  final LoginCountryDial country;
  final TextEditingController phoneController;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onSubmit;
  final String? linkedGoogleEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final flag = loginCountryFlagEmoji(country.isoCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.loginPhoneStepTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          linkedGoogleEmail != null && linkedGoogleEmail!.isNotEmpty
              ? l10n.loginPhoneStepSubtitleGoogle(linkedGoogleEmail!)
              : l10n.loginPhoneStepSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.92),
                height: 1.4,
                fontSize: 13.5,
              ),
        ),
        const SizedBox(height: 24),
        PassengerAuthGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.loginPhone,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
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
                      decoration: passengerAuthFieldDecoration(
                        label: l10n.loginPhone,
                        hint: l10n.loginPhoneHint,
                      ).copyWith(
                        labelText: null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onFieldSubmitted: (_) => onSubmit(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: AppSpacing.xxx),
                PremiumStateView(
                  icon: Icons.info_outline_rounded,
                  title: l10n.loginReviewDataTitle,
                  message: errorMessage!,
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: TexiScalePress(
                  child: FilledButton(
                    onPressed: isLoading ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                    ),
                    child: Semantics(
                      button: true,
                      label: l10n.loginContinueA11y,
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
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flagEmoji.isNotEmpty) ...[
              Text(
                flagEmoji,
                style: const TextStyle(fontSize: 20, height: 1),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              dialCode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
