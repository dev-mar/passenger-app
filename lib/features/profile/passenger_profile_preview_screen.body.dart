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
    final hasName = profile.displayName.trim().isNotEmpty;
    final hasPhone = profile.phone.trim().isNotEmpty;
    final hasEmail = profile.email != null && profile.email!.trim().isNotEmpty;
    final hasPhoto =
        profile.profilePhotoUrl != null &&
        profile.profilePhotoUrl!.trim().isNotEmpty;
    final completed =
        [hasName, hasPhone, hasEmail, hasPhoto].where((e) => e).length;
    final missing = 4 - completed;
    final completion = ((completed / 4) * 100).round();
    final name =
        profile.displayName.isEmpty ? profile.phone : profile.displayName;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          color: AppColors.primary,
                        ),
                        Expanded(
                          child: Text(
                            l10n.profileBrandTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.profileSettingsTitle,
                          onPressed: onLanguage,
                          icon: const Icon(Icons.settings_rounded),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: hasPhoto
                                    ? Image.network(
                                        profile.profilePhotoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _ProfileInitialsAvatar(
                                          name: name,
                                          size: 82,
                                        ),
                                      )
                                    : _ProfileInitialsAvatar(
                                        name: name,
                                        size: 82,
                                      ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.background,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  size: 16,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      profile.phone.isEmpty
                                          ? l10n.commonEmptyDash
                                          : profile.phone,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    profile.isVerified
                                        ? Icons.verified_rounded
                                        : Icons.info_outline_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    profile.isVerified
                                        ? l10n.profileVerifiedUserLabel
                                        : l10n.profileSectionSecurity,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.profileCompletenessTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ),
                              Text(
                                '$completion%',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: completed / 4,
                              minHeight: 8,
                              backgroundColor: Colors.white12,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            missing == 0
                                ? l10n.profileCompletenessDone
                                : l10n.profileCompletenessMissing(missing),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          if (missing > 0) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              height: AppSizes.buttonHeight,
                              child: FilledButton(
                                onPressed: onEditInfo,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  l10n.profileCompleteInfoCta,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      l10n.profileQuickActions,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickTile(
                            icon: Icons.edit_outlined,
                            label: l10n.profileActionEditInfo,
                            onTap: onEditInfo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickTile(
                            icon: Icons.headset_mic_rounded,
                            label: l10n.profileActionSupport,
                            onTap: onSupport,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickTile(
                            icon: Icons.settings_rounded,
                            label: l10n.profileSettingsTitle,
                            onTap: onLanguage,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickTile(
                            icon: Icons.refresh_rounded,
                            label: l10n.profileRefreshTooltip,
                            onTap: () {
                              TexiUiFeedback.lightTap();
                              onRefresh();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxx,
              AppSpacing.section,
              AppSpacing.xxx,
              AppSpacing.sheetBodyV,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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

class _ProfileInitialsAvatar extends StatelessWidget {
  const _ProfileInitialsAvatar({
    required this.name,
    required this.size,
  });

  final String name;
  final double size;

  String _initials() {
    String firstChar(String s) {
      final t = s.trim();
      if (t.isEmpty) return '';
      return t.substring(0, 1).toUpperCase();
    }

    final cleaned = name.trim();
    if (cleaned.isEmpty) return 'TX';
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return '${firstChar(parts[0])}${firstChar(parts[1])}';
    }
    if (cleaned.length >= 2) {
      return cleaned.substring(0, 2).toUpperCase();
    }
    return firstChar(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E3A4A),
            Color(0xFF1E2733),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.onPrimary.withValues(alpha: 0.98),
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          TexiUiFeedback.lightTap();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
              ),
            ],
          ),
        ),
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

