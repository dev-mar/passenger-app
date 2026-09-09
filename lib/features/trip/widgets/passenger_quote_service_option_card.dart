import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/service_type_display.dart';
import '../../../data/models/quote_response.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../../promotions/passenger_promo_you_pay_chip.dart';
import 'service_type_vehicle_image.dart';

/// Tarjeta de oferta: imagen izq. + textos der. (guía trip-typeofert + PNGs).
class PassengerQuoteServiceOptionCard extends StatelessWidget {
  const PassengerQuoteServiceOptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    required this.etaMinutes,
    this.displayPrice,
  });

  /// Altura del carrusel cuando no hay “Tú pagas”.
  static const double heightCompact = 78;

  /// Altura con tarifa bruta grande + chip de beneficio (el ListView debe usar esta).
  static const double heightWithYouPay = 128;

  static const double cardWidth = 210;

  final QuoteOption option;
  final bool selected;
  final VoidCallback onTap;
  final int etaMinutes;
  final double? displayPrice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = displayServiceTypeName(
      option.serviceTypeName,
      l10n,
      serviceTypeId: option.serviceTypeId,
    );
    final displayedGross = displayPrice ?? option.estimatedPrice;
    final price = formatMoney(
      displayedGross,
      currencyCode: option.currencyCode,
      decimals: 1,
    );
    final seats = serviceTypeSeatCapacity(
      option.serviceTypeName,
      serviceTypeId: option.serviceTypeId,
    );
    final asset = serviceTypeVehicleAsset(
      option.serviceTypeName,
      serviceTypeId: option.serviceTypeId,
    );
    final etaLabel = etaMinutes > 0 ? '$etaMinutes min' : '—';
    final youPay = option.youPayForDisplayedGross(displayedGross);
    final hasYouPay = youPay != null;

    return TexiScalePress(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: cardWidth,
            height: hasYouPay ? heightWithYouPay : heightCompact,
            padding: EdgeInsets.fromLTRB(8, 8, 10, hasYouPay ? 8 : 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              color: selected
                  ? const Color(0xFF3A3428)
                  : const Color(0xFF24221C),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.10),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 76,
                        height: hasYouPay ? 70 : 62,
                        child: ServiceTypeVehicleImage(
                          asset: asset,
                          selected: selected,
                          errorBuilder: (_, _, _) => Icon(
                            serviceTypeIconData(
                              option.serviceTypeName,
                              serviceTypeId: option.serviceTypeId,
                            ),
                            color: AppColors.primary,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: hasYouPay
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 12,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.95,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$seats',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '  ·  ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    etaLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (youPay != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _YouPayShadowBand(
                    child: PassengerPromoYouPayChip(
                      cashDuePassenger: youPay,
                      currencyCode: option.currencyCode,
                      compact: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Franja oscura detrás de “Tú pagas”, con aire respecto al borde de la tarjeta.
class _YouPayShadowBand extends StatelessWidget {
  const _YouPayShadowBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 3.5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE60A0A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
