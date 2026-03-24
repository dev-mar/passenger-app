import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';

enum _ProfileUiState { loading, loaded, empty, error, offline }

class PassengerProfilePreviewScreen extends StatefulWidget {
  const PassengerProfilePreviewScreen({super.key});

  @override
  State<PassengerProfilePreviewScreen> createState() =>
      _PassengerProfilePreviewScreenState();
}

class _PassengerProfilePreviewScreenState
    extends State<PassengerProfilePreviewScreen> {
  _ProfileUiState _uiState = _ProfileUiState.loading;

  @override
  void initState() {
    super.initState();
    _simulateLoad();
  }

  Future<void> _simulateLoad() async {
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() => _uiState = _ProfileUiState.loaded);
  }

  Future<void> _onRefresh() async {
    setState(() => _uiState = _ProfileUiState.loading);
    await _simulateLoad();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget content;
    switch (_uiState) {
      case _ProfileUiState.loading:
        content = const _ProfileSkeleton();
      case _ProfileUiState.loaded:
        content = const _ProfileLoadedContent();
      case _ProfileUiState.empty:
        content = _ProfileStateView(
          icon: Icons.person_search_rounded,
          title: AppLocalizations.of(context)!.profileEmptyTitle,
          message: AppLocalizations.of(context)!.profileEmptyBody,
          actionLabel: AppLocalizations.of(context)!.profileCompleteNow,
          onAction: _onRefresh,
        );
      case _ProfileUiState.error:
        content = _ProfileStateView(
          icon: Icons.error_outline_rounded,
          title: AppLocalizations.of(context)!.profileErrorTitle,
          message: AppLocalizations.of(context)!.profileErrorBody,
          actionLabel: AppLocalizations.of(context)!.homeRetry,
          onAction: _onRefresh,
        );
      case _ProfileUiState.offline:
        content = _ProfileStateView(
          icon: Icons.wifi_off_rounded,
          title: AppLocalizations.of(context)!.profileOfflineTitle,
          message: AppLocalizations.of(context)!.profileOfflineBody,
          actionLabel: AppLocalizations.of(context)!.profileRefresh,
          onAction: _onRefresh,
        );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileScreenTitle),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.profileRefreshTooltip,
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<_ProfileUiState>(
            tooltip: AppLocalizations.of(context)!.profileStatesPreviewTooltip,
            icon: const Icon(Icons.tune_rounded),
            onSelected: (s) => setState(() => _uiState = s),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ProfileUiState.loaded,
                child: Text(AppLocalizations.of(context)!.profileStateLoaded),
              ),
              PopupMenuItem(
                value: _ProfileUiState.loading,
                child: Text(AppLocalizations.of(context)!.profileStateLoading),
              ),
              PopupMenuItem(
                value: _ProfileUiState.empty,
                child: Text(AppLocalizations.of(context)!.profileStateEmpty),
              ),
              PopupMenuItem(
                value: _ProfileUiState.error,
                child: Text(AppLocalizations.of(context)!.profileStateError),
              ),
              PopupMenuItem(
                value: _ProfileUiState.offline,
                child: Text(AppLocalizations.of(context)!.profileStateOffline),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoadedContent extends StatelessWidget {
  const _ProfileLoadedContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(),
        SizedBox(height: 14),
        _StatsRow(),
        SizedBox(height: 14),
        _PersonalInfoCard(),
        SizedBox(height: 12),
        _PreferencesCard(),
        SizedBox(height: 12),
        _SecurityCard(),
        SizedBox(height: 18),
        _ActionsBlock(),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Semantics(
            label: AppLocalizations.of(context)!.profileAvatarSemantics,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.95),
                    AppColors.primary.withValues(alpha: 0.45),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.profileMockInitials,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.profileMockName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.profileMockPhone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.profileVerifiedBadge,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: _StatTile(label: l10n.profileStatTrips, value: l10n.profileStatTripsValue)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: l10n.profileStatRating, value: l10n.profileStatRatingValue)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: l10n.profileStatSavings, value: l10n.profileStatSavingsValue)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      title: l10n.profileSectionPersonalData,
      children: [
        _InfoRow(icon: Icons.mail_outline_rounded, label: l10n.profileFieldEmail, value: l10n.profileMockEmail),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.badge_outlined, label: l10n.profileFieldDocument, value: l10n.profileMockDocument),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.home_outlined, label: l10n.profileFieldAddress, value: l10n.profileMockAddress),
      ],
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      title: l10n.profileSectionPreferences,
      children: [
        _ToggleRow(
          icon: Icons.notifications_none_rounded,
          title: l10n.profileFieldNotifications,
          subtitle: l10n.profileFieldNotificationsDesc,
          value: true,
        ),
        const SizedBox(height: 8),
        _ToggleRow(
          icon: Icons.dark_mode_outlined,
          title: l10n.profileFieldDarkMode,
          subtitle: l10n.profileFieldDarkModeDesc,
          value: false,
        ),
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      title: l10n.profileSectionSecurity,
      children: [
        _InfoRow(icon: Icons.fingerprint_rounded, label: l10n.profileFieldBiometrics, value: l10n.profileMockBiometricsValue),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.lock_outline_rounded, label: l10n.profileFieldLastAccess, value: l10n.profileMockLastAccessValue),
      ],
    );
  }
}

class _ActionsBlock extends StatelessWidget {
  const _ActionsBlock();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TexiScalePress(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black87,
            ),
            onPressed: () {},
            icon: const Icon(Icons.edit_rounded),
            label: Text(l10n.profileActionEditInfo),
          ),
        ),
        const SizedBox(height: 10),
        TexiScalePress(
          minScale: 0.98,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded),
            label: Text(l10n.profileActionSupport),
          ),
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSkeletonBox(height: 112, radius: 20),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: PremiumSkeletonBox(height: 64, radius: 14)),
            SizedBox(width: 10),
            Expanded(child: PremiumSkeletonBox(height: 64, radius: 14)),
            SizedBox(width: 10),
            Expanded(child: PremiumSkeletonBox(height: 64, radius: 14)),
          ],
        ),
        SizedBox(height: 14),
        PremiumSkeletonBox(height: 156, radius: 16),
        SizedBox(height: 12),
        PremiumSkeletonBox(height: 122, radius: 16),
        SizedBox(height: 12),
        PremiumSkeletonBox(height: 96, radius: 16),
        SizedBox(height: 18),
        PremiumSkeletonBox(height: 48, radius: 12),
        SizedBox(height: 10),
        PremiumSkeletonBox(height: 46, radius: 12),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Semantics(
          label: '$title ${value ? l10n.commonEnabled : l10n.commonDisabled}',
          child: Switch.adaptive(value: value, onChanged: (_) {}),
        ),
      ],
    );
  }
}

class _ProfileStateView extends StatelessWidget {
  const _ProfileStateView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return PremiumStateView(
      key: ValueKey<String>('state-$title'),
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
