import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/compliance/passenger_legal_links.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_motion.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../trip_passenger_extras.dart';
import '../trip_passenger_specials.dart';
import '../trip_payment_method.dart';
import '../trip_request_state.dart';
import '../trip_service_addon_policy.dart';

Future<void> showPassengerTripRequestDetailsSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _PassengerTripRequestDetailsSheet(),
  );
}

class _FormPalette {
  const _FormPalette({
    required this.sheetTop,
    required this.sheetBottom,
    required this.card,
    required this.accent,
    required this.onAccent,
  });

  final Color sheetTop;
  final Color sheetBottom;
  final Color card;
  final Color accent;
  final Color onAccent;

  static const payment = Color(0xFF5EEAD4);
  static const prefs = Color(0xFF7DD3FC);
  static const specials = Color(0xFFF5C16C);
  static const premium = Color(0xFFE8C47A);
  static const moto = Color(0xFFC4B5FD);
  static const text = Color(0xFFF7F4EE);
  static const muted = Color(0xFFB8B3A8);

  factory _FormPalette.forFamily(TripPassengerServiceFamily family) {
    switch (family) {
      case TripPassengerServiceFamily.exclusive:
        return const _FormPalette(
          sheetTop: Color(0xFF2C2418),
          sheetBottom: Color(0xFF16120C),
          card: Color(0xFF3A3124),
          accent: premium,
          onAccent: Color(0xFF1A140C),
        );
      case TripPassengerServiceFamily.motorbike:
        return const _FormPalette(
          sheetTop: Color(0xFF241B30),
          sheetBottom: Color(0xFF120E18),
          card: Color(0xFF322844),
          accent: moto,
          onAccent: Color(0xFF1A1224),
        );
      case TripPassengerServiceFamily.comfort:
        return const _FormPalette(
          sheetTop: Color(0xFF1A2628),
          sheetBottom: Color(0xFF101618),
          card: Color(0xFF243336),
          accent: Color(0xFF7DD3C8),
          onAccent: Color(0xFF102018),
        );
      case TripPassengerServiceFamily.economy:
      case TripPassengerServiceFamily.other:
        return const _FormPalette(
          sheetTop: Color(0xFF242018),
          sheetBottom: Color(0xFF14120E),
          card: Color(0xFF332E24),
          accent: Color(0xFFE2C48A),
          onAccent: Color(0xFF1A140C),
        );
    }
  }
}

