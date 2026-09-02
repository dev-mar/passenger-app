import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/network/passenger_api_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../../../core/compliance/passenger_account_deletion_service.dart';
import '../../../core/compliance/passenger_legal_links.dart';

String? formatPassengerAccountDeletionDate(BuildContext context, String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return null;
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(parsed.toLocal());
}

Future<void> showPassengerAccountDeletionDialog(
  BuildContext context,
  AppLocalizations l10n,
  WidgetRef ref, {
  required int graceDays,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        icon: Icon(Icons.person_remove_outlined, color: AppColors.primary),
        title: Text(l10n.passengerLegalDeleteAccountTitle),
        content: Text(l10n.passengerLegalDeleteAccountBodyGrace(graceDays)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openPassengerAccountDeletionInfo(context);
            },
            child: Text(l10n.passengerLegalDeleteAccountAction),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (!context.mounted) return;
              await _runPassengerAccountDeletionSchedule(context, l10n, ref);
            },
            child: Text(l10n.passengerLegalDeleteAccountConfirmNow),
          ),
        ],
      );
    },
  );
}

Future<void> _runPassengerAccountDeletionSchedule(
  BuildContext context,
  AppLocalizations l10n,
  WidgetRef ref,
) async {
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: Text(l10n.passengerLegalDeleteAccountDeleting)),
        ],
      ),
    ),
  );

  final result = await PassengerAccountDeletionService().deleteAccount();
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  switch (result) {
    case PassengerAccountDeletionScheduled(:final message):
      await AuthService.logout();
      ref.invalidate(passengerMeProfileDataProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? l10n.passengerLegalDeleteAccountScheduledSuccess,
          ),
        ),
      );
      context.goNamed(AppRouter.login);
    case PassengerAccountDeletionCancelled():
      break;
    case PassengerAccountDeletionFailure failure:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedPassengerAccountDeletionFailure(
              l10n,
              failure,
              flow: PassengerAccountDeletionFlow.schedule,
            ),
          ),
        ),
      );
  }
}

Future<void> _runPassengerAccountDeletionCancel(
  BuildContext context,
  AppLocalizations l10n,
  WidgetRef ref,
) async {
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: Text(l10n.passengerLegalDeleteAccountCancelling)),
        ],
      ),
    ),
  );

  final result = await PassengerAccountDeletionService().cancelAccountDeletion();
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  switch (result) {
    case PassengerAccountDeletionCancelled(:final message):
      ref.invalidate(passengerMeProfileDataProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? l10n.passengerLegalDeleteAccountCancelSuccess,
          ),
        ),
      );
    case PassengerAccountDeletionScheduled():
      break;
    case PassengerAccountDeletionFailure failure:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedPassengerAccountDeletionFailure(
              l10n,
              failure,
              flow: PassengerAccountDeletionFlow.cancel,
            ),
          ),
        ),
      );
  }
}

/// Documentos legales del perfil (privacidad y términos). La eliminación de cuenta está en Ajustes.
class PassengerProfileLegalSection extends StatelessWidget {
  const PassengerProfileLegalSection({
    super.key,
    this.showTitle = true,
  });

  /// Si el padre ya muestra el título de sección, pasar `false`.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            l10n.passengerLegalSectionTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          l10n.passengerLegalSectionSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.88),
                height: 1.4,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _LegalDocTile(
          icon: Icons.shield_outlined,
          accent: AppColors.primary,
          label: l10n.passengerLegalPrivacyPolicy,
          onTap: () {
            HapticFeedback.selectionClick();
            openPassengerPrivacyPolicy(context);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _LegalDocTile(
          icon: Icons.menu_book_outlined,
          accent: const Color(0xFF7EB6FF),
          label: l10n.passengerLegalTermsOfService,
          onTap: () {
            HapticFeedback.selectionClick();
            openPassengerTerms(context);
          },
        ),
      ],
    );
  }
}

class _LegalDocTile extends StatelessWidget {
  const _LegalDocTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161616),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                accent.withValues(alpha: 0.10),
                const Color(0xFF161616),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxx,
              vertical: AppSpacing.xxl,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: AppTypography.bodyLarge,
                        ),
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
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

/// Eliminación de cuenta: solo Ajustes (no perfil).
class PassengerAccountDeletionSettingsBlock extends ConsumerWidget {
  const PassengerAccountDeletionSettingsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(passengerMeProfileDataProvider);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _buildBody(context, l10n, ref, null),
      data: (profile) {
        final deletion = PassengerAccountDeletionStatus.fromJson(
          profile['account_deletion'] as Map<String, dynamic>?,
        );
        return _buildBody(context, l10n, ref, deletion);
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
    PassengerAccountDeletionStatus? deletion,
  ) {
    final graceDays = deletion?.graceDays ?? 20;
    final pending = deletion?.pending == true;
    final effectiveDate = formatPassengerAccountDeletionDate(
          context,
          deletion?.deletionEffectiveAt,
        ) ??
        l10n.passengerLegalDeleteAccountPendingDateFallback;
    final daysRemaining = deletion?.daysRemaining ?? graceDays;

    if (pending) {
      return Material(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxx),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.passengerLegalDeleteAccountPendingTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.passengerLegalDeleteAccountPendingBody(
                  effectiveDate,
                  daysRemaining,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () =>
                    _runPassengerAccountDeletionCancel(context, l10n, ref),
                child: Text(l10n.passengerLegalDeleteAccountCancelAction),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: const Color(0xFF161616),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.lightImpact();
          showPassengerAccountDeletionDialog(
            context,
            l10n,
            ref,
            graceDays: graceDays,
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxx,
              vertical: AppSpacing.xxl,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.person_remove_outlined,
                    color: AppColors.error.withValues(alpha: 0.95),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Text(
                    l10n.passengerLegalDeleteAccountTitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
