import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money_formatter.dart';
import '../../gen_l10n/app_localizations.dart';

/// Chip aditivo: “Tú pagas X”. El precio grande sigue siendo la tarifa bruta.
class PassengerPromoYouPayChip extends StatelessWidget {
  const PassengerPromoYouPayChip({
    super.key,
    required this.cashDuePassenger,
    this.currencyCode,
    this.compact = false,
  });

  final double cashDuePassenger;
  final String? currencyCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = formatTripMoney(
      cashDuePassenger,
      currencyCode: currencyCode,
    );
    return Text(
      l10n.promoChipYouPay(amount),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 11 : 13,
            height: 1.1,
          ),
    );
  }
}
