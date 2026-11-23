import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../home_quick_slots.dart';
import 'passenger_home_look.dart';

class PassengerHomeQuickTripCardData {
  const PassengerHomeQuickTripCardData({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.configured,
    required this.onTap,
    this.onEdit,
  });

  final HomeQuickSlotKind kind;
  final String title;
  final String subtitle;
  final bool configured;

  final VoidCallback onTap;

  final VoidCallback? onEdit;
}

class PassengerHomeQuickTripsCarousel extends StatelessWidget {
  const PassengerHomeQuickTripsCarousel({super.key, required this.cards});

  final List<PassengerHomeQuickTripCardData> cards;

  static const double overflow = 64;
  static const double cardBody = 186;
  static const double iconSize = 128;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width * 0.48).clamp(164.0, 196.0);

    return SizedBox(
      height: overflow + cardBody,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: AppSpacing.xxx),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xl),
        itemBuilder: (context, i) {
          return SizedBox(
            width: cardWidth,
            height: (overflow - 6) + cardBody,
            child: _QuickTripCard(data: cards[i]),
          );
        },
      ),
    );
  }
}

class _QuickTripCard extends StatelessWidget {
  const _QuickTripCard({required this.data});

  final PassengerHomeQuickTripCardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configurable = HomeQuickSlots.isConfigurable(data.kind);
    final showAdd = configurable && !data.configured;
    final showEdit = configurable && data.configured && data.onEdit != null;
    const iconSize = PassengerHomeQuickTripsCarousel.iconSize;
    const overflow = PassengerHomeQuickTripsCarousel.overflow;
    const lift = overflow - 6;
    const badgeTop = lift - overflow + 10;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: lift,
          left: 0,
          right: 0,
          bottom: 0,
          child: TexiScalePress(
            minScale: 0.97,
            child: Material(
              color: Colors.transparent,
              clipBehavior: Clip.none,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  data.onTap();
                },
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              PassengerHomeLook.quickCardLift,
                              PassengerHomeLook.quickCard,
                            ],
                          ),
                          border: Border.all(
                            color: PassengerHomeLook.quickBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.32),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -overflow + 6,
                      left: 4,
                      right: 4,
                      child: SizedBox(
                        height: iconSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              bottom: 8,
                              child: Container(
                                width: 78,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.32),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                              ),
                            ),
                            Image.asset(
                              _assetFor(data.kind),
                              height: iconSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 48, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
                            Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: PassengerHomeLook.ink,
                                    height: 1.15,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              data.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: PassengerHomeLook.muted,
                                    height: 1.2,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                              ),
                              child: Text(
                                l10n.homeRequestNow,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showAdd)
          Positioned(
            top: badgeTop,
            right: 12,
            child: _SlotBadge(icon: Icons.add, onPressed: data.onTap),
          ),
        if (showEdit)
          Positioned(
            top: badgeTop,
            right: 12,
            child: _SlotBadge(
              icon: Icons.edit_outlined,
              label: l10n.homeQuickPlaceEdit,
              onPressed: data.onEdit,
            ),
          ),
      ],
    );
  }

  String _assetFor(HomeQuickSlotKind kind) {
    switch (kind) {
      case HomeQuickSlotKind.airport:
        return AppAssets.quickTripAirport;
      case HomeQuickSlotKind.work:
        return AppAssets.quickTripWork;
      case HomeQuickSlotKind.home:
        return AppAssets.quickTripHome;
      case HomeQuickSlotKind.favorite:
        return AppAssets.quickTripFavorite;
    }
  }
}

class _SlotBadge extends StatelessWidget {
  const _SlotBadge({required this.icon, this.label, this.onPressed});

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disk = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: Colors.black, size: 16),
    );
    if (onPressed == null) return disk;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed!();
          },
          child: disk,
        ),
      ),
    );
  }
}
