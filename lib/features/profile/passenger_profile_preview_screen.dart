import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/locale_provider.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../core/network/passenger_api_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../gen_l10n/app_localizations.dart';
import 'passenger_profile_models.dart';
import 'widgets/passenger_profile_edit_sheet.dart';
import 'widgets/passenger_profile_legal_section.dart';

part 'passenger_profile_preview_screen.body.dart';

/// Perfil pasajero: `GET /api/v2/auth/me` (foto firmada si aplica).
class PassengerProfilePreviewScreen extends ConsumerStatefulWidget {
  const PassengerProfilePreviewScreen({super.key});

  @override
  ConsumerState<PassengerProfilePreviewScreen> createState() =>
      _PassengerProfilePreviewScreenState();
}

class _PassengerProfilePreviewScreenState
    extends ConsumerState<PassengerProfilePreviewScreen> {
  late Future<PassengerProfileVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PassengerProfileVm> _load({bool forceRefresh = false}) {
    return ref
        .read(passengerProfileRepositoryProvider)
        .fetchProfile(forceRefresh: forceRefresh);
  }

  Future<void> _reload() async {
    TexiUiFeedback.lightTap();
    setState(() => _future = _load(forceRefresh: true));
    await _future;
  }

  Future<void> _openEditProfile(PassengerProfileVm profile) async {
    final saved = await showPassengerProfileEditSheet(
      context: context,
      ref: ref,
      profile: profile,
    );
    if (saved && mounted) await _reload();
  }

  Future<void> _openSupportCenter() async {
    if (!mounted) return;
    context.pushNamed(AppRouter.supportHelp);
  }

  void _openSettingsSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.profileSettingsTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  l10n.settingsLanguage,
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.translate, color: AppColors.primary),
                title: Text(l10n.languageSpanish),
                onTap: () {
                  ProviderScope.containerOf(
                    ctx,
                    listen: false,
                  ).read(localeProvider.notifier).state = const Locale('es');
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate, color: AppColors.primary),
                title: Text(l10n.languageEnglish),
                onTap: () {
                  ProviderScope.containerOf(
                    ctx,
                    listen: false,
                  ).read(localeProvider.notifier).state = const Locale('en');
                },
              ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.profileSectionPreferences,
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: _PreferencesCard(l10n: l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _close() {
    TexiUiFeedback.lightTap();
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRouter.home);
    }
  }

  String _errMsg(Object? e, AppLocalizations l10n) {
    if (e == PassengerProfileLoadError.noSession) {
      return l10n.profileErrorNoSession;
    }
    if (e == PassengerProfileLoadError.empty ||
        e == PassengerProfileLoadError.badFormat) {
      return l10n.profileErrorBody;
    }
    if (e is PassengerProfileApiException) {
      final ac = e.apiCode;
      if (ac != null && ac.startsWith('RBAC_')) {
        return localizedTripApiError(
          l10n,
          ac,
          fallbackMessage:
              e.message.isNotEmpty && e.message != 'profile' ? e.message : null,
        );
      }
      switch (e.apiCode) {
        case 'PASS_AUTH_FORBIDDEN':
        case 'FORBIDDEN':
          return l10n.profileErrorForbidden;
        case 'PASS_USER_NOT_FOUND':
        case 'NOT_FOUND':
          return l10n.profileErrorNotFound;
        case 'PASS_AUTH_INVALID':
        case 'UNAUTHORIZED':
          return l10n.profileErrorNoSession;
      }
      if (e.message.isNotEmpty && e.message != 'profile') {
        return e.message;
      }
    }
    return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<PassengerProfileVm>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _LoadingState(onClose: _close);
          }
          if (snap.hasError) {
            return _ErrorState(
              message: _errMsg(snap.error, l10n),
              onRetry: _reload,
              onClose: _close,
              l10n: l10n,
            );
          }
          return _ProfileBody(
            profile: snap.data!,
            l10n: l10n,
            onRefresh: _reload,
            onEditInfo: () => _openEditProfile(snap.data!),
            onSupport: _openSupportCenter,
            onLanguage: _openSettingsSheet,
          );
        },
      ),
    );
  }
}
