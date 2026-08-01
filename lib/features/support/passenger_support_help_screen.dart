import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/contacts/passenger_company_contacts.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../gen_l10n/app_localizations.dart';
import 'passenger_account_views_flags.dart';
import 'widgets/passenger_support_center_sheet.dart';
import 'widgets/passenger_verified_drivers_panel.dart';

/// Seguridad (ex Soporte): emergencia 110 + contacto + (V2) conductores verificados.
class PassengerSupportHelpScreen extends ConsumerStatefulWidget {
  const PassengerSupportHelpScreen({super.key});

  @override
  ConsumerState<PassengerSupportHelpScreen> createState() =>
      _PassengerSupportHelpScreenState();
}

class _PassengerSupportHelpScreenState
    extends ConsumerState<PassengerSupportHelpScreen> {
  static const _card = Color(0xFF141414);
  bool _showVerifiedDrivers = false;

  Future<void> _safeCall(
    BuildContext context,
    Future<bool> Function() launch,
    String failMsg,
  ) async {
    TexiUiFeedback.lightTap();
    final ok = await launch();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failMsg)),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Icons.verified_user_rounded,
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
                    l10n.menuSupportHelp,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.supportHelpSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: AppColors.onPrimary,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.supportEmergencyTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.supportEmergencyBody(
                            PassengerCompanyContacts.emergencyDisplay,
                          ),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: AppSizes.buttonHeight,
                          child: FilledButton.icon(
                            onPressed: () => _safeCall(
                              context,
                              PassengerCompanyContacts.callEmergency,
                              l10n.supportCallFailed,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.phone_rounded),
                            label: Text(
                              l10n.supportCallNowCta,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (kPassengerAccountViewsV2) ...[
                    const SizedBox(height: 22),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(
                            () => _showVerifiedDrivers = !_showVerifiedDrivers,
                          );
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF5EE0A8).withValues(alpha: 0.16),
                                _card,
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFF5EE0A8)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5EE0A8)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFF5EE0A8),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.operatorVerifiedDriversCtaTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                      Text(
                                        l10n.operatorVerifiedDriversCtaSubtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _showVerifiedDrivers
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: const Color(0xFF5EE0A8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: PassengerVerifiedDriversPanel(),
                      ),
                      crossFadeState: _showVerifiedDrivers
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 280),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    l10n.supportMoreOptionsTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _HelpOptionTile(
                    icon: Icons.chat_rounded,
                    title: l10n.supportWhatsAppTitle,
                    subtitle: PassengerCompanyContacts.companyPhoneDisplay,
                    onTap: () => _safeCall(
                      context,
                      PassengerCompanyContacts.openCompanyWhatsApp,
                      l10n.supportCallFailed,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _HelpOptionTile(
                    icon: Icons.support_agent_rounded,
                    title: l10n.profileSupportCenterTitle,
                    subtitle: l10n.supportTicketsSubtitle,
                    onTap: () async {
                      TexiUiFeedback.lightTap();
                      await showPassengerSupportCenterSheet(
                        context: context,
                        ref: ref,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _HelpOptionTile(
                    icon: Icons.call_rounded,
                    title: l10n.supportCompanyCallTitle,
                    subtitle: PassengerCompanyContacts.companyPhoneDisplay,
                    onTap: () => _safeCall(
                      context,
                      PassengerCompanyContacts.callCompany,
                      l10n.supportCallFailed,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: AppColors.primary.withValues(alpha: 0.9),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.supportTrustFooter,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpOptionTile extends StatelessWidget {
  const _HelpOptionTile({
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
