import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../trip_request_state.dart';

/// Editor de monto solo cuando la cotización viene en modo ofertable.
class PassengerOfferableFareEditor extends ConsumerWidget {
  const PassengerOfferableFareEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripRequestProvider);
    final quote = trip.quote;
    final floor = trip.previewTotalPrice;
    if (quote == null || !quote.isOfferable || floor == null || floor <= 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final current = trip.passengerOfferAmount ?? floor;
    final shown = current < floor ? floor : current;

    void setAmount(double next) {
      final value = next < floor ? floor : next;
      ref.read(tripRequestProvider.notifier).setPassengerOffer(value);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.offerableFareTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.offerableFareHint,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: shown <= floor + 0.01
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        setAmount((shown - 0.5).clamp(floor, shown));
                      },
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: l10n.offerableFareTitle,
              ),
              Expanded(
                child: Text(
                  formatTripMoney(shown, currencyCode: quote.currencyCode),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setAmount(shown + 0.5);
                },
                icon: const Icon(Icons.add_circle_outline),
                tooltip: l10n.offerableFareTitle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
