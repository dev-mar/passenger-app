import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/trips_api.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'passenger_home_look.dart';

class PassengerHomeRecentList extends StatelessWidget {
  const PassengerHomeRecentList({
    super.key,
    required this.places,
    required this.onTap,
  });

  final List<PassengerRecentPlace> places;
  final void Function(PassengerRecentPlace place) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (var i = 0; i < places.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _RecentRow(
            place: places[i],
            alt: i.isOdd,
            fallbackSubtitle: l10n.homePlaceTapToRide,
            onTap: () {
              HapticFeedback.lightImpact();
              onTap(places[i]);
            },
          ),
        ],
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.place,
    required this.alt,
    required this.fallbackSubtitle,
    required this.onTap,
  });

  final PassengerRecentPlace place;
  final bool alt;
  final String fallbackSubtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = place.subtitle?.trim();
    return TexiScalePress(
      minScale: 0.98,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg + 2),
          child: Ink(
            decoration: BoxDecoration(
              color: alt
                  ? PassengerHomeLook.recentCardAlt
                  : PassengerHomeLook.recentCard,
              borderRadius: BorderRadius.circular(AppRadii.lg + 2),
              border: Border.all(
                color: PassengerHomeLook.recentAccent.withValues(
                  alpha: alt ? 0.22 : 0.12,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: PassengerHomeLook.recentAccent.withValues(
                        alpha: 0.16,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: PassengerHomeLook.recentAccent,
                      size: AppIconSizes.xl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: PassengerHomeLook.ink,
                              ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PassengerHomeLook.muted,
                                ),
                          ),
                        ] else ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            fallbackSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PassengerHomeLook.muted,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.north_east_rounded,
                    color: PassengerHomeLook.recentAccent,
                    size: AppIconSizes.lg,
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
