import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_service.dart';
import '../../core/constants/app_assets.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/network/trips_api.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../gen_l10n/app_localizations.dart';
import '../trip/passenger_realtime_controller.dart';
import '../trip/trip_request_state.dart';
import '../trip/trip_request_trip_phase_helpers.dart';
import '../trip/widgets/passenger_trip_toast.dart';
import 'widgets/passenger_verified_drivers_panel.dart';

/// Hub Seguridad: logo escudo + grid 2×2 (mockup `vista-seguridad.png`).
class PassengerSafetyHubScreen extends ConsumerWidget {
  const PassengerSafetyHubScreen({super.key});

  static const _gold = Color(0xFFD4AF37);
  static const _tileBg = Color(0xFF0A0A0A);

  bool _liveTrackingEnabled(String? status) =>
      passengerTripIsEnRouteToDestination(status);

  Future<void> _shareLiveTrip(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final tripId = ref.read(tripRequestProvider).tripId;
    final rt = ref.read(passengerRealtimeProvider);
    if (tripId == null || tripId.isEmpty) {
      PassengerTripToast.show(
        context,
        message: l10n.safetyLiveTrackingUnavailable,
        icon: Icons.share_location_rounded,
      );
      return;
    }
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) {
      if (context.mounted) {
        PassengerTripToast.show(
          context,
          message: l10n.tripShareError,
          icon: Icons.error_outline_rounded,
          accent: AppColors.error,
        );
      }
      return;
    }
    try {
      final link = await TripsApi(token: token).createOrReuseTripShareLink(
        tripId: tripId,
      );
      if (!context.mounted) return;
      if (link.shareUrl.isEmpty) {
        PassengerTripToast.show(
          context,
          message: l10n.tripShareError,
          icon: Icons.error_outline_rounded,
          accent: AppColors.error,
        );
        return;
      }
      final who = (rt.driverName ?? '').trim().isEmpty
          ? l10n.tripDriverNameFallback
          : rt.driverName!.trim();
      final plate = (rt.carPlate ?? '').trim().isEmpty
          ? l10n.commonEmptyDash
          : rt.carPlate!.trim();
      final message = l10n.tripShareMessage(link.shareUrl, who, plate);
      await SharePlus.instance.share(ShareParams(text: message));
    } catch (_) {
      if (context.mounted) {
        PassengerTripToast.show(
          context,
          message: l10n.tripShareError,
          icon: Icons.error_outline_rounded,
          accent: AppColors.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(passengerRealtimeProvider).status;
    final liveOk = _liveTrackingEnabled(status);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  TexiUiFeedback.lightTap();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.goNamed(AppRouter.home);
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
                color: _gold,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: Image.asset(
                          AppAssets.safetyShieldLogo,
                          fit: BoxFit.contain,
                          height: MediaQuery.sizeOf(context).height * 0.28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 6,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final gap = 14.0;
                          final tileW =
                              (constraints.maxWidth - gap) / 2;
                          final tileH =
                              (constraints.maxHeight - gap) / 2;
                          final size = tileW < tileH ? tileW : tileH;
                          return Center(
                            child: SizedBox(
                              width: size * 2 + gap,
                              height: size * 2 + gap,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _SafetyTile(
                                            icon: Icons
                                                .verified_user_outlined,
                                            label: l10n
                                                .operatorVerifiedDriversTitle,
                                            onTap: () {
                                              TexiUiFeedback.lightTap();
                                              context.pushNamed(
                                                AppRouter
                                                    .safetyVerifiedDrivers,
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(width: gap),
                                        Expanded(
                                          child: _SafetyTile(
                                            icon: Icons
                                                .share_location_rounded,
                                            label: l10n
                                                .safetyLiveTrackingTitle,
                                            enabled: liveOk,
                                            onTap: () {
                                              TexiUiFeedback.lightTap();
                                              if (!liveOk) {
                                                PassengerTripToast.show(
                                                  context,
                                                  message: l10n
                                                      .safetyLiveTrackingUnavailable,
                                                  icon: Icons
                                                      .share_location_rounded,
                                                );
                                                return;
                                              }
                                              unawaited(
                                                _shareLiveTrip(
                                                  context,
                                                  ref,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _SafetyTile(
                                            icon: Icons
                                                .notifications_active_outlined,
                                            label:
                                                l10n.safetyEmergencyCta,
                                            onTap: () {
                                              TexiUiFeedback.lightTap();
                                              context.pushNamed(
                                                AppRouter.supportHelp,
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(width: gap),
                                        Expanded(
                                          child: _SafetyTile(
                                            icon: Icons.headset_mic_outlined,
                                            label: l10n.menuOperatorTexi,
                                            onTap: () {
                                              TexiUiFeedback.lightTap();
                                              context.pushNamed(
                                                AppRouter.operatorTexi,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyTile extends StatelessWidget {
  const _SafetyTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final border = enabled
        ? _gold.withValues(alpha: 0.85)
        : _gold.withValues(alpha: 0.28);
    final fg = enabled ? _gold : _gold.withValues(alpha: 0.35);
    final textColor = enabled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: PassengerSafetyHubScreen._tileBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: enabled ? 0.12 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 42, color: fg),
                const SizedBox(height: 14),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.2,
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

/// Lista moderna “cómo TEXI verifica conductores”.
class PassengerVerifiedDriversScreen extends StatelessWidget {
  const PassengerVerifiedDriversScreen({super.key});

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
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
                        context.goNamed(AppRouter.safetyHub);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: _gold,
                  ),
                  Expanded(
                    child: Text(
                      l10n.operatorVerifiedDriversTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Center(
                    child: Image.asset(
                      AppAssets.safetyShieldLogo,
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.operatorVerifiedDriversCtaSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 22),
                  const PassengerVerifiedDriversPanel(compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
