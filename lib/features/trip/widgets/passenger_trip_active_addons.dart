import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../trip_passenger_extras.dart';
import '../trip_passenger_specials.dart';
import '../trip_payment_method.dart';

/// Chip de pago del viaje activo (efectivo / QR).
class PassengerTripPaymentChip extends StatelessWidget {
  const PassengerTripPaymentChip({
    super.key,
    required this.l10n,
    required this.paymentMethod,
  });

  final AppLocalizations l10n;
  final String paymentMethod;

  static const Color _cash = Color(0xFF34D399);
  static const Color _qr = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final isQr = TripPaymentMethod.isQr(paymentMethod);
    final color = isQr ? _qr : _cash;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isQr ? Icons.qr_code_2_rounded : Icons.payments_rounded,
            size: 13,
            color: color.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 4),
          Text(
            isQr ? l10n.tripPaymentMethodQr : l10n.tripPaymentMethodCash,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Iconos compactos de extras/requerimientos. Tap abre el detalle.
class PassengerTripAddonsStrip extends StatelessWidget {
  const PassengerTripAddonsStrip({
    super.key,
    required this.l10n,
    required this.extras,
    required this.specials,
  });

  final AppLocalizations l10n;
  final List<String> extras;
  final List<String> specials;

  static const Color _muted = Color(0xFF94A3B8);
  static const Color _special = Color(0xFFF5C16C);

  @override
  Widget build(BuildContext context) {
    final extraCodes = extras.toSet().where((c) => c.isNotEmpty).toList();
    final specialCodes = specials.toSet().where((c) => c.isNotEmpty).toList();
    if (extraCodes.isEmpty && specialCodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          showPassengerTripAddonsSheet(
            context: context,
            l10n: l10n,
            extras: extraCodes,
            specials: specialCodes,
          );
        },
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: specialCodes.isNotEmpty
                ? _special.withValues(alpha: 0.14)
                : _muted.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: specialCodes.isNotEmpty
                  ? _special.withValues(alpha: 0.42)
                  : _muted.withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < specialCodes.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Icon(
                  passengerTripSpecialIcon(specialCodes[i]),
                  size: 13,
                  color: _special,
                ),
              ],
              if (specialCodes.isNotEmpty && extraCodes.isNotEmpty)
                const SizedBox(width: 5),
              for (var i = 0; i < extraCodes.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Icon(
                  passengerTripExtraIcon(extraCodes[i]),
                  size: 13,
                  color: _muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showPassengerTripAddonsSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<String> extras,
  required List<String> specials,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadii.sheetTop),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sheetH,
            AppSpacing.lg,
            AppSpacing.sheetH,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.tripRequestDetailsTitle,
                style: const TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final code in specials)
                _AddonRow(
                  icon: passengerTripSpecialIcon(code),
                  accent: const Color(0xFFF5C16C),
                  title: passengerTripSpecialTitle(l10n, code),
                  subtitle: passengerTripSpecialBody(l10n, code),
                ),
              for (final code in extras)
                _AddonRow(
                  icon: passengerTripExtraIcon(code),
                  accent: AppColors.textSecondary,
                  title: passengerTripExtraTitle(l10n, code),
                  subtitle: passengerTripExtraBody(l10n, code),
                ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: AppSizes.buttonHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.tripAddonInfoClose),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AddonRow extends StatelessWidget {
  const _AddonRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSizes.lg, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: AppTypography.captionAlt,
                      height: 1.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData passengerTripExtraIcon(String code) {
  switch (code) {
    case TripPassengerExtra.pet:
      return Icons.pets_rounded;
    case TripPassengerExtra.childSeat:
      return Icons.child_care_rounded;
    case TripPassengerExtra.wheelchair:
      return Icons.accessible_rounded;
    case TripPassengerExtra.over4:
      return Icons.groups_rounded;
    case TripPassengerExtra.luggage:
      return Icons.luggage_rounded;
    case TripPassengerExtra.ac:
      return Icons.ac_unit_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

IconData passengerTripSpecialIcon(String code) {
  switch (code) {
    case TripPassengerSpecial.seats6:
      return Icons.groups_rounded;
    case TripPassengerSpecial.roofRack:
      return Icons.airport_shuttle_rounded;
    case TripPassengerSpecial.cargo:
      return Icons.inventory_2_outlined;
    default:
      return Icons.priority_high_rounded;
  }
}

String passengerTripExtraTitle(AppLocalizations l10n, String code) {
  switch (code) {
    case TripPassengerExtra.pet:
      return l10n.tripPrefPetTitle;
    case TripPassengerExtra.wheelchair:
      return l10n.tripPrefWheelchairTitle;
    case TripPassengerExtra.luggage:
      return l10n.tripPrefLuggageTitle;
    case TripPassengerExtra.ac:
      return l10n.tripPrefAcTitle;
    default:
      return code;
  }
}

String passengerTripExtraBody(AppLocalizations l10n, String code) {
  switch (code) {
    case TripPassengerExtra.pet:
      return l10n.tripPrefPetBody;
    case TripPassengerExtra.wheelchair:
      return l10n.tripPrefWheelchairBody;
    case TripPassengerExtra.luggage:
      return l10n.tripPrefLuggageBody;
    case TripPassengerExtra.ac:
      return l10n.tripPrefAcBody;
    default:
      return '';
  }
}

String passengerTripSpecialTitle(AppLocalizations l10n, String code) {
  switch (code) {
    case TripPassengerSpecial.seats6:
      return l10n.tripSpecialSeats6Title;
    case TripPassengerSpecial.roofRack:
      return l10n.tripSpecialRoofRackTitle;
    case TripPassengerSpecial.cargo:
      return l10n.tripSpecialCargoTitle;
    default:
      return code;
  }
}

String passengerTripSpecialBody(AppLocalizations l10n, String code) {
  switch (code) {
    case TripPassengerSpecial.seats6:
      return l10n.tripSpecialSeats6Body;
    case TripPassengerSpecial.roofRack:
      return l10n.tripSpecialRoofRackBody;
    case TripPassengerSpecial.cargo:
      return l10n.tripSpecialCargoBody;
    default:
      return '';
  }
}
