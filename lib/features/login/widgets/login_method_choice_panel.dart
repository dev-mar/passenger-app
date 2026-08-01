import 'package:flutter/material.dart';

import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'login_google_brand_icon.dart';

typedef LoginMethodSelected = void Function(LoginEntryMethod method);

enum LoginEntryMethod { phone, google }

class LoginMethodChoicePanel extends StatelessWidget {
  const LoginMethodChoicePanel({
    super.key,
    required this.onMethodSelected,
    this.googleAuthEnabled = false,
  });

  final LoginMethodSelected onMethodSelected;
  final bool googleAuthEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.loginMethodChoiceTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.loginMethodChoiceSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.92),
            height: 1.45,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 28),
        _LoginMethodCard(
          highlighted: true,
          onTap: () {
            TexiUiFeedback.softImpact();
            onMethodSelected(LoginEntryMethod.phone);
          },
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.smartphone_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          title: l10n.loginMethodPhoneTitle,
          subtitle: l10n.loginMethodPhoneSubtitle,
          trailing: Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.primary.withValues(alpha: 0.95),
            size: 20,
          ),
        ),
        const SizedBox(height: AppSpacing.xxx),
        _LoginMethodCard(
          highlighted: false,
          badge: googleAuthEnabled ? null : l10n.loginMethodGoogleBadge,
          onTap: () {
            TexiUiFeedback.softImpact();
            onMethodSelected(LoginEntryMethod.google);
          },
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Center(child: LoginGoogleBrandIcon(size: 24)),
          ),
          title: l10n.loginMethodGoogleTitle,
          subtitle: l10n.loginMethodGoogleSubtitle,
          trailing: Icon(
            Icons.mail_outline_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.85),
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _LoginMethodCard extends StatelessWidget {
  const _LoginMethodCard({
    required this.highlighted,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.badge,
  });

  final bool highlighted;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted
        ? AppColors.primary.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.1);
    final fill = highlighted
        ? AppColors.primary.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.04);

    return TexiScalePress(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.dialog),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.dialog),
              color: fill,
              border: Border.all(color: borderColor, width: highlighted ? 1.4 : 1),
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              child: Row(
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
                                  fontSize: 15.5,
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
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
                                ),
                                child: Text(
                                  badge!,
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
