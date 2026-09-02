import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/phone/bolivia_local_phone.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../utils/login_country_flag.dart';
import 'passenger_auth_look.dart';
import 'passenger_auth_shell.dart';

class LoginPhoneEntryPanel extends StatelessWidget {
  const LoginPhoneEntryPanel({
    super.key,
    required this.country,
    required this.phoneController,
    required this.isLoading,
    this.linkedGoogleEmail,
    this.showHeadline = true,
  });

  final LoginCountryDial country;
  final TextEditingController phoneController;
  final bool isLoading;
  final String? linkedGoogleEmail;
  final bool showHeadline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final flag = loginCountryFlagEmoji(country.isoCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeadline) ...[
          PassengerAuthHeadline(
            title: l10n.loginPhoneStepTitle,
            subtitle: linkedGoogleEmail != null && linkedGoogleEmail!.isNotEmpty
                ? l10n.loginPhoneStepSubtitleGoogle(linkedGoogleEmail!)
                : l10n.loginPhoneStepSubtitle,
          ),
          const SizedBox(height: 20),
        ],
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
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
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
      ],
    );
  }
}
