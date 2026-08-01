import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../gen_l10n/app_localizations.dart';

/// Lista “cómo TEXI verifica conductores” (compartida Operador legacy / Seguridad V2).
class PassengerVerifiedDriversPanel extends StatelessWidget {
  const PassengerVerifiedDriversPanel({
    super.key,
    this.compact = false,
  });

  final bool compact;

  static List<({IconData icon, String title, String body, Color accent})>
      items(AppLocalizations l10n) {
    return [
      (
        icon: Icons.badge_outlined,
        title: l10n.operatorCheckIdentityTitle,
        body: l10n.operatorCheckIdentityBody,
        accent: const Color(0xFFFFD600),
      ),
      (
        icon: Icons.policy_outlined,
        title: l10n.operatorCheckBackgroundTitle,
        body: l10n.operatorCheckBackgroundBody,
        accent: const Color(0xFF7C9CFF),
      ),
      (
        icon: Icons.directions_car_outlined,
        title: l10n.operatorCheckInspectionTitle,
        body: l10n.operatorCheckInspectionBody,
        accent: const Color(0xFF5EE0A8),
      ),
      (
        icon: Icons.health_and_safety_outlined,
        title: l10n.operatorCheckInsuranceTitle,
        body: l10n.operatorCheckInsuranceBody,
        accent: const Color(0xFFFF8A65),
      ),
      (
        icon: Icons.school_outlined,
        title: l10n.operatorCheckTrainingTitle,
        body: l10n.operatorCheckTrainingBody,
        accent: const Color(0xFFCE93D8),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checks = items(l10n);
    final gap = compact ? 8.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.35),
                    AppColors.primary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.operatorVerifiedDriversTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                l10n.appName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 12 : 14),
        for (final c in checks) ...[
          _VerifiedCheckCard(
            icon: c.icon,
            title: c.title,
            body: c.body,
            accent: c.accent,
          ),
          SizedBox(height: gap),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.operatorTrustClosing,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

class _VerifiedCheckCard extends StatelessWidget {
  const _VerifiedCheckCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.black, size: 16),
          ),
        ],
      ),
    );
  }
}
