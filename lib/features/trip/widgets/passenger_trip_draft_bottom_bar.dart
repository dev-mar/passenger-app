import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../core/utils/service_type_display.dart';
import '../../../data/models/quote_response.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'passenger_quote_service_option_card.dart';

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
  final ValueChanged<Offset> onMenuPressed;
  final String menuTooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final quoteData = quote;
    final selectedName = selectedQuoteOption == null
        ? null
        : displayServiceTypeName(selectedQuoteOption!.serviceTypeName, l10n);
    final requestLabel = (selectedName != null && selectedName.isNotEmpty)
        ? l10n.confirmRequestRideWithService(selectedName)
        : l10n.confirmRequestRide;

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
                Builder(
                  builder: (context) {
                    final options = List<QuoteOption>.from(quoteData.options)
                      ..sort(
                        (a, b) => serviceTypeCarouselSortKey(a.serviceTypeName)
                            .compareTo(
                              serviceTypeCarouselSortKey(b.serviceTypeName),
                            ),
                      );
                    return SizedBox(
                      height: 78,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: options.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final selected =
                              selectedQuoteOption?.serviceTypeId ==
                              option.serviceTypeId;
                          return PassengerQuoteServiceOptionCard(
                            option: option,
                            selected: selected,
                            onTap: () => onSelectQuoteOption(option),
                            etaMinutes: quoteData.durationMinutes,
                          );
                        },
                      ),
                    );
                  },
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
                            requestLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppTypography.title,
                              fontWeight: FontWeight.w700,
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
              child: Builder(
                builder: (btnCtx) {
                  return Material(
                    elevation: 14,
                    shadowColor: AppColors.primary.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    color: Colors.transparent,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        final box = btnCtx.findRenderObject() as RenderBox?;
                        final anchor = box == null
                            ? Offset.zero
                            : box.localToGlobal(box.size.center(Offset.zero));
                        onMenuPressed(anchor);
                      },
                      child: Ink(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.82),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          size: 26,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
