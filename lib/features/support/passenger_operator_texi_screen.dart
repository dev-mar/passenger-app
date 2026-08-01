import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/contacts/passenger_company_contacts.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../gen_l10n/app_localizations.dart';
import 'passenger_account_views_flags.dart';
import 'widgets/passenger_verified_drivers_panel.dart';

/// Contacto Operador Texi.
///
/// Con [kPassengerAccountViewsV2]: solo Seguridad / WhatsApp / Llamar.
/// Con flag en `false`: layout previo (incluye Conductores verificados).
class PassengerOperatorTexiScreen extends StatelessWidget {
  const PassengerOperatorTexiScreen({super.key});

  Future<void> _call(BuildContext context, AppLocalizations l10n) async {
    TexiUiFeedback.lightTap();
    final ok = await PassengerCompanyContacts.callCompany();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.supportCallFailed)),
      );
    }
  }

  Future<void> _whatsapp(BuildContext context, AppLocalizations l10n) async {
    TexiUiFeedback.lightTap();
    final ok = await PassengerCompanyContacts.openCompanyWhatsApp();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.supportCallFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      TexiUiFeedback.lightTap();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: Text(
                      l10n.profileBrandTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.phone_in_talk_rounded,
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Text(
                    l10n.menuOperatorTexi,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.operatorTexiSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 22),
                  if (kPassengerAccountViewsV2) ...[
                    _OperatorActionCard(
                      icon: Icons.chat_rounded,
                      title: l10n.supportWhatsAppTitle,
                      subtitle: PassengerCompanyContacts.companyPhoneDisplay,
                      accent: const Color(0xFF25D366),
                      onTap: () => _whatsapp(context, l10n),
                    ),
                    const SizedBox(height: 12),
                    _OperatorActionCard(
                      icon: Icons.phone_in_talk_rounded,
                      title: l10n.operatorCallTitle,
                      subtitle: PassengerCompanyContacts.companyPhoneDisplay,
                      accent: const Color(0xFF7C9CFF),
                      onTap: () => _call(context, l10n),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.operatorSecurityCareMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _OperatorActionCard(
                      icon: Icons.shield_rounded,
                      title: l10n.operatorSecurityCtaTitle,
                      subtitle: l10n.operatorSecurityCtaSubtitle,
                      accent: const Color(0xFFFFD600),
                      emphasis: true,
                      onTap: () {
                        TexiUiFeedback.lightTap();
                        context.pushNamed(AppRouter.supportHelp);
                      },
                    ),
                  ] else ...[
                    // --- Layout legacy (revert: kPassengerAccountViewsV2 = false) ---
                    _LegacyContactRow(
                      icon: Icons.shield_rounded,
                      title: l10n.operatorSecurityCtaTitle,
                      subtitle: l10n.operatorSecurityCtaSubtitle,
                      onTap: () {
                        TexiUiFeedback.lightTap();
                        context.pushNamed(AppRouter.supportHelp);
                      },
                    ),
                    const SizedBox(height: 10),
                    _LegacyContactRow(
                      icon: Icons.chat_rounded,
                      title: l10n.supportWhatsAppTitle,
                      subtitle: PassengerCompanyContacts.companyPhoneDisplay,
                      onTap: () => _whatsapp(context, l10n),
                    ),
                    const SizedBox(height: 10),
                    _LegacyContactRow(
                      icon: Icons.phone_in_talk_rounded,
                      title: l10n.operatorCallTitle,
                      subtitle: PassengerCompanyContacts.companyPhoneDisplay,
                      onTap: () => _call(context, l10n),
                    ),
                    const SizedBox(height: 28),
                    const PassengerVerifiedDriversPanel(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperatorActionCard extends StatelessWidget {
  const _OperatorActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.emphasis = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: emphasis ? 0.22 : 0.12),
                const Color(0xFF141414),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: emphasis ? 0.55 : 0.28),
              width: emphasis ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: emphasis ? 0.18 : 0.08),
                blurRadius: emphasis ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: emphasis ? 18 : 16,
            ),
            child: Row(
              children: [
                Container(
                  width: emphasis ? 52 : 48,
                  height: emphasis ? 52 : 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: emphasis ? 28 : 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontSize: emphasis ? 18 : 16,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: accent.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegacyContactRow extends StatelessWidget {
  const _LegacyContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
