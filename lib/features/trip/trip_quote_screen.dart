import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/service_type_display.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../gen_l10n/app_localizations.dart';
import 'trip_request_state.dart';

/// Pantalla Cotización: lista de tipos de servicio y precios.
class TripQuoteScreen extends ConsumerWidget {
  const TripQuoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(tripRequestProvider);
    final quote = state.quote;
    final selected = state.selectedOption;

    if (quote == null || quote.options.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(l10n.quoteTitle)),
        body: Center(child: Text(l10n.commonError)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.quoteTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.quoteSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: quote.options.length,
              itemBuilder: (context, index) {
                final option = quote.options[index];
                final isSelected = selected?.serviceTypeId == option.serviceTypeId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        ref.read(tripRequestProvider.notifier).selectOption(option);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car_rounded,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayServiceTypeName(
                                      option.serviceTypeName,
                                      l10n,
                                    ),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                  ),
                                  Text(
                                    '${option.estimatedPrice.toStringAsFixed(1)} ${l10n.quotePerTrip}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TexiScalePress(
                child: FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => context.pushNamed('trip_confirm'),
                  child: Text(l10n.quoteConfirm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
