import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_ui_tokens.dart';
import '../ui/texi_scale_press.dart';

/// Tarjeta reusable para estados de carga/empty/error/offline con estética consistente.
class PremiumStateView extends StatelessWidget {
  const PremiumStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxx,
        AppSpacing.sheetH,
        AppSpacing.xxxx,
        AppSpacing.xxl + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.snackBar),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Icon(icon, size: AppIconSizes.stateHero, color: cs.primary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xxx),
            TexiScalePress(
              child: FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumSkeletonBox extends StatefulWidget {
  const PremiumSkeletonBox({
    super.key,
    required this.height,
    this.radius = AppRadii.md,
  });

  final double height;
  final double radius;

  @override
  State<PremiumSkeletonBox> createState() => _PremiumSkeletonBoxState();
}

class _PremiumSkeletonBoxState extends State<PremiumSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final alpha = 0.13 + (_ctrl.value * 0.10);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
