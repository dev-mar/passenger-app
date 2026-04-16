import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';

class TripQuickPickRow extends StatelessWidget {
  const TripQuickPickRow({
    super.key,
    required this.onGps,
    required this.onSearch,
    required this.onMap,
    this.onSavedPlaces,
    this.gpsLabel,
    this.searchLabel,
    this.mapLabel,
    this.savedPlacesLabel,
  });

  final VoidCallback onGps;
  final VoidCallback onSearch;
  final VoidCallback onMap;
  final VoidCallback? onSavedPlaces;
  final String? gpsLabel;
  final String? searchLabel;
  final String? mapLabel;
  final String? savedPlacesLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        );

    final items = <Widget>[
      TripQuickActionChip(
        icon: Icons.my_location_rounded,
        label: gpsLabel ?? l10n.quickGps,
        onTap: onGps,
        textStyle: textStyle,
      ),
      TripQuickActionChip(
        icon: Icons.search_rounded,
        label: searchLabel ?? l10n.quickSearch,
        onTap: onSearch,
        textStyle: textStyle,
      ),
      TripQuickActionChip(
        icon: Icons.map_rounded,
        label: mapLabel ?? l10n.quickMap,
        onTap: onMap,
        textStyle: textStyle,
      ),
      if (onSavedPlaces != null)
        TripQuickActionChip(
          icon: Icons.bookmark_rounded,
          label: savedPlacesLabel ?? l10n.profileSavedPlaces,
          onTap: onSavedPlaces!,
          textStyle: textStyle,
        ),
    ];

    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => items[i],
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 18,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 18,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface.withValues(alpha: 0),
                      AppColors.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TripQuickActionChip extends StatelessWidget {
  const TripQuickActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.textStyle,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSizes.sm, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class TripRecentDestinationTile extends StatelessWidget {
  const TripRecentDestinationTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history_rounded, size: AppIconSizes.lg, color: AppColors.textSecondary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      onTap: onTap,
    );
  }
}

class TripStopRow extends StatelessWidget {
  const TripStopRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isOrigin,
    this.dimmed = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isOrigin;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.stopRowBubble,
          height: AppSizes.stopRowBubble,
          decoration: BoxDecoration(
            color: isOrigin ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.6),
              width: AppBorders.emphasis,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: AppIconSizes.md, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppTypography.caption,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  color: dimmed ? AppColors.textSecondary : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            size: AppIconSizes.xl,
          ),
      ],
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
            child: content,
          ),
        ),
      );
    }
    return content;
  }
}
