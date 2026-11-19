import 'package:flutter/material.dart';

import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/phone/passenger_phone_countries.dart';
import '../../../core/theme/app_colors.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'passenger_auth_look.dart';

Future<LoginCountryDial?> showLoginCountryPicker({
  required BuildContext context,
  required LoginCountryDial selected,
}) {
  return showModalBottomSheet<LoginCountryDial>(
    context: context,
    backgroundColor: const Color(0xFF141210),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PassengerAuthLook.hairlineStrong,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.loginCountryPickerTitle,
                textAlign: TextAlign.center,
                style: PassengerAuthLook.sectionLabelStyle,
              ),
              const SizedBox(height: 8),
              for (final country in kLoginCountryChoices)
                _CountryRow(
                  country: country,
                  selected: country.dialCode == selected.dialCode,
                  onTap: () {
                    TexiUiFeedback.lightTap();
                    Navigator.of(ctx).pop(country);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final LoginCountryDial country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final flag = loginCountryFlagEmoji(country.isoCode);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (flag.isNotEmpty)
                  Text(flag, style: const TextStyle(fontSize: 22, height: 1)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    country.label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  country.dialCode,
                  style: const TextStyle(
                    color: PassengerAuthLook.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
