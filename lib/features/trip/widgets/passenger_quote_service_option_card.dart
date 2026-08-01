import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/service_type_display.dart';
import '../../../data/models/quote_response.dart';
import '../../../gen_l10n/app_localizations.dart';

/// Tarjeta de oferta: imagen izq. + textos der. (guía trip-typeofert + PNGs).
class PassengerQuoteServiceOptionCard extends StatelessWidget {
  const PassengerQuoteServiceOptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    required this.etaMinutes,
  });

  final QuoteOption option;
  final bool selected;
  final VoidCallback onTap;
  final int etaMinutes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = displayServiceTypeName(option.serviceTypeName, l10n);
    final price = formatMoney(
      option.estimatedPrice,
      currencyCode: option.currencyCode,
      decimals: 1,
    );
    final seats = serviceTypeSeatCapacity(option.serviceTypeName);
    final asset = serviceTypeVehicleAsset(option.serviceTypeName);
    final etaLabel = etaMinutes > 0 ? '$etaMinutes min' : '—';

    return TexiScalePress(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: 210,
            height: 78,
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 62,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => Icon(
                      serviceTypeIconData(option.serviceTypeName),
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(height: 3),
                      Text(
                        price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.05,
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
  }
}
