import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/locale_provider.dart';
import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'passenger_auth_look.dart';

/// ES | EN en el login. Si nadie eligió, sigue el idioma del teléfono.
class LoginLanguageSwitch extends ConsumerWidget {
  const LoginLanguageSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(localeProvider);
    final systemCode = WidgetsBinding.instance.platformDispatcher.locale
        .languageCode
        .toLowerCase();
    final active = chosen?.languageCode ?? (systemCode == 'en' ? 'en' : 'es');
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.settingsLanguage,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: PassengerAuthLook.hairlineStrong),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageSegment(
                label: 'ES',
                selected: active == 'es',
                onTap: () => _select(context, const Locale('es')),
              ),
              _LanguageSegment(
                label: 'EN',
                selected: active == 'en',
                onTap: () => _select(context, const Locale('en')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, Locale locale) {
    TexiUiFeedback.lightTap();
    applyPassengerLocale(ProviderScope.containerOf(context), locale);
  }
}

class _LanguageSegment extends StatelessWidget {
  const _LanguageSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 40,
          width: 48,
          decoration: BoxDecoration(
            color: selected ? PassengerAuthLook.goldWash : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : PassengerAuthLook.muted,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
