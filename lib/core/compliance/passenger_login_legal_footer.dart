import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../gen_l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_ui_tokens.dart';
import 'passenger_legal_links.dart';

/// Aviso legal sutil en login / onboarding (Play Store: privacidad accesible sin sesión).
///
/// - [PassengerLegalNoticeTone.methodChoice]: pantalla inicial de elección de método.
/// - [PassengerLegalNoticeTone.authContinue]: teléfono / Google (mayoría de edad + políticas).
/// - [PassengerLegalNoticeTone.emphasized]: cierre de registro de perfil.
enum PassengerLegalNoticeTone {
  methodChoice,
  authContinue,
  emphasized,
}

class PassengerLoginLegalFooter extends StatefulWidget {
  const PassengerLoginLegalFooter({
    super.key,
    this.textColor,
    this.tone = PassengerLegalNoticeTone.methodChoice,
  });

  final Color? textColor;
  final PassengerLegalNoticeTone tone;

  @override
  State<PassengerLoginLegalFooter> createState() =>
      _PassengerLoginLegalFooterState();
}

class _PassengerLoginLegalFooterState extends State<PassengerLoginLegalFooter> {
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()
      ..onTap = () {
        HapticFeedback.selectionClick();
        openPassengerPrivacyPolicy(context);
      };
    _termsTap = TapGestureRecognizer()
      ..onTap = () {
        HapticFeedback.selectionClick();
        openPassengerTerms(context);
      };
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = widget.textColor ?? AppColors.textSecondary.withValues(alpha: 0.92);
    final linkColor = AppColors.primary.withValues(alpha: 0.92);
    final emphasized = widget.tone == PassengerLegalNoticeTone.emphasized;

    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: secondary,
          height: 1.35,
          fontSize: emphasized ? 12.5 : AppTypography.captionAlt,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        );

    final linkStyle = baseStyle?.copyWith(
      color: linkColor,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: linkColor.withValues(alpha: 0.35),
      decorationThickness: 1,
    );

    final prefix = switch (widget.tone) {
      PassengerLegalNoticeTone.methodChoice => l10n.passengerLegalLoginPrefix,
      PassengerLegalNoticeTone.authContinue =>
        l10n.passengerLegalAuthContinuePrefix,
      PassengerLegalNoticeTone.emphasized =>
        l10n.passengerLegalRegistrationPrefix,
    };

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: prefix, style: baseStyle),
          TextSpan(
            text: l10n.passengerLegalPrivacyPolicy,
            style: linkStyle,
            recognizer: _privacyTap,
          ),
          TextSpan(text: l10n.passengerLegalLoginConjunction, style: baseStyle),
          TextSpan(
            text: l10n.passengerLegalTermsOfService,
            style: linkStyle,
            recognizer: _termsTap,
          ),
          TextSpan(text: '.', style: baseStyle),
        ],
      ),
      textAlign: TextAlign.center,
      softWrap: true,
    );
  }
}