class _AddonChoice {
  const _AddonChoice({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.info,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final String info;
  final VoidCallback onTap;
}

class _PassengerTripRequestDetailsSheet extends ConsumerWidget {
  const _PassengerTripRequestDetailsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tripState = ref.watch(tripRequestProvider);
    final selected = TripPaymentMethod.normalize(tripState.paymentMethod);
    final extras = tripState.extras;
    final specials = tripState.specials;
    final family = passengerServiceFamily(
      serviceTypeId: tripState.selectedOption?.serviceTypeId,
      serviceTypeName: tripState.selectedOption?.serviceTypeName,
    );
    final palette = _FormPalette.forFamily(family);
    final extraCodes = allowedExtrasForFamily(family);
    final specialCodes = allowedSpecialsForFamily(family);
    final maxH = MediaQuery.sizeOf(context).height * 0.9;
    final notifier = ref.read(tripRequestProvider.notifier);

    final prefChoices = <_AddonChoice>[
      if (extraCodes.contains(TripPassengerExtra.pet))
        _AddonChoice(
          selected: extras.pet,
          icon: Icons.pets_rounded,
          title: l10n.tripPrefPetTitle,
          subtitle: l10n.tripPrefPetBody,
          info: l10n.tripPrefPetInfo,
          onTap: () => notifier.toggleExtra(TripPassengerExtra.pet),
        ),
      if (extraCodes.contains(TripPassengerExtra.wheelchair))
        _AddonChoice(
          selected: extras.wheelchair,
          icon: Icons.accessible_rounded,
          title: l10n.tripPrefWheelchairTitle,
          subtitle: l10n.tripPrefWheelchairBody,
          info: l10n.tripPrefWheelchairInfo,
          onTap: () => notifier.toggleExtra(TripPassengerExtra.wheelchair),
        ),
      if (extraCodes.contains(TripPassengerExtra.luggage))
        _AddonChoice(
          selected: extras.luggage,
          icon: Icons.luggage_rounded,
          title: l10n.tripPrefLuggageTitle,
          subtitle: l10n.tripPrefLuggageBody,
          info: l10n.tripPrefLuggageInfo,
          onTap: () => notifier.toggleExtra(TripPassengerExtra.luggage),
        ),
      if (extraCodes.contains(TripPassengerExtra.ac))
        _AddonChoice(
          selected: extras.ac,
          icon: Icons.ac_unit_rounded,
          title: l10n.tripPrefAcTitle,
          subtitle: l10n.tripPrefAcBody,
          info: l10n.tripPrefAcInfo,
          onTap: () => notifier.toggleExtra(TripPassengerExtra.ac),
        ),
    ];

    final specialChoices = <_AddonChoice>[
      if (specialCodes.contains(TripPassengerSpecial.seats6))
        _AddonChoice(
          selected: specials.seats6,
          icon: Icons.groups_rounded,
          title: l10n.tripSpecialSeats6Title,
          subtitle: l10n.tripSpecialSeats6Body,
          info: l10n.tripSpecialSeats6Info,
          onTap: () => notifier.toggleSpecial(TripPassengerSpecial.seats6),
        ),
      if (specialCodes.contains(TripPassengerSpecial.roofRack))
        _AddonChoice(
          selected: specials.roofRack,
          icon: Icons.airport_shuttle_rounded,
          title: l10n.tripSpecialRoofRackTitle,
          subtitle: l10n.tripSpecialRoofRackBody,
          info: l10n.tripSpecialRoofRackInfo,
          onTap: () => notifier.toggleSpecial(TripPassengerSpecial.roofRack),
        ),
      if (specialCodes.contains(TripPassengerSpecial.cargo))
        _AddonChoice(
          selected: specials.cargo,
          icon: Icons.inventory_2_outlined,
          title: l10n.tripSpecialCargoTitle,
          subtitle: l10n.tripSpecialCargoBody,
          info: l10n.tripSpecialCargoInfo,
          onTap: () => notifier.toggleSpecial(TripPassengerSpecial.cargo),
        ),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.sheetTop, palette.sheetBottom],
          ),
          borderRadius: const BorderRadius.vertical(
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
                  color: _FormPalette.muted.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.tripRequestDetailsTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTypography.headlineSm,
                fontWeight: FontWeight.w800,
                color: _FormPalette.text,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.tripRequestDetailsHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTypography.bodySmall,
                height: 1.35,
                color: _FormPalette.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH - 228),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(
                      title: l10n.tripPaymentSectionTitle,
                      accent: _FormPalette.payment,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ChoiceCard(
                      palette: palette,
                      accent: _FormPalette.payment,
                      selected: selected == TripPaymentMethod.cash,
                      icon: Icons.payments_rounded,
                      title: l10n.tripPaymentMethodCash,
                      subtitle: l10n.tripPaymentMethodCashBody,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        notifier.setPaymentMethod(TripPaymentMethod.cash);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ChoiceCard(
                      palette: palette,
                      accent: _FormPalette.payment,
                      selected: selected == TripPaymentMethod.qr,
                      icon: Icons.qr_code_2_rounded,
                      title: l10n.tripPaymentMethodQr,
                      subtitle: l10n.tripPaymentMethodQrBody,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        notifier.setPaymentMethod(TripPaymentMethod.qr);
                      },
                    ),
                    if (family == TripPassengerServiceFamily.motorbike) ...[
                      const SizedBox(height: AppSpacing.section),
                      _MotoShowcase(palette: palette, l10n: l10n),
                    ],
                    if (family == TripPassengerServiceFamily.exclusive) ...[
                      const SizedBox(height: AppSpacing.section),
                      _PremiumShowcase(palette: palette, l10n: l10n),
                    ],
                    if (prefChoices.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.section),
                      _SectionLabel(
                        title: l10n.tripPrefsSectionTitle,
                        caption: l10n.tripPrefsSectionHint,
                        accent: _FormPalette.prefs,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (var i = 0; i < prefChoices.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        _ChoiceCard(
                          palette: palette,
                          accent: _FormPalette.prefs,
                          selected: prefChoices[i].selected,
                          icon: prefChoices[i].icon,
                          title: prefChoices[i].title,
                          subtitle: prefChoices[i].subtitle,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            prefChoices[i].onTap();
                          },
                          onInfo: () => _openInfoScreen(
                            context,
                            accent: _FormPalette.prefs,
                            icon: prefChoices[i].icon,
                            title: prefChoices[i].title,
                            body: prefChoices[i].info,
                          ),
                        ),
                      ],
                    ],
                    if (specialChoices.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.section),
                      _SectionLabel(
                        title: l10n.tripSpecialsSectionTitle,
                        caption: l10n.tripSpecialsSectionHint,
                        accent: _FormPalette.specials,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (var i = 0; i < specialChoices.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        _ChoiceCard(
                          palette: palette,
                          accent: _FormPalette.specials,
                          selected: specialChoices[i].selected,
                          icon: specialChoices[i].icon,
                          title: specialChoices[i].title,
                          subtitle: specialChoices[i].subtitle,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            specialChoices[i].onTap();
                          },
                          onInfo: () => _openInfoScreen(
                            context,
                            accent: _FormPalette.specials,
                            icon: specialChoices[i].icon,
                            title: specialChoices[i].title,
                            body: specialChoices[i].info,
                          ),
                        ),
                      ],
                      if (specials.isNotEmpty &&
                          tripState.previewTotalPrice != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _PricePreview(
                          accent: _FormPalette.specials,
                          label: l10n.tripSpecialsPricePreview(
                            formatTripMoney(
                              tripState.previewTotalPrice,
                              currencyCode:
                                  tripState.selectedOption?.currencyCode,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _LearnMoreLink(
              accent: palette.accent,
              label: l10n.tripRequestDetailsLearnMore,
              errorLabel: l10n.tripRequestDetailsLearnMoreError,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppSizes.buttonHeight,
              child: TexiScalePress(
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: Text(
                    l10n.tripRequestDetailsDone,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.accent,
    this.caption,
  });

  final String title;
  final String? caption;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: caption == null ? 16 : 32,
          margin: const EdgeInsets.only(top: 2, right: AppSpacing.md),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w800,
                  color: _FormPalette.text,
                ),
              ),
              if (caption != null && caption!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: const TextStyle(
                    fontSize: AppTypography.captionAlt,
                    height: 1.3,
                    color: _FormPalette.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.palette,
    required this.accent,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onInfo,
  });

  final _FormPalette palette;
  final Color accent;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    return TexiScalePress(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: AnimatedContainer(
            duration: TexiMotion.fast,
            curve: TexiMotion.standard,
            constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.16)
                  : palette.card.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.06),
                width: selected ? AppBorders.emphasis : AppBorders.thin,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.tileLeading,
                  height: AppSizes.tileLeading,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: selected ? 0.28 : 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(icon, color: accent, size: AppIconSizes.xl),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w800,
                          color: _FormPalette.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: AppTypography.captionAlt,
                          height: 1.3,
                          color: _FormPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onInfo != null)
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onInfo!();
                    },
                    tooltip: title,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.info_outline_rounded,
                      size: AppIconSizes.lg,
                      color: _FormPalette.muted.withValues(alpha: 0.95),
                    ),
                  ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? accent : _FormPalette.muted,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumShowcase extends StatelessWidget {
  const _PremiumShowcase({required this.palette, required this.l10n});

  final _FormPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String title, String body})>[
      (
        icon: Icons.electrical_services_rounded,
        title: l10n.tripPremiumAmenityCharger,
        body: l10n.tripPremiumAmenityChargerBody,
      ),
      (
        icon: Icons.door_front_door_outlined,
        title: l10n.tripPremiumAmenityCourtesy,
        body: l10n.tripPremiumAmenityCourtesyBody,
      ),
      (
        icon: Icons.water_drop_outlined,
        title: l10n.tripPremiumAmenityWater,
        body: l10n.tripPremiumAmenityWaterBody,
      ),
      (
        icon: Icons.receipt_long_outlined,
        title: l10n.tripPremiumAmenityInvoice,
        body: l10n.tripPremiumAmenityInvoiceBody,
      ),
      (
        icon: Icons.schedule_rounded,
        title: l10n.tripPremiumAmenityWait,
        body: l10n.tripPremiumAmenityWaitBody,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A3C28),
            palette.card,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: _FormPalette.premium.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: _FormPalette.premium,
                size: AppIconSizes.xl,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.tripPremiumIncludedTitle,
                  style: const TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: FontWeight.w800,
                    color: _FormPalette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.tripPremiumIncludedHint,
            style: const TextStyle(
              fontSize: AppTypography.captionAlt,
              height: 1.35,
              color: _FormPalette.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final item in items)
            _BenefitRow(
              accent: _FormPalette.premium,
              icon: item.icon,
              title: item.title,
              subtitle: item.body,
            ),
        ],
      ),
    );
  }
}

