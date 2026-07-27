import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_safe_scrolling.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../trip_request_trip_phase_helpers.dart';
import 'trip_tracking_widgets.dart';

/// Chip superior con el estado del viaje activo.
class PassengerTripActiveStatusChip extends StatelessWidget {
  const PassengerTripActiveStatusChip({
    super.key,
    required this.status,
    required this.statusLabel,
  });

  final String status;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 10,
      right: 72,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Material(
            color: AppColors.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 18,
                    color: passengerTripActiveRouteColor(status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// FAB flotante con badge de mensajes no leídos del chat del viaje.
class PassengerTripChatUnreadFab extends StatelessWidget {
  const PassengerTripChatUnreadFab({
    super.key,
    required this.unreadCount,
    required this.attentionT,
    required this.onTap,
  });

  final int unreadCount;
  final double attentionT;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 112,
      right: 14,
      child: SafeArea(
        bottom: false,
        child: Transform.scale(
          scale: 1 + (attentionT * 0.06),
          child: Material(
            color: AppColors.surface,
            elevation: 4,
            shadowColor: AppColors.primary.withValues(
              alpha: 0.22 + (attentionT * 0.2),
            ),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.mark_chat_unread_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    Positioned(
                      right: 4,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
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

/// Banner inferior mientras se rehidrata un viaje activo desde storage/API.
class PassengerTripRecoveringBanner extends StatelessWidget {
  const PassengerTripRecoveringBanner({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16 + AppSafeScrolling.systemNavBottom(context),
      child: Material(
        color: AppColors.surface,
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel deslizable del viaje activo (estado, conductor, chat).
class PassengerTripActiveTrackingSheet extends StatelessWidget {
  const PassengerTripActiveTrackingSheet({
    super.key,
    required this.status,
    required this.statusLabel,
    required this.driverName,
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
    required this.l10n,
    this.onFinishedClose,
    this.onOpenChat,
    this.unreadChatCount = 0,
  });

  final String status;
  final String statusLabel;
  final String driverName;
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
  final AppLocalizations l10n;
  final VoidCallback? onFinishedClose;
  final VoidCallback? onOpenChat;
  final int unreadChatCount;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      top: 0,
      child: DraggableScrollableSheet(
        initialChildSize: 0.34,
        minChildSize: 0.14,
        maxChildSize: 0.72,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              TripStatusCard(
                status: status,
                statusLabel: statusLabel,
                driverName: driverName,
                driverPhotoUrl: driverPhotoUrl,
                driverRating: driverRating,
                showAvatarRefreshingRing: showAvatarRefreshingRing,
                carColor: carColor,
                carPlate: carPlate,
                carModel: carModel,
                originLabel: originLabel,
                destinationLabel: destinationLabel,
                durationMinutes: durationMinutes,
                distanceKm: distanceKm,
                estimatedPrice: estimatedPrice,
                currencyCode: currencyCode,
                statusFromLabel: l10n.tripStatusFrom,
                statusToLabel: l10n.tripStatusTo,
                driverAssignedLabel: l10n.tripStatusDriverAssigned,
                statusMinutesLabel: (int c) => l10n.tripStatusMinutes(c),
                statusKmLabel: (String v) => l10n.tripStatusKm(v),
                onFinishedClose: onFinishedClose,
                finishedCloseLabel: status == 'completed'
                    ? l10n.tripFinishedBackToHome
                    : null,
                onOpenChat: onOpenChat,
                chatLabel: l10n.tripSecureChat,
                unreadChatCount: unreadChatCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
