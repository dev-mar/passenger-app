import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../driver_avatar_premium.dart';

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
                        Text(
                          driverAssignedLabel,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
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
                        formatMoney(
                          estimatedPrice,
                          currencyCode: currencyCode,
                          decimals: 1,
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onShareTrip != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onShareTrip,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(shareTripLabel ?? l10n.tripShareRide),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
            if (onOpenChat != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenChat,
                  icon: unreadChatCount > 0
                      ? _ChatUnreadBell(count: unreadChatCount)
                      : const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(chatLabel ?? l10n.tripSecureChat),
                ),
              ),
            ],
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

class _ChatUnreadBell extends StatelessWidget {
  const _ChatUnreadBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.mark_chat_unread_rounded, size: AppIconSizes.lg),
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
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
