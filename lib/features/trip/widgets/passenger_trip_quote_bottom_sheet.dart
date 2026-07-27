import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/service_type_display.dart';
import '../../../data/models/quote_response.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../passenger_trip_submit_helper.dart';
import '../trip_request_state.dart';
import 'quote_bottom_sheet_widgets.dart';

/// Bottom sheet: opciones de precio y envío directo de la solicitud.
class PassengerTripQuoteBottomSheet extends ConsumerStatefulWidget {
  const PassengerTripQuoteBottomSheet({
    super.key,
    required this.quote,
    this.originAddress,
    this.destinationAddress,
    this.routeOverviewEncoded,
    required this.ensureDeviceGpsForNewTrip,
    required this.onClose,
    required this.onSuccess,
  });

  final QuoteResponse quote;
  final String? originAddress;
  final String? destinationAddress;
  final String? routeOverviewEncoded;
  final Future<bool> Function() ensureDeviceGpsForNewTrip;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  @override
  ConsumerState<PassengerTripQuoteBottomSheet> createState() =>
      _PassengerTripQuoteBottomSheetState();
}

class _PassengerTripQuoteBottomSheetState
    extends ConsumerState<PassengerTripQuoteBottomSheet> {
  QuoteOption? _selected;
  bool _requesting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.quote.options.isNotEmpty) {
      _selected = widget.quote.options.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tripRequestProvider.notifier).selectOption(_selected!);
      });
    }
  }

  Future<void> _requestTrip() async {
    final state = ref.read(tripRequestProvider);
    final origin = state.origin;
    final destination = state.destination;
    final quote = state.quote;
    final option = _selected;

    if (origin == null ||
        destination == null ||
        quote == null ||
        option == null) {
      return;
    }

    setState(() {
      _requesting = true;
      _errorMessage = null;
    });

    final result = await submitPassengerTripFromQuote(
      ref: ref,
      context: context,
      quote: quote,
      option: option,
      originLat: origin.lat,
      originLng: origin.lng,
      destinationLat: destination.lat,
      destinationLng: destination.lng,
      originAddress: widget.originAddress,
      destinationAddress: widget.destinationAddress,
      routeOverviewEncoded: widget.routeOverviewEncoded,
      ensureDeviceGpsForNewTrip: widget.ensureDeviceGpsForNewTrip,
    );
    if (!mounted) return;
    setState(() => _requesting = false);
    if (result.kind == PassengerTripSubmitResultKind.success ||
        result.kind == PassengerTripSubmitResultKind.recoveredExisting) {
      widget.onSuccess();
      return;
    }
    setState(() {
      _errorMessage =
          result.message ?? AppLocalizations.of(context)!.commonError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quote = widget.quote;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: TripQuoteSheetCloseOrb(onTap: widget.onClose)),
          ),
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.quoteSheetTopMargin),
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height *
                  AppSizes.quoteSheetMaxHeightFactor,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.sheetTop),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
                width: AppBorders.thin,
              ),
              boxShadow: AppShadows.sheetLiftStrong,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Container(
                    width: AppSizes.dragHandleQuoteW,
                    height: AppSizes.dragHandleQuoteH,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                TripQuoteHeader(
                  title: l10n.quoteTitle,
                  summary:
                      '${quote.distanceKm.toStringAsFixed(1)} km · ${quote.durationMinutes} min · ${quote.city.name}',
                ),
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxx,
                      AppSpacing.md,
                      AppSpacing.xxx,
                      AppSpacing.xxx,
                    ),
                    shrinkWrap: true,
                    itemCount: quote.options.length,
                    itemBuilder: (context, index) {
                      final option = quote.options[index];
                      final isSelected =
                          _selected?.serviceTypeId == option.serviceTypeId;
                      return TripQuoteOptionTile(
                        serviceName: displayServiceTypeName(
                          option.serviceTypeName,
                          l10n,
                        ),
                        priceText:
                            '${formatMoney(option.estimatedPrice, currencyCode: option.currencyCode, decimals: 1)} ${l10n.quotePerTrip}',
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selected = option);
                          ref
                              .read(tripRequestProvider.notifier)
                              .selectOption(option);
                        },
                      );
                    },
                  ),
                ),
                if (_errorMessage != null) ...[
                  TripQuoteErrorBanner(message: _errorMessage!),
                ],
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.sheetH,
                    AppSpacing.md,
                    AppSpacing.sheetH,
                    MediaQuery.of(context).padding.bottom + AppSpacing.xxx,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TripQuoteConfirmButton(
                        enabled: _selected != null && !_requesting,
                        loading: _requesting,
                        label: l10n.quoteConfirm,
                        onPressed: _requestTrip,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
