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
    case PassengerAccountDeletionFailure(:final message):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
    case PassengerAccountDeletionFailure(:final message):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}

/// Documentos legales + eliminación de cuenta (perfil).
class PassengerProfileLegalSection extends ConsumerWidget {
  const PassengerProfileLegalSection({
    super.key,
    this.showTitle = true,
  });

  /// Si el padre ya muestra el título de sección, pasar `false`.
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(passengerMeProfileDataProvider);

    return profileAsync.when(
      loading: () => _buildLegalBody(context, l10n, ref, null),
      error: (_, _) => _buildLegalBody(context, l10n, ref, null),
      data: (profile) {
        final deletion = PassengerAccountDeletionStatus.fromJson(
          profile['account_deletion'] as Map<String, dynamic>?,
        );
        return _buildLegalBody(context, l10n, ref, deletion);
      },
    );
  }

  Widget _buildLegalBody(
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
                color: AppColors.textSecondary.withValues(alpha: 0.85),
                height: 1.35,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              _LegalRow(
                icon: Icons.privacy_tip_outlined,
                label: l10n.passengerLegalPrivacyPolicy,
                onTap: () {
                  HapticFeedback.selectionClick();
                  openPassengerPrivacyPolicy(context);
                },
              ),
              Divider(
                height: 1,
                indent: 52,
                color: AppColors.border.withValues(alpha: 0.28),
              ),
              _LegalRow(
                icon: Icons.description_outlined,
                label: l10n.passengerLegalTermsOfService,
                onTap: () {
                  HapticFeedback.selectionClick();
                  openPassengerTerms(context);
                },
              ),
              if (!pending) ...[
                Divider(
                  height: 1,
                  indent: 52,
                  color: AppColors.border.withValues(alpha: 0.28),
                ),
                _LegalRow(
                  icon: Icons.person_remove_outlined,
                  label: l10n.passengerLegalDeleteAccountTitle,
                  labelColor: AppColors.error,
                  iconColor: AppColors.error.withValues(alpha: 0.9),
                  trailing: Icons.chevron_right_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showPassengerAccountDeletionDialog(
                      context,
                      l10n,
                      ref,
                      graceDays: graceDays,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        if (pending) ...[
          const SizedBox(height: AppSpacing.md),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.passengerLegalDeleteAccountPendingTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
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
          ),
        ],
      ],
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.trailing = Icons.open_in_new_rounded,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxx,
            vertical: AppSpacing.xxxx,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppIconSizes.lg,
                color: iconColor ?? AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: labelColor ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: AppTypography.bodyLarge,
                      ),
                ),
              ),
              Icon(
                trailing,
                size: AppIconSizes.sm,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
