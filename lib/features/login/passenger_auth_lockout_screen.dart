import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/passenger_app_environment.dart';
import '../../core/storage/passenger_auth_lockout_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../gen_l10n/app_localizations.dart';
import 'login_controller.dart';
import 'models/passenger_auth_lockout.dart';
import 'utils/passenger_auth_lockout_time_formatter.dart';
import 'widgets/passenger_auth_shell.dart';

class PassengerAuthLockoutScreen extends ConsumerStatefulWidget {
  const PassengerAuthLockoutScreen({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
    this.initialLockout,
  });

  final String countryCode;
  final String phoneNumber;
  final PassengerAuthLockout? initialLockout;

  @override
  ConsumerState<PassengerAuthLockoutScreen> createState() =>
      _PassengerAuthLockoutScreenState();
}

class _PassengerAuthLockoutScreenState
    extends ConsumerState<PassengerAuthLockoutScreen> {
  PassengerAuthLockout? _lockout;
  Timer? _timer;
  bool _waLoading = false;

  @override
  void initState() {
    super.initState();
    _lockout = widget.initialLockout;
    unawaited(_hydrateLockout());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _hydrateLockout() async {
    final stored = await PassengerAuthLockoutStorage.readActive();
    if (!mounted) return;
    if (stored != null) {
      setState(() => _lockout = stored);
      return;
    }
    if (_lockout != null && _lockout!.isActive) {
      await PassengerAuthLockoutStorage.save(_lockout!);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final lockout = _lockout;
      if (lockout == null || !lockout.isActive) {
        unawaited(_onLockoutExpired());
        return;
      }
      setState(() {});
    });
  }

  Future<void> _onLockoutExpired() async {
    _timer?.cancel();
    await PassengerAuthLockoutStorage.clear();
    if (!mounted) return;
    context.goNamed(
      'login',
      queryParameters: {
        'cc': widget.countryCode,
        'phone': widget.phoneNumber,
      },
    );
  }

  String get _fullPhone {
    final cc = widget.countryCode.trim();
    final digits = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final ccDigits = cc.replaceAll(RegExp(r'[^\d]'), '');
    if (cc.startsWith('+')) return '$cc$digits';
    return '+$ccDigits$digits';
  }

  Future<void> _tryWhatsAppInbound() async {
    if (_waLoading || _lockout == null) return;
    setState(() => _waLoading = true);
    final next = await ref.read(loginControllerProvider.notifier).login(
          countryCode: widget.countryCode,
          phoneNumber: widget.phoneNumber,
          fullPhone: _fullPhone,
          otpChannel: 'whatsapp_inbound',
        );
    if (!mounted) return;
    setState(() => _waLoading = false);
    if (next == LoginNextStep.verifyCode) {
      await PassengerAuthLockoutStorage.clear();
      final loginState = ref.read(loginControllerProvider);
      if (!mounted) return;
      context.goNamed(
        'verify_code',
        queryParameters: {
          'cc': widget.countryCode,
          'phone': widget.phoneNumber,
          'channel': loginState.verificationChannel ?? 'whatsapp_inbound',
          if (loginState.challengeId != null &&
              loginState.challengeId!.isNotEmpty)
            'challenge_id': loginState.challengeId!,
          if (loginState.waDeepLink != null &&
              loginState.waDeepLink!.isNotEmpty)
            'wa_deep_link': loginState.waDeepLink!,
        },
      );
      return;
    }
    if (next == LoginNextStep.authLockout) {
      final updated = ref.read(loginControllerProvider).authLockout;
      if (updated != null) {
        setState(() => _lockout = updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lockout = _lockout;
    final remaining = lockout?.remainingSec ?? 0;
    final tier = lockout?.lockTier ?? 1;
    final countdown = PassengerAuthLockoutTimeFormatter.format(
      remainingSec: remaining,
      lockTier: tier,
    );
    final secondsHint = PassengerAuthLockoutTimeFormatter.unitHint(
      lockTier: tier,
      secondsLabel: l10n.authLockoutSecondsUnit,
    );
    final showWa = lockout?.canTryWhatsAppInbound == true &&
        PassengerAppEnvironment.multichannelAuthEnabled;

    return PassengerAuthShell(
      loading: _waLoading,
      loadingMessage: l10n.loginVerifyMethodLoadingWa,
      leading: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: l10n.loginBackToMethods,
          onPressed: () => context.goNamed('login'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 52,
            color: AppColors.primary.withValues(alpha: 0.95),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.authLockoutTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.authLockoutBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(AppRadii.dialog),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    l10n.authLockoutWaitLabel,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        countdown,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: tier <= 1 ? 56 : 40,
                          letterSpacing: tier <= 1 ? -1 : 0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (secondsHint.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          secondsHint,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.85),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showWa) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.authLockoutAlternateHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _waLoading ? null : _tryWhatsAppInbound,
              icon: const Icon(Icons.chat_rounded),
              label: Text(l10n.authLockoutWhatsAppCta),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => context.goNamed('login'),
            child: Text(l10n.loginAttemptsLimitAction),
          ),
        ],
      ),
    );
  }
}
