import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/passenger_api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../passenger_phone_link_navigation.dart';

/// Sesión limitada (p. ej. solo email/Google) sin teléfono verificado.
Future<bool> isPassengerEmailOnlyLimitedSession(WidgetRef ref) async {
  try {
    final me = await ref.read(passengerMeProfileServiceProvider).fetchData();
    if (me['phone_verified'] == true) return false;
    final authLevel = me['auth_level']?.toString().trim() ?? 'limited';
    return authLevel == 'limited';
  } catch (_) {
    return true;
  }
}

/// Pantalla flotante cuando un usuario email-only intenta solicitar un viaje.
Future<void> showPassengerPhoneVerificationGateOverlay(
  BuildContext context, {
  String? returnTo,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.tripPhoneGateTitle,
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
    pageBuilder: (ctx, _, _) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _PassengerPhoneVerificationGateCard(
              returnTo: returnTo,
            ),
          ),
        ),
      );
    },
  );
}

class _PassengerPhoneVerificationGateCard extends StatelessWidget {
  const _PassengerPhoneVerificationGateCard({this.returnTo});

  final String? returnTo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.dialog),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppRadii.dialog),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primary.withValues(alpha: 0.92),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.tripPhoneGateTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.tripPhoneGateBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.94),
                    height: 1.48,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TexiScalePress(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        navigateToPassengerPhoneLink(
                          context,
                          returnTo: returnTo,
                        );
                      },
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor:
                            AppColors.textPrimary.withValues(alpha: 0.94),
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        l10n.tripPhoneGatePrimaryAction,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.tripPhoneGateDismiss,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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
