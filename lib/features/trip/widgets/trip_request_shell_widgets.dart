import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'trip_location_panel_widgets.dart';

class TripCircleButton extends StatelessWidget {
  const TripCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        child: SizedBox(
          width: AppSizes.circleButton,
          height: AppSizes.circleButton,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: AppSizes.progressBtn,
                    height: AppSizes.progressBtn,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class TripBottomRequestCardContent extends StatelessWidget {
  const TripBottomRequestCardContent({
    super.key,
    required this.originDisplayText,
    required this.originSubtitle,
    required this.onOriginTap,
    required this.onOriginUseMyLocation,
    required this.onOriginSearch,
    required this.onOriginPickOnMap,
    required this.destinationLabel,
    this.destinationDisplayText,
    required this.destinationPlaceholder,
    required this.loadingRoute,
    required this.loadingQuote,
    this.error,
    required this.routeHint,
    required this.isPickingOrigin,
    required this.isPickingDestination,
    required this.expandOrigin,
    required this.expandDestination,
    required this.useMapCenterLabel,
    required this.useAsPickupLabel,
    required this.useAsDestinationLabel,
    required this.seePricesLabel,
    required this.onUseMapCenter,
    required this.onSetOriginFromMap,
    required this.onSetDestinationFromMap,
    required this.onDestinationTap,
    required this.onDestinationUseMyLocation,
    required this.onDestinationSearch,
    required this.onDestinationPickOnMap,
    this.onSeePrices,
    required this.onPickOriginSaved,
    required this.onPickOriginRecent,
    required this.onPickDestinationSaved,
    required this.onPickDestinationRecent,
    this.showCancelQuoteDraft = false,
    this.cancelQuoteDraftLabel,
    this.onCancelQuoteDraft,
  });

  final String originDisplayText;
  final String originSubtitle;
  final VoidCallback onOriginTap;
  final VoidCallback onOriginUseMyLocation;
  final VoidCallback onOriginSearch;
  final VoidCallback onOriginPickOnMap;
  final String destinationLabel;
  final String? destinationDisplayText;
  final String destinationPlaceholder;
  final bool loadingRoute;
  final bool loadingQuote;
  final String? error;
  final String routeHint;
  final bool isPickingOrigin;
  final bool isPickingDestination;
  final bool expandOrigin;
  final bool expandDestination;
  final String useMapCenterLabel;
  final String useAsPickupLabel;
  final String useAsDestinationLabel;
  final String seePricesLabel;
  final VoidCallback onUseMapCenter;
  final VoidCallback onSetOriginFromMap;
  final VoidCallback onSetDestinationFromMap;
  final VoidCallback onDestinationTap;
  final VoidCallback onDestinationUseMyLocation;
  final VoidCallback onDestinationSearch;
  final VoidCallback onDestinationPickOnMap;
  final VoidCallback? onSeePrices;
  final ValueChanged<String> onPickOriginSaved;
  final ValueChanged<String> onPickOriginRecent;
  final ValueChanged<String> onPickDestinationSaved;
  final ValueChanged<String> onPickDestinationRecent;
  final bool showCancelQuoteDraft;
  final String? cancelQuoteDraftLabel;
  final VoidCallback? onCancelQuoteDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDestination = destinationDisplayText != null && destinationDisplayText!.isNotEmpty;
    final destText = destinationDisplayText ?? destinationPlaceholder;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xxx, AppSpacing.lg, AppSpacing.xxx, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: AppSizes.iconButtonMin,
                  child: showCancelQuoteDraft && onCancelQuoteDraft != null
                      ? IconButton(
                          tooltip: cancelQuoteDraftLabel,
                          onPressed: onCancelQuoteDraft,
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: AppSizes.iconButtonMin,
                            minHeight: AppSizes.iconButtonMin,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: AppSizes.dragHandleW,
                      height: AppSizes.dragHandleH,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.iconButtonMin),
              ],
            ),
            TripStopRow(
              icon: Icons.trip_origin_rounded,
              label: originSubtitle,
              value: originDisplayText,
              isOrigin: true,
              onTap: onOriginTap,
            ),
            if (expandOrigin) ...[
              const SizedBox(height: AppSpacing.md),
              TripQuickPickRow(
                onGps: onOriginUseMyLocation,
                onSearch: onOriginSearch,
                onMap: onOriginPickOnMap,
              ),
              ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.profileSavedPlaces,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    TripQuickActionChip(
                      icon: Icons.home_rounded,
                      label: l10n.placeHome,
                      onTap: () => onPickOriginSaved(l10n.placeHome),
                    ),
                    TripQuickActionChip(
                      icon: Icons.apartment_rounded,
                      label: l10n.placeOffice,
                      onTap: () => onPickOriginSaved(l10n.placeOffice),
                    ),
                    TripQuickActionChip(
                      icon: Icons.star_rounded,
                      label: l10n.placeFavorite,
                      onTap: () => onPickOriginSaved(l10n.placeFavorite),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.profileRecentPlaces,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TripRecentDestinationTile(
                  title: l10n.placeMainSquare,
                  subtitle: l10n.placeDowntown,
                  onTap: () => onPickOriginRecent(l10n.placeMainSquare),
                ),
                TripRecentDestinationTile(
                  title: l10n.placeAirport,
                  subtitle: l10n.placeNorthZone,
                  onTap: () => onPickOriginRecent(l10n.placeAirport),
                ),
              ],
            ],
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xxxx),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSizes.stopConnectorDot,
                    height: AppSizes.stopConnectorDot,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadii.micro),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: AppBorders.thin,
                    height: AppSizes.connectorLineHeight,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppBorders.thin),
                    ),
                  ),
                ],
              ),
            ),
            TripStopRow(
              icon: Icons.location_on_rounded,
              label: destinationLabel,
              value: destText,
              isOrigin: false,
              dimmed: !hasDestination,
              onTap: onDestinationTap,
            ),
            if (expandDestination) ...[
              const SizedBox(height: AppSpacing.md),
              TripQuickPickRow(
                onGps: onDestinationUseMyLocation,
                onSearch: onDestinationSearch,
                onMap: onDestinationPickOnMap,
              ),
              ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.profileSavedPlaces,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    TripQuickActionChip(
                      icon: Icons.home_rounded,
                      label: l10n.placeHome,
                      onTap: () => onPickDestinationSaved(l10n.placeHome),
                    ),
                    TripQuickActionChip(
                      icon: Icons.apartment_rounded,
                      label: l10n.placeOffice,
                      onTap: () => onPickDestinationSaved(l10n.placeOffice),
                    ),
                    TripQuickActionChip(
                      icon: Icons.star_rounded,
                      label: l10n.placeFavorite,
                      onTap: () => onPickDestinationSaved(l10n.placeFavorite),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.profileRecentPlaces,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TripRecentDestinationTile(
                  title: l10n.placeMainSquare,
                  subtitle: l10n.placeDowntown,
                  onTap: () => onPickDestinationRecent(l10n.placeMainSquare),
                ),
                TripRecentDestinationTile(
                  title: l10n.placeAirport,
                  subtitle: l10n.placeNorthZone,
                  onTap: () => onPickDestinationRecent(l10n.placeAirport),
                ),
              ],
            ],
            if (loadingRoute) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const SizedBox(
                    width: AppSizes.progressSm,
                    height: AppSizes.progressSm,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    routeHint,
                    style: const TextStyle(
                      fontSize: AppTypography.captionAlt,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: AppTypography.bodySmall,
                  ),
                ),
              ),
            ],
            if (!isPickingOrigin && !isPickingDestination) ...[
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: AppSizes.buttonHeight,
                width: double.infinity,
                child: TexiScalePress(
                  child: FilledButton(
                    onPressed: onSeePrices == null || loadingQuote ? null : onSeePrices,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    ),
                    child: loadingQuote
                        ? const SizedBox(
                            height: AppSizes.progressBtn,
                            width: AppSizes.progressBtn,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(
                            seePricesLabel,
                            style: const TextStyle(
                              fontSize: AppTypography.title,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
