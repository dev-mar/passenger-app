import 'package:flutter/material.dart';

import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'login_whatsapp_brand_icon.dart';
import 'passenger_auth_shell.dart';

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
        Center(child: LoginWhatsAppBrandIcon(size: 56)),
        const SizedBox(height: 18),
        Text(
          l10n.loginVerifyMethodTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.loginVerifyMethodSubtitle(phoneMasked),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.92),
            height: 1.45,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 24),
        PassengerAuthGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _VerificationMethodTile(
                highlighted: true,
                badge: l10n.loginVerifyMethodRecommendedBadge,
                leading: const LoginWhatsAppBrandIcon(size: 44),
                title: l10n.loginVerifyMethodWaInboundTitle,
                subtitle: l10n.loginVerifyMethodWaInboundSubtitle,
                onTap: () {
                  TexiUiFeedback.softImpact();
                  onMethodSelected(PhoneVerificationMethod.whatsAppInbound);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        l10n.loginVerifyMethodOrDivider,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.75),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              _VerificationMethodTile(
                highlighted: false,
                badge: outboundEnabled ? null : l10n.loginMethodGoogleBadge,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.sms_outlined,
                    color: AppColors.textPrimary.withValues(alpha: 0.9),
                    size: 22,
                  ),
                ),
                title: l10n.loginVerifyMethodCodeTitle,
                subtitle: l10n.loginVerifyMethodCodeSubtitle,
                onTap: outboundEnabled
                    ? () {
                        TexiUiFeedback.softImpact();
                        onMethodSelected(
                          PhoneVerificationMethod.verificationCode,
                        );
                      }
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
          ),
        ),
      ],
    );
  }
}

class _VerificationMethodTile extends StatelessWidget {
  const _VerificationMethodTile({
    required this.highlighted,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final bool highlighted;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted
        ? LoginWhatsAppBrandIcon.brandGreen.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.1);
    final fill = highlighted
        ? LoginWhatsAppBrandIcon.brandGreen.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.03);

    return TexiScalePress(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              color: fill,
              border: Border.all(
                color: borderColor,
                width: highlighted ? 1.35 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: AppSpacing.xxx),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: highlighted
                                      ? LoginWhatsAppBrandIcon.brandGreen
                                          .withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.pill),
                                ),
                                child: Text(
                                  badge!,
                                  style: TextStyle(
                                    color: highlighted
                                        ? LoginWhatsAppBrandIcon.brandGreen
                                        : AppColors.textSecondary
                                            .withValues(alpha: 0.95),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.92),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: highlighted
                        ? LoginWhatsAppBrandIcon.brandGreen
                            .withValues(alpha: 0.95)
                        : AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
