import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import 'passenger_home_look.dart';

class PassengerHomeShortcutTile extends StatelessWidget {
  const PassengerHomeShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.accent = PassengerHomeLook.sky,
    this.featured = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final Color accent;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return TexiScalePress(
      minScale: 0.97,
      child: Material(
        color: featured ? PassengerHomeLook.cardLift : PassengerHomeLook.card,
        borderRadius: BorderRadius.circular(AppRadii.lg + 4),
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(AppRadii.lg + 4),
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg + 4),
                border: Border.all(
                  color: featured
                      ? accent.withValues(alpha: 0.35)
                      : PassengerHomeLook.hairline,
                ),
                gradient: featured
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.22),
                          PassengerHomeLook.cardLift,
                        ],
                      )
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xxxx,
                  featured ? AppSpacing.xxxx : AppSpacing.xxx,
                  AppSpacing.xxxx,
                  featured ? AppSpacing.xxxx : AppSpacing.xxx,
                ),
                child: Row(
                  children: [
                    Container(
                      width: featured ? 56 : AppSizes.tileLeading,
                      height: featured ? 56 : AppSizes.tileLeading,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: featured ? 0.28 : 0.18),
                        borderRadius: BorderRadius.circular(
                          featured ? AppRadii.lg : AppRadii.md,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: accent,
                        size: featured ? AppIconSizes.hero : AppIconSizes.xl,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: PassengerHomeLook.ink,
                                  letterSpacing: -0.2,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PassengerHomeLook.muted,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: featured ? accent : PassengerHomeLook.muted,
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

class PassengerHomePlaceChip extends StatelessWidget {
  const PassengerHomePlaceChip({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.accent = PassengerHomeLook.violet,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TexiScalePress(
      minScale: 0.97,
      child: Material(
        color: PassengerHomeLook.card,
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(AppRadii.lg + 2),
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg + 2),
                border: Border.all(color: PassengerHomeLook.hairline),
              ),
              child: SizedBox(
                width: 168,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accent, size: AppIconSizes.lg),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: PassengerHomeLook.ink,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: PassengerHomeLook.muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
