import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/service_type_display.dart';
import '../../../data/models/quote_response.dart';
import '../../../gen_l10n/app_localizations.dart';

/// Barra fija inferior del borrador: cotización, CTA y confirmación en mapa.
/// GPS / mapa / guardados viven en la cabecera junto al buscador (sin fila de acciones aquí).
class PassengerTripDraftBottomBar extends StatelessWidget {
  const PassengerTripDraftBottomBar({
    super.key,
    required this.isMapConfirmMode,
    required this.confirmingOrigin,
    required this.onConfirmMapPick,
    this.quote,
    this.selectedQuoteOption,
    required this.onSelectQuoteOption,
    required this.quotePerTripLabel,
    required this.quoteSummaryText,
    required this.onRequestRide,
    required this.requestRideEnabled,
    required this.requestRideLoading,
    required this.quotingInProgress,
    required this.loadingRoute,
    required this.routeLoadingLabel,
    this.errorMessage,
    required this.showCancelDraft,
    required this.onCancelDraft,
    required this.cancelDraftLabel,
    required this.onMenuPressed,
    required this.menuTooltip,
  });

  final bool isMapConfirmMode;
  final bool confirmingOrigin;
  final VoidCallback onConfirmMapPick;

  final QuoteResponse? quote;
  final QuoteOption? selectedQuoteOption;
  final ValueChanged<QuoteOption> onSelectQuoteOption;
  final String quotePerTripLabel;
  final String? quoteSummaryText;

  final VoidCallback onRequestRide;
  final bool requestRideEnabled;
  final bool requestRideLoading;
  final bool quotingInProgress;
  final bool loadingRoute;
  final String routeLoadingLabel;

  final String? errorMessage;
  final bool showCancelDraft;
  final VoidCallback onCancelDraft;
  final String cancelDraftLabel;
  final VoidCallback onMenuPressed;
  final String menuTooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final quoteData = quote;

    final panel = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null && errorMessage!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!isMapConfirmMode && loadingRoute) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        routeLoadingLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (isMapConfirmMode) ...[
              TexiScalePress(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: confirmingOrigin
                        ? const Color(0xFFF9AB00)
                        : const Color(0xFF111111),
                    foregroundColor: confirmingOrigin
                        ? Colors.black87
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  onPressed: onConfirmMapPick,
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      confirmingOrigin
                          ? l10n.tripConfirmOrigin
                          : l10n.tripConfirmDestination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ] else ...[
              if (quotingInProgress) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: AppSizes.progressSm,
                      height: AppSizes.progressSm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.tripDraftQuoting,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (quoteData != null && quoteData.options.isNotEmpty) ...[
                if (quoteSummaryText != null &&
                    quoteSummaryText!.trim().isNotEmpty) ...[
                  Text(
                    quoteSummaryText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: quoteData.options.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final option = quoteData.options[index];
                      final selected =
                          selectedQuoteOption?.serviceTypeId ==
                          option.serviceTypeId;
                      final name = displayServiceTypeName(
                        option.serviceTypeName,
                        l10n,
                      );
                      final price = formatMoney(
                        option.estimatedPrice,
                        currencyCode: option.currencyCode,
                        decimals: 1,
                      );
                      return TexiScalePress(
                        child: Material(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.background.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          child: InkWell(
                            onTap: () => onSelectQuoteOption(option),
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            child: Container(
                              width: 140,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border.withValues(alpha: 0.4),
                                  width: selected ? 1.6 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary.withValues(
                                              alpha: 0.22,
                                            )
                                          : AppColors.textSecondary.withValues(
                                              alpha: 0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.sm,
                                      ),
                                    ),
                                    child: Icon(
                                      serviceTypeIconData(option.serviceTypeName),
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: selected
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '$price $quotePerTripLabel',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SizedBox(
                height: AppSizes.buttonHeight,
                child: TexiScalePress(
                  child: FilledButton(
                    onPressed: requestRideEnabled ? onRequestRide : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: requestRideLoading
                        ? const SizedBox(
                            height: AppSizes.progressBtn,
                            width: AppSizes.progressBtn,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : (!requestRideEnabled &&
                              (quotingInProgress || loadingRoute))
                        ? const SizedBox(
                            height: AppSizes.progressBtn,
                            width: AppSizes.progressBtn,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(
                            l10n.confirmRequestRide,
                            style: const TextStyle(
                              fontSize: AppTypography.title,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
            if (showCancelDraft) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: onCancelDraft,
                  child: Text(
                    cancelDraftLabel,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          panel,
          Positioned(
            right: 12,
            top: -28,
            child: Tooltip(
              message: menuTooltip,
              child: Material(
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onMenuPressed,
                  child: Ink(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2.5),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.surface,
                          AppColors.background.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.apps_rounded,
                      size: 30,
                      color: AppColors.primary,
                    ),
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
