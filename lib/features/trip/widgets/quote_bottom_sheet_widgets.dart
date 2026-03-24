import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';

class TripQuoteHeader extends StatelessWidget {
  const TripQuoteHeader({
    super.key,
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sheetH, AppSpacing.xxxx, AppSpacing.sheetH, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.headlineSm,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              summary,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TripQuoteOptionTile extends StatelessWidget {
  const TripQuoteOptionTile({
    super.key,
    required this.serviceName,
    required this.priceText,
    required this.isSelected,
    required this.onTap,
  });

  final String serviceName;
  final String priceText;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxx, vertical: AppSpacing.xxx),
            child: Row(
              children: [
                Container(
                  width: AppSizes.tileLeading,
                  height: AppSizes.tileLeading,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: AppIconSizes.xl,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxx),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: AppTypography.title,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: AppTypography.body,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: AppIconSizes.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TripQuoteErrorBanner extends StatelessWidget {
  const TripQuoteErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sheetH, vertical: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.error, fontSize: AppTypography.bodySmall),
        ),
      ),
    );
  }
}

class TripQuoteConfirmButton extends StatelessWidget {
  const TripQuoteConfirmButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.buttonHeight,
      width: double.infinity,
      child: TexiScalePress(
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          ),
          child: loading
              ? const SizedBox(
                  height: AppSizes.progressBtn,
                  width: AppSizes.progressBtn,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                )
              : Text(
                  label,
                  style: const TextStyle(fontSize: AppTypography.title, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

class TripQuoteSheetCloseOrb extends StatelessWidget {
  const TripQuoteSheetCloseOrb({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: AppElevation.closeOrb,
      shadowColor: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.65),
              width: AppBorders.strong,
            ),
          ),
          child: const SizedBox(
            width: AppSizes.closeOrb,
            height: AppSizes.closeOrb,
            child: Icon(
              Icons.close_rounded,
              color: AppColors.textPrimary,
              size: AppIconSizes.xl,
            ),
          ),
        ),
      ),
    );
  }
}
