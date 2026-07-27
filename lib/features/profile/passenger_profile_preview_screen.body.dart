part of 'passenger_profile_preview_screen.dart';

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onClose,
    required this.l10n,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IconButton(
              alignment: Alignment.centerLeft,
              onPressed: onClose,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: AppColors.primary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: AppSpacing.sheetV),
                  Text(
                    l10n.profileErrorTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  FilledButton.icon(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.homeRetry),
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

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.l10n,
    required this.onRefresh,
    required this.onEditInfo,
    required this.onSupport,
    required this.onLanguage,
  });

  final PassengerProfileVm profile;
  final AppLocalizations l10n;
  final Future<void> Function() onRefresh;
  final VoidCallback onEditInfo;
  final VoidCallback onSupport;
  final VoidCallback onLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(
              profile: profile,
              l10n: l10n,
              onRefresh: onRefresh,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxx,
              0,
              AppSpacing.xxx,
              AppSpacing.sheetBodyV,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHighlights(profile: profile, l10n: l10n),
                  const SizedBox(height: AppSpacing.section),
                  _QuickActionsPanel(
                    l10n: l10n,
                    onEditInfo: onEditInfo,
                    onSupport: onSupport,
                    onLanguage: onLanguage,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _ModernSectionTitle(label: l10n.profileSectionBasics),
                  const SizedBox(height: AppSpacing.xl),
                  _GlassCard(
                    child: Column(
                      children: [
                        _DataRow(
                          icon: Icons.badge_outlined,
                          label: l10n.profileFieldFullName,
                          value: profile.displayName.isEmpty ? l10n.commonEmptyDash : profile.displayName,
                        ),
                        const Divider(height: 1),
                        _DataRow(
                          icon: Icons.smartphone_rounded,
                          label: l10n.profileFieldPhone,
                          value: profile.phone.isEmpty ? l10n.commonEmptyDash : profile.phone,
                        ),
                        if (profile.email != null && profile.email!.isNotEmpty) ...[
                          const Divider(height: 1),
                          _DataRow(
                            icon: Icons.alternate_email_rounded,
                            label: l10n.profileFieldEmail,
                            value: profile.email!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _ModernSectionTitle(label: l10n.profileSectionPreferences),
                  const SizedBox(height: AppSpacing.xl),
                  _PreferencesCard(l10n: l10n),
                  const SizedBox(height: AppSpacing.section),
                  _ModernSectionTitle(label: l10n.profileSectionSecurity),
                  const SizedBox(height: AppSpacing.xl),
                  _SecurityCard(
                    l10n: l10n,
                    profile: profile,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _ModernSectionTitle(label: l10n.passengerLegalSectionTitle),
                  const SizedBox(height: AppSpacing.xl),
                  const PassengerProfileLegalSection(showTitle: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.l10n,
    required this.onRefresh,
  });

  final PassengerProfileVm profile;
  final AppLocalizations l10n;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName.isEmpty ? profile.phone : profile.displayName;
    final subtitle = profile.displayName.isEmpty ? l10n.profileTaglinePassenger : profile.phone;
    final hasEmail = profile.email != null && profile.email!.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxx,
        0,
        AppSpacing.xxx,
        AppSpacing.section,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.28),
            AppColors.surface.withValues(alpha: 0.82),
            AppColors.background.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.62, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    TexiUiFeedback.lightTap();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(AppRouter.home);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.onPrimary,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.22),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: l10n.profileRefreshTooltip,
                  onPressed: () async {
                    TexiUiFeedback.lightTap();
                    await onRefresh();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.onPrimary,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _ChipPill(
                  icon: profile.isVerified
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  label: profile.isVerified
                      ? l10n.profileVerifiedBadge
                      : l10n.profileSectionSecurity,
                  foreground: profile.isVerified
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
                if (hasEmail)
                  _ChipPill(
                    icon: Icons.alternate_email_rounded,
                    label: profile.email ?? '',
                    foreground: AppColors.textSecondary,
                  ),
                if (profile.accountStatus != null &&
                    profile.accountStatus!.isNotEmpty)
                  _ChipPill(
                    icon: Icons.shield_outlined,
                    label:
                        '${l10n.profileAccountLabel}: ${profile.accountStatus}',
                    foreground: AppColors.textSecondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSectionTitle extends StatelessWidget {
  const _ModernSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadii.xs),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadii.lg + 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: child,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxx,
        vertical: AppSpacing.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primary.withValues(alpha: 0.9)),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
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

class _ProfileHighlights extends StatelessWidget {
  const _ProfileHighlights({
    required this.profile,
    required this.l10n,
  });

  final PassengerProfileVm profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    String cleanPhotoLabel(String value) =>
        value.replaceAll('(servidor)', '').replaceAll('(server)', '').trim();
    final hasName = profile.displayName.trim().isNotEmpty;
    final hasPhone = profile.phone.trim().isNotEmpty;
    final hasEmail = profile.email != null && profile.email!.trim().isNotEmpty;
    final hasPhoto = profile.profilePhotoUrl != null && profile.profilePhotoUrl!.trim().isNotEmpty;
    final completed = [hasName, hasPhone, hasEmail, hasPhoto].where((e) => e).length;
    final completion = ((completed / 4) * 100).round();

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profileSectionBasics,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                Text(
                  '$completion%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: completion / 100,
                color: AppColors.primary,
                backgroundColor: AppColors.border.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.verified_user_outlined,
                    label: l10n.profileAccountLabel,
                    value: profile.isVerified ? 'OK' : l10n.commonEmptyDash,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatItem(
                    icon: Icons.contact_page_outlined,
                    label: l10n.profileFieldFullName,
                    value: hasName ? 'OK' : l10n.commonEmptyDash,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatItem(
                    icon: Icons.image_outlined,
                    label: cleanPhotoLabel(l10n.profilePhotoFromServer),
                    value: hasPhoto ? 'OK' : l10n.commonEmptyDash,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({
    required this.l10n,
    required this.onEditInfo,
    required this.onSupport,
    required this.onLanguage,
  });

  final AppLocalizations l10n;
  final VoidCallback onEditInfo;
  final VoidCallback onSupport;
  final VoidCallback onLanguage;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.profileQuickActions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.profileTaglinePassenger,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              children: [
                _ActionCard(
                  icon: Icons.edit_outlined,
                  label: l10n.profileActionEditInfo,
                  subtitle: l10n.profileSectionBasics,
                  onTap: onEditInfo,
                ),
                const SizedBox(height: AppSpacing.md),
                _ActionCard(
                  icon: Icons.support_agent_rounded,
                  label: l10n.profileActionSupport,
                  subtitle: l10n.profileSectionSecurity,
                  onTap: onSupport,
                ),
                const SizedBox(height: AppSpacing.md),
                _ActionCard(
                  icon: Icons.language_rounded,
                  label: l10n.settingsLanguage,
                  subtitle: l10n.homeTooltipLanguage,
                  onTap: onLanguage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.987 : 1,
      duration: const Duration(milliseconds: 110),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.92),
                AppColors.background.withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _PreferencesCard extends StatefulWidget {
  const _PreferencesCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<_PreferencesCard> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await AuthService.getPassengerPreferences();
    if (!mounted) return;
    setState(() {
      _notifications = prefs.notificationsEnabled;
      _darkMode = prefs.darkModeEnabled;
      _loaded = true;
    });
  }

  Future<void> _persist() async {
    await AuthService.savePassengerPreferences(
      notificationsEnabled: _notifications,
      darkModeEnabled: _darkMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const _GlassCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxx),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    return _GlassCard(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: _notifications,
            onChanged: (v) {
              TexiUiFeedback.lightTap();
              setState(() => _notifications = v);
              _persist();
            },
            title: Text(widget.l10n.profileFieldNotifications),
            subtitle: Text(widget.l10n.profileFieldNotificationsDesc),
            secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            value: _darkMode,
            onChanged: (v) {
              TexiUiFeedback.lightTap();
              setState(() => _darkMode = v);
              _persist();
            },
            title: Text(widget.l10n.profileFieldDarkMode),
            subtitle: Text(widget.l10n.profileFieldDarkModeDesc),
            secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.l10n,
    required this.profile,
  });

  final AppLocalizations l10n;
  final PassengerProfileVm profile;

  String _formatLastAccess() {
    final dt = profile.lastAccessAt;
    if (dt == null) return l10n.profileSecurityNotAvailable;
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          _DataRow(
            icon: Icons.fingerprint_rounded,
            label: l10n.profileFieldBiometrics,
            value: profile.biometricsEnabled
                ? l10n.commonEnabled
                : l10n.commonDisabled,
          ),
          const Divider(height: 1),
          _DataRow(
            icon: Icons.schedule_rounded,
            label: l10n.profileFieldLastAccess,
            value: _formatLastAccess(),
          ),
        ],
      ),
    );
  }
}
