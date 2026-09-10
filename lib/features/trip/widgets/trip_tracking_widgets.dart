import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/ui/texi_motion.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../driver_avatar_premium.dart';
import '../passenger_pickup_wait.dart';
import '../passenger_trip_live_eta.dart';
import 'passenger_trip_active_addons.dart';

export 'passenger_trip_searching_overlay.dart' show TripSearchingDriverOverlay;

class TripConnectionErrorOverlay extends StatelessWidget {
  const TripConnectionErrorOverlay({
    super.key,
    required this.message,
    required this.onRetry,
    this.onCancel,
    required this.retryLabel,
    this.cancelLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onCancel;
  final String retryLabel;
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.sheetH,
          AppSpacing.md,
          AppSpacing.sheetH,
          AppSpacing.sheetH,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sheetV,
          vertical: AppSpacing.sheetV,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.dialog),
          boxShadow: AppShadows.overlayRaised,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: AppIconSizes.sheet,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: AppSpacing.xxx),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sheetV),
            Row(
              children: [
                if (onCancel != null &&
                    cancelLabel != null &&
                    cancelLabel!.trim().isNotEmpty) ...[
                  Expanded(
                    child: TexiScalePress(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        child: Text(cancelLabel!),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                ],
                Expanded(
                  child: TexiScalePress(
                    child: FilledButton(
                      onPressed: onRetry,
                      child: Text(retryLabel),
                    ),
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

class TripStatusCard extends StatelessWidget {
  const TripStatusCard({
    super.key,
    required this.status,
    required this.statusLabel,
    this.driverName,
    this.driverPhotoUrl,
    this.driverRating,
    this.showAvatarRefreshingRing = false,
    this.carColor,
    this.carPlate,
    this.carModel,
    required this.originLabel,
    required this.destinationLabel,
    required this.durationMinutes,
    required this.distanceKm,
    required this.estimatedPrice,
    this.currencyCode,
    required this.statusFromLabel,
    required this.statusToLabel,
    required this.driverAssignedLabel,
    required this.statusMinutesLabel,
    required this.statusKmLabel,
    this.onFinishedClose,
    this.finishedCloseLabel,
    this.onShareTrip,
    this.shareTripLabel,
    this.onOpenChat,
    this.chatLabel,
    this.unreadChatCount = 0,
    this.paymentMethod,
    this.tripExtras = const [],
    this.tripSpecials = const [],
    this.driverLat,
    this.driverLng,
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
    this.pickupWaitSpec,
    this.onPassengerEnRoute,
    this.passengerEnRouteConnected = false,
    this.enRouteCooldownUntilMs,
    this.enRouteErrorCode,
    this.onCancelTrip,
    this.cancelTripLabel,
    this.showCancelAction = false,
    this.promoPayDriverAmount,
  });

  final String status;
  final String statusLabel;
  final String? driverName;
  final String? driverPhotoUrl;
  final double? driverRating;
  final bool showAvatarRefreshingRing;
  final String? carColor;
  final String? carPlate;
  final String? carModel;
  final String originLabel;
  final String destinationLabel;
  final int durationMinutes;
  final double distanceKm;
  final double estimatedPrice;
  final String? currencyCode;
  final String statusFromLabel;
  final String statusToLabel;
  final String driverAssignedLabel;
  final String Function(int) statusMinutesLabel;
  final String Function(String) statusKmLabel;

  /// Al completar el viaje: permite salir del panel y volver a pedir otro viaje.
  final VoidCallback? onFinishedClose;
  final String? finishedCloseLabel;
  final VoidCallback? onShareTrip;
  final String? shareTripLabel;
  final VoidCallback? onOpenChat;
  final String? chatLabel;
  final int unreadChatCount;
  final String? paymentMethod;
  final List<String> tripExtras;
  final List<String> tripSpecials;
  final double? driverLat;
  final double? driverLng;
  final double? pickupLat;
  final double? pickupLng;
  final double? destLat;
  final double? destLng;
  final TripPickupWaitSpec? pickupWaitSpec;
  final VoidCallback? onPassengerEnRoute;
  final bool passengerEnRouteConnected;
  final int? enRouteCooldownUntilMs;
  final String? enRouteErrorCode;
  final VoidCallback? onCancelTrip;
  final String? cancelTripLabel;
  /// Visible solo con el sheet del viaje a tope (gesto de arrastre).
  final bool showCancelAction;

  /// Monto ya formateado (`Bs 12.5`) si el viaje activo tiene beneficio.
  final String? promoPayDriverAmount;

  /// Si el backend envía hex (#RRGGBB) mostramos punto de color; si no, solo texto.
  Color? _carColorDotColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var s = raw.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length != 6) return null;
    try {
      return Color(int.parse('FF$s', radix: 16));
    } catch (_) {
      return null;
    }
  }

  IconData _statusIcon() {
    switch (status) {
      case 'accepted':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.location_on_rounded;
      case 'started':
        return Icons.navigation_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  Color _statusAccent() {
    switch (status) {
      case 'accepted':
        return const Color(0xFFFFC107);
      case 'arrived':
        return const Color(0xFF26A69A);
      case 'started':
      case 'in_trip':
        return const Color(0xFF42A5F5);
      case 'completed':
        return const Color(0xFF66BB6A);
      default:
        return AppColors.primary;
    }
  }

  double _statusProgressValue() {
    switch (status) {
      case 'accepted':
        return 0.25;
      case 'arrived':
        return 0.5;
      case 'started':
      case 'in_trip':
        return 0.75;
      case 'completed':
        return 1.0;
      default:
        return 0.2;
    }
  }

  int _statusStepIndex() {
    switch (status) {
      case 'accepted':
        return 0;
      case 'arrived':
        return 1;
      case 'started':
      case 'in_trip':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = _statusAccent();
    final progress = _statusProgressValue();
    final currentStep = _statusStepIndex();
    final hasDriverInfo =
        (driverName != null && driverName!.isNotEmpty) ||
        (driverPhotoUrl != null && driverPhotoUrl!.isNotEmpty) ||
        (carModel != null && carModel!.isNotEmpty) ||
        (carPlate != null && carPlate!.isNotEmpty) ||
        (carColor != null && carColor!.isNotEmpty);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxx,
          AppSpacing.md,
          AppSpacing.xxx,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSizes.dragHandleW,
                height: AppSizes.dragHandleH,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: AppSizes.tileLeading,
                  height: AppSizes.tileLeading,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    _statusIcon(),
                    color: accent,
                    size: AppIconSizes.xl,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                color: accent,
                backgroundColor: AppColors.border.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: List.generate(4, (index) {
                final isActive = index <= currentStep;
                return Expanded(
                  child: Align(
                    alignment: index == 0
                        ? Alignment.centerLeft
                        : index == 3
                        ? Alignment.centerRight
                        : Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: isActive ? 11 : 8,
                      height: isActive ? 11 : 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? accent
                            : AppColors.border.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.border.withValues(alpha: 0.5),
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
            _TripLiveEtaStrip(
              eta: resolvePassengerTripLiveEta(
                status: status,
                driverLat: driverLat,
                driverLng: driverLng,
                pickupLat: pickupLat,
                pickupLng: pickupLng,
                destLat: destLat,
                destLng: destLng,
                quoteDurationMinutes: durationMinutes,
              ),
              accent: accent,
              l10n: l10n,
              shareLabel: onShareTrip != null
                  ? (shareTripLabel ?? l10n.tripShareRide)
                  : null,
              onShare: onShareTrip,
            ),
            if (status == 'arrived' && pickupWaitSpec != null)
              PickupWaitClockStrip(
                spec: pickupWaitSpec!,
                accent: accent,
              ),
            if (status == 'arrived' && onPassengerEnRoute != null)
              PassengerEnRouteCta(
                connected: passengerEnRouteConnected,
                onPressed: onPassengerEnRoute!,
                cooldownUntilMs: enRouteCooldownUntilMs,
                errorCode: enRouteErrorCode,
              ),
            const SizedBox(height: AppSpacing.xxx),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: hasDriverInfo
                  ? Builder(
                      builder: (context) {
                        final resolvedDriverName =
                            (driverName != null && driverName!.isNotEmpty)
                            ? driverName!
                            : driverAssignedLabel;
                        final resolvedModel =
                            (carModel != null && carModel!.trim().isNotEmpty)
                            ? carModel!.trim()
                            : '-';
                        final resolvedPlate =
                            (carPlate != null && carPlate!.trim().isNotEmpty)
                            ? carPlate!.trim()
                            : '-';
                        final resolvedColor =
                            (carColor != null && carColor!.trim().isNotEmpty)
                            ? carColor!.trim()
                            : '-';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                DriverAvatarPremium(
                                  displayName: resolvedDriverName,
                                  photoUrl: driverPhotoUrl,
                                  showRefreshingRing: showAvatarRefreshingRing,
                                  size: 56,
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        resolvedDriverName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: AppIconSizes.md,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            driverRating != null
                                                ? driverRating!.toStringAsFixed(
                                                    1,
                                                  )
                                                : '-',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (onOpenChat != null) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  _TripCircleAction(
                                    icon: Icons.forum_rounded,
                                    tooltip: chatLabel ?? l10n.tripSecureChat,
                                    badgeCount: unreadChatCount,
                                    onPressed: onOpenChat!,
                                    filled: true,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                _VehiclePill(
                                  icon: Icons.directions_car_rounded,
                                  text: resolvedModel,
                                ),
                                _VehiclePill(
                                  icon: Icons.style_rounded,
                                  text: resolvedPlate,
                                ),
                                _VehiclePill(
                                  icon: Icons.palette_rounded,
                                  text: resolvedColor,
                                  colorDot: _carColorDotColor(carColor),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: AppIconSizes.lg,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Text(
                            driverAssignedLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        if (onOpenChat != null)
                          _TripCircleAction(
                            icon: Icons.forum_rounded,
                            tooltip: chatLabel ?? l10n.tripSecureChat,
                            badgeCount: unreadChatCount,
                            onPressed: onOpenChat!,
                            filled: true,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TripDetailRow(
                    icon: Icons.trip_origin_rounded,
                    label: statusFromLabel,
                    value: originLabel,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TripDetailRow(
                    icon: Icons.flag_rounded,
                    label: statusToLabel,
                    value: destinationLabel,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(height: AppBorders.thin),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: AppIconSizes.md,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        statusMinutesLabel(durationMinutes),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Icon(
                        Icons.straighten_rounded,
                        size: AppIconSizes.md,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        statusKmLabel(distanceKm.toStringAsFixed(1)),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatTripMoney(
                          estimatedPrice,
                          currencyCode: currencyCode,
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  if (promoPayDriverAmount != null &&
                      promoPayDriverAmount!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.promoActiveBannerTitle,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  height: 1.1,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${l10n.promoActivePayDriverLead}  ',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        height: 1.25,
                                      ),
                                ),
                                TextSpan(
                                  text: promoPayDriverAmount,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        height: 1.15,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (paymentMethod != null ||
                      tripExtras.isNotEmpty ||
                      tripSpecials.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (paymentMethod != null)
                          PassengerTripPaymentChip(
                            l10n: l10n,
                            paymentMethod: paymentMethod!,
                          ),
                        if (tripExtras.isNotEmpty || tripSpecials.isNotEmpty)
                          PassengerTripAddonsStrip(
                            l10n: l10n,
                            extras: tripExtras,
                            specials: tripSpecials,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AnimatedSize(
              duration: AppMotion.draftSearchChromeReveal,
              curve: AppMotion.standard,
              alignment: Alignment.topCenter,
              child: onCancelTrip != null && showCancelAction
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onCancelTrip,
                          icon: const Icon(Icons.close_rounded),
                          label: Text(cancelTripLabel ?? l10n.tripCancelCta),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            minimumSize: const Size(
                              double.infinity,
                              AppSizes.buttonHeight,
                            ),
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (status == 'completed' &&
                onFinishedClose != null &&
                (finishedCloseLabel != null &&
                    finishedCloseLabel!.isNotEmpty)) ...[
              const SizedBox(height: AppSpacing.xl),
              TexiScalePress(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onFinishedClose,
                    child: Text(finishedCloseLabel!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripCircleAction extends StatelessWidget {
  const _TripCircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badgeCount;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.surface;
    final fg = filled ? AppColors.textPrimary : AppColors.textPrimary;
    return Tooltip(
      message: tooltip,
      child: TexiScalePress(
        child: Material(
          color: bg,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: filled
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : AppColors.border.withValues(alpha: 0.85),
                ),
              ),
              child: SizedBox(
                width: AppSizes.circleButton,
                height: AppSizes.circleButton,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: fg, size: AppIconSizes.xl),
                    if (badgeCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripShareRouteChip extends StatelessWidget {
  const _TripShareRouteChip({
    required this.label,
    required this.onPressed,
    required this.accent,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: TexiScalePress(
        child: Material(
          color: compact
              ? Colors.white.withValues(alpha: 0.72)
              : accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: compact ? 40 : AppSizes.buttonHeight,
                minWidth: compact ? 40 : AppSizes.circleButton,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? AppSpacing.md : AppSpacing.xl,
                  vertical: compact ? AppSpacing.sm : AppSpacing.md,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share_location_rounded,
                      size: compact ? AppIconSizes.md : AppIconSizes.lg,
                      color: accent,
                    ),
                    SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? AppTypography.captionAlt : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehiclePill extends StatelessWidget {
  const _VehiclePill({required this.icon, required this.text, this.colorDot});

  final IconData icon;
  final String text;
  final Color? colorDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSizes.sm, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          if (colorDot != null) ...[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: colorDot,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripLiveEtaStrip extends StatelessWidget {
  const _TripLiveEtaStrip({
    required this.eta,
    required this.accent,
    required this.l10n,
    this.shareLabel,
    this.onShare,
  });

  final PassengerTripLiveEta? eta;
  final Color accent;
  final AppLocalizations l10n;
  final String? shareLabel;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final resolved = eta;
    final share = onShare != null
        ? _TripShareRouteChip(
            label: shareLabel ?? l10n.tripShareRide,
            onPressed: onShare!,
            accent: accent,
            compact: true,
          )
        : null;
    if (resolved == null && share == null) {
      return const SizedBox(height: AppSpacing.xxx);
    }

    final minutes = resolved?.minutes;
    final title = resolved == null
        ? null
        : switch (resolved.kind) {
            PassengerTripLiveEtaKind.pickup =>
              l10n.tripLiveEtaPickup(minutes ?? 1),
            PassengerTripLiveEtaKind.destination =>
              l10n.tripLiveEtaDestination(minutes ?? 1),
            PassengerTripLiveEtaKind.atPickup => l10n.tripLiveEtaAtPickup,
          };

    String? clock;
    if (resolved != null &&
        minutes != null &&
        resolved.kind != PassengerTripLiveEtaKind.atPickup) {
      final when = DateTime.now().add(Duration(minutes: minutes));
      clock = l10n.tripLiveEtaClockHint(
        TimeOfDay.fromDateTime(when).format(context),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: AnimatedContainer(
        duration: TexiMotion.medium,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            if (resolved != null) ...[
              Icon(
                resolved.kind == PassengerTripLiveEtaKind.atPickup
                    ? Icons.location_on_rounded
                    : Icons.schedule_rounded,
                size: AppIconSizes.lg,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if (clock != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        clock,
                        style: TextStyle(
                          fontSize: AppTypography.captionAlt,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else
              const Spacer(),
            if (share != null) ...[
              if (resolved != null) const SizedBox(width: AppSpacing.sm),
              share,
            ],
          ],
        ),
      ),
    );
  }
}

class _TripDetailRow extends StatelessWidget {
  const _TripDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppIconSizes.md, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
