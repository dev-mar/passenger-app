import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../driver_avatar_premium.dart';

class TripSearchingDriverOverlay extends StatefulWidget {
  const TripSearchingDriverOverlay({
    super.key,
    required this.onCancel,
    required this.searchingTitle,
    required this.searchingSubtitle,
    required this.cancelLabel,
  });

  final VoidCallback onCancel;
  final String searchingTitle;
  final String searchingSubtitle;
  final String cancelLabel;

  @override
  State<TripSearchingDriverOverlay> createState() => _TripSearchingDriverOverlayState();
}

class _TripSearchingDriverOverlayState extends State<TripSearchingDriverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppDurations.searchingPulse,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.sheetH,
          AppSpacing.md,
          AppSpacing.sheetH,
          AppSpacing.sheetV,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.section,
          vertical: AppSpacing.sheetBodyV,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.sheetTop),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: AppBorders.thin,
          ),
          boxShadow: AppShadows.overlayFloating,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: AppSizes.searchingRadarArea,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (i) {
                          final t = (_pulseController.value + i * 0.33) % 1.0;
                          final scale = 0.45 + t * 0.55;
                          final opacity = (1 - t) * 0.4;
                          return Container(
                            width: AppSizes.searchingBase * scale,
                            height: AppSizes.searchingBase * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: opacity),
                                width: AppBorders.radarRing,
                              ),
                            ),
                          );
                        }),
                        Container(
                          width: AppSizes.searchingInnerCircle,
                          height: AppSizes.searchingInnerCircle,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: AppSpacing.xl,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            size: AppIconSizes.hero,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sheetV),
            Text(
              widget.searchingTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.searchingSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.section),
            SizedBox(
              width: double.infinity,
              child: TexiScalePress(
                minScale: 0.98,
                child: TextButton(
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  ),
                  child: Text(widget.cancelLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TripConnectionErrorOverlay extends StatelessWidget {
  const TripConnectionErrorOverlay({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onCancel,
    required this.retryLabel,
    required this.cancelLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  final String retryLabel;
  final String cancelLabel;

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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sheetV),
            Row(
              children: [
                Expanded(
                  child: TexiScalePress(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: Text(cancelLabel),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
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
    this.showAvatarRefreshingRing = false,
    this.carColor,
    this.carPlate,
    this.carModel,
    required this.originLabel,
    required this.destinationLabel,
    required this.durationMinutes,
    required this.distanceKm,
    required this.estimatedPrice,
    required this.statusFromLabel,
    required this.statusToLabel,
    required this.driverAssignedLabel,
    required this.statusMinutesLabel,
    required this.statusKmLabel,
    this.onFinishedClose,
    this.finishedCloseLabel,
  });

  final String status;
  final String statusLabel;
  final String? driverName;
  final String? driverPhotoUrl;
  final bool showAvatarRefreshingRing;
  final String? carColor;
  final String? carPlate;
  final String? carModel;
  final String originLabel;
  final String destinationLabel;
  final int durationMinutes;
  final double distanceKm;
  final double estimatedPrice;
  final String statusFromLabel;
  final String statusToLabel;
  final String driverAssignedLabel;
  final String Function(int) statusMinutesLabel;
  final String Function(String) statusKmLabel;
  /// Al completar el viaje: permite salir del panel y volver a pedir otro viaje.
  final VoidCallback? onFinishedClose;
  final String? finishedCloseLabel;

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

  @override
  Widget build(BuildContext context) {
    final hasDriverInfo = (driverName != null && driverName!.isNotEmpty) ||
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
                    color: status == 'completed'
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    _statusIcon(),
                    color: AppColors.primary,
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
              ],
            ),
            const SizedBox(height: AppSpacing.xxx),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: hasDriverInfo
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((driverName != null && driverName!.isNotEmpty) ||
                            (driverPhotoUrl != null && driverPhotoUrl!.isNotEmpty))
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              DriverAvatarPremium(
                                displayName: driverName ?? '',
                                photoUrl: driverPhotoUrl,
                                showRefreshingRing: showAvatarRefreshingRing,
                                size: AppSizes.avatarTripStatus,
                              ),
                              const SizedBox(width: AppSpacing.xxl),
                              Expanded(
                                child: Text(
                                  (driverName != null && driverName!.isNotEmpty)
                                      ? driverName!
                                      : driverAssignedLabel,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        if (carModel != null || carColor != null || carPlate != null) ...[
                          if ((driverName != null && driverName!.isNotEmpty) ||
                              (driverPhotoUrl != null && driverPhotoUrl!.isNotEmpty))
                            const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car_rounded,
                                size: AppIconSizes.md,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  [
                                    if (carColor != null && carColor!.isNotEmpty) carColor,
                                    if (carModel != null && carModel!.isNotEmpty) carModel,
                                    if (carPlate != null && carPlate!.isNotEmpty) carPlate,
                                  ].join(' · '),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
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
                        'Bs ${estimatedPrice.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (status == 'completed' &&
                onFinishedClose != null &&
                (finishedCloseLabel != null && finishedCloseLabel!.isNotEmpty)) ...[
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
