import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';

const Duration kLoginAttemptsLimitOverlayDuration = Duration(seconds: 5);

/// Alerta semitransparente por bloqueo de intentos; se oculta sola y opcionalmente vuelve a login.
Future<void> showLoginAttemptsLimitDialog(
  BuildContext context, {
  bool navigateToLoginOnDismiss = true,
  Duration visibleFor = kLoginAttemptsLimitOverlayDuration,
}) async {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context, rootNavigator: true);

  unawaited(
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, anim, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _LoginAttemptsLimitCard(
                title: l10n.loginAttemptsLimitTitle,
                body: l10n.loginAttemptsLimitBody,
              ),
            ),
          ),
        );
      },
    ),
  );

  await Future<void>.delayed(visibleFor);
  if (navigator.mounted && navigator.canPop()) {
    navigator.pop();
  }

  if (!context.mounted || !navigateToLoginOnDismiss) return;
  context.goNamed('login');
}

class _LoginAttemptsLimitCard extends StatelessWidget {
  const _LoginAttemptsLimitCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.dialog),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadii.dialog),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
