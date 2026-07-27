import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../gen_l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_ui_tokens.dart';
import 'passenger_legal_links.dart';

/// Aviso legal sutil en login / onboarding (Play Store: privacidad accesible sin sesión).
///
/// Variante [PassengerLegalNoticeTone.compact]: una línea + enlaces inline.
/// Variante [PassengerLegalNoticeTone.emphasized]: bloque suave (p. ej. cierre de registro).
enum PassengerLegalNoticeTone { compact, emphasized }

class PassengerLoginLegalFooter extends StatelessWidget {
  const PassengerLoginLegalFooter({
    super.key,
    this.textColor,
    this.tone = PassengerLegalNoticeTone.compact,
  });

  final Color? textColor;
  final PassengerLegalNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = textColor ?? AppColors.textSecondary;
    final linkColor = AppColors.primary;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tone == PassengerLegalNoticeTone.emphasized
              ? l10n.passengerLegalRegistrationHint
              : l10n.passengerLegalLoginHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: secondary,
                height: 1.4,
                fontSize: AppTypography.bodySmall,
                fontWeight: FontWeight.w400,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _LegalLinkRow(
          privacyLabel: l10n.passengerLegalPrivacyPolicy,
          termsLabel: l10n.passengerLegalTermsOfService,
          linkColor: linkColor,
          onPrivacy: () {
            HapticFeedback.selectionClick();
            openPassengerPrivacyPolicy(context);
          },
          onTerms: () {
            HapticFeedback.selectionClick();
            openPassengerTerms(context);
          },
        ),
      ],
    );

    if (tone == PassengerLegalNoticeTone.compact) {
      return body;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxx,
          AppSpacing.xxxx,
          AppSpacing.xxx,
          AppSpacing.xxxx,
        ),
        child: body,
      ),
    );
  }
}

class _LegalLinkRow extends StatelessWidget {
  const _LegalLinkRow({
    required this.privacyLabel,
    required this.termsLabel,
    required this.linkColor,
    required this.onPrivacy,
    required this.onTerms,
  });

  final String privacyLabel;
  final String termsLabel;
  final Color linkColor;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _LinkChip(label: privacyLabel, color: linkColor, onTap: onPrivacy),
        Text(
          '·',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        _LinkChip(label: termsLabel, color: linkColor, onTap: onTerms),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: AppTypography.captionAlt,
                      decoration: TextDecoration.underline,
                      decorationColor: color.withValues(alpha: 0.45),
                      decorationThickness: 1.2,
                      height: 1.2,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
