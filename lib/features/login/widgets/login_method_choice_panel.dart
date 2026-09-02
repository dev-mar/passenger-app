import 'package:flutter/material.dart';

import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'login_auth_info_button.dart';
import 'login_google_brand_icon.dart';
import 'passenger_auth_look.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PassengerAuthHeadline(
          title: l10n.loginMethodChoiceTitle,
          subtitle: l10n.loginMethodChoiceSubtitle,
        ),
        const SizedBox(height: 28),
        _LoginMethodCard(
          highlighted: true,
          onTap: () {
            TexiUiFeedback.softImpact();
            onMethodSelected(LoginEntryMethod.phone);
          },
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smartphone_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          title: l10n.loginMethodPhoneTitle,
          subtitle: l10n.loginMethodPhoneSubtitle,
          infoMessage: l10n.loginMethodPhoneInfo,
        ),
        const SizedBox(height: 10),
        _LoginMethodCard(
          highlighted: false,
          badge: googleAuthEnabled ? null : l10n.loginMethodGoogleBadge,
          onTap: () {
            TexiUiFeedback.softImpact();
            onMethodSelected(LoginEntryMethod.google);
          },
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PassengerAuthLook.hairline),
            ),
            child: const Center(child: LoginGoogleBrandIcon(size: 22)),
          ),
          title: l10n.loginMethodGoogleTitle,
          subtitle: l10n.loginMethodGoogleSubtitle,
          infoMessage: l10n.loginMethodGoogleInfo,
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
    required this.infoMessage,
    this.badge,
  });

  final bool highlighted;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final String infoMessage;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return TexiScalePress(
      child: DecoratedBox(
        decoration: highlighted
            ? PassengerAuthLook.highlightedDecoration(AppColors.primary)
            : PassengerAuthLook.panelDecoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          leading,
                          const SizedBox(width: 12),
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
                                          letterSpacing: -0.15,
                                        ),
                                      ),
                                    ),
                                    if (badge != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        badge!,
                                        style: const TextStyle(
                                          color: PassengerAuthLook.muted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: PassengerAuthLook.muted,
                                    fontSize: 12.5,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              LoginAuthInfoButton(
                message: infoMessage,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
