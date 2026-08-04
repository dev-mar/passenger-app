import 'package:flutter/material.dart';

import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'login_auth_action_row.dart';
import 'login_whatsapp_brand_icon.dart';

enum PhoneVerificationMethod {
  whatsAppInbound,
  verificationCode,
}

typedef PhoneVerificationMethodSelected = void Function(
  PhoneVerificationMethod method,
);

class LoginPhoneVerificationMethodPanel extends StatelessWidget {
  const LoginPhoneVerificationMethodPanel({
    super.key,
    required this.phoneMasked,
    required this.onMethodSelected,
    this.outboundEnabled = true,
  });

  final String phoneMasked;
  final PhoneVerificationMethodSelected onMethodSelected;
  final bool outboundEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.loginVerifyMethodTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.loginVerifyMethodSubtitle(phoneMasked),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            height: 1.45,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 28),
        LoginAuthActionRow(
          enabled: true,
          highlighted: true,
          accent: LoginWhatsAppBrandIcon.brandGreen,
          icon: const LoginWhatsAppBrandIcon(size: 28),
          label: l10n.loginVerifyMethodWaInboundShort,
          badge: l10n.loginVerifyMethodRecommendedBadge,
          infoMessage: l10n.loginVerifyMethodWaInboundInfo,
          onTap: () => onMethodSelected(PhoneVerificationMethod.whatsAppInbound),
        ),
        const SizedBox(height: 10),
        LoginAuthActionRow(
          enabled: outboundEnabled,
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
              ? () => onMethodSelected(PhoneVerificationMethod.verificationCode)
              : () {
                  TexiUiFeedback.softImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(l10n.loginVerifyMethodCodeComingSoon),
                    ),
                  );
                },
        ),
      ],
    );
  }
}