class _MotoShowcase extends StatelessWidget {
  const _MotoShowcase({required this.palette, required this.l10n});

  final _FormPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B2A55),
            palette.card,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: _FormPalette.moto.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.two_wheeler_rounded,
                color: _FormPalette.moto,
                size: AppIconSizes.hero,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.tripMotoServiceTitle,
                  style: const TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: FontWeight.w800,
                    color: _FormPalette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tripMotoServiceBody,
            style: const TextStyle(
              fontSize: AppTypography.bodySmall,
              height: 1.35,
              color: _FormPalette.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _BenefitRow(
            accent: _FormPalette.moto,
            icon: Icons.bolt_rounded,
            title: l10n.tripMotoPerkSpeed,
          ),
          _BenefitRow(
            accent: _FormPalette.moto,
            icon: Icons.person_rounded,
            title: l10n.tripMotoPerkSolo,
          ),
          _BenefitRow(
            accent: _FormPalette.moto,
            icon: Icons.inventory_2_outlined,
            title: l10n.tripMotoPerkLight,
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.accent,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSizes.md, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w700,
                    color: _FormPalette.text,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: AppTypography.captionAlt,
                      height: 1.3,
                      color: _FormPalette.muted,
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

class _PricePreview extends StatelessWidget {
  const _PricePreview({required this.accent, required this.label});

  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTypography.bodyLarge,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _LearnMoreLink extends StatelessWidget {
  const _LearnMoreLink({
    required this.accent,
    required this.label,
    required this.errorLabel,
  });

  final Color accent;
  final String label;
  final String errorLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.iconButtonMin,
      child: TextButton(
        onPressed: () => _openServicesGuide(context, errorLabel),
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: accent.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.open_in_new_rounded, size: AppIconSizes.sm, color: accent),
          ],
        ),
      ),
    );
  }
}

Future<void> _openServicesGuide(BuildContext context, String errorLabel) async {
  HapticFeedback.selectionClick();
  final ok = await openPassengerServicesGuide(context);
  if (!context.mounted || ok) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorLabel)),
  );
}

Future<void> _openInfoScreen(
  BuildContext context, {
  required Color accent,
  required IconData icon,
  required String title,
  required String body,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF221E18), Color(0xFF12100C)],
              ),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: AppSizes.dragHandleQuoteW,
                    height: AppSizes.dragHandleQuoteH,
                    decoration: BoxDecoration(
                      color: _FormPalette.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: AppIconSizes.hero),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppTypography.headlineSm,
                    fontWeight: FontWeight.w800,
                    color: _FormPalette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        height: 1.45,
                        color: _FormPalette.muted,
                      ),
                    ),
                  ),
                ),
                _LearnMoreLink(
                  accent: accent,
                  label: l10n.tripRequestDetailsLearnMore,
                  errorLabel: l10n.tripRequestDetailsLearnMoreError,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: AppSizes.buttonHeight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: const Color(0xFF1A140C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: Text(
                      l10n.tripAddonInfoClose,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
