import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';

/// Look exclusivo del embudo de autenticación (puede apartarse de la paleta base).
class PassengerAuthLook {
  PassengerAuthLook._();

  static const Color ink = Color(0xFF070605);
  static const Color panel = Color(0xE3181511);
  static const Color panelLift = Color(0xF21C1914);
  static const Color hairline = Color(0x22FFFFFF);
  static const Color hairlineStrong = Color(0x33FFFFFF);
  static const Color goldWash = Color(0x26FFD600);
  static const Color muted = Color(0xFF9A948A);

  static const double fieldHeight = 56;
  static const double actionHeight = 54;
  static const double titleSize = 24;
  static const double bodySize = 14;

  static const BorderRadius panelRadius =
      BorderRadius.all(Radius.circular(18));

  static BoxDecoration get panelDecoration => BoxDecoration(
        borderRadius: panelRadius,
        color: panel,
        border: Border.all(color: hairline),
      );

  static BoxDecoration highlightedDecoration(Color accent) => BoxDecoration(
        borderRadius: panelRadius,
        color: accent.withValues(alpha: 0.1),
        border: Border.all(color: accent.withValues(alpha: 0.42), width: 1.2),
      );

  static TextStyle titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
              height: 1.12,
              fontSize: titleSize,
            ) ??
        const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: titleSize,
        );
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: muted,
              height: 1.4,
              fontSize: bodySize,
              fontWeight: FontWeight.w400,
            ) ??
        const TextStyle(color: muted, fontSize: bodySize, height: 1.4);
  }

  static const TextStyle sectionLabelStyle = TextStyle(
    color: muted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
  );
}

class PassengerAuthHeadline extends StatelessWidget {
  const PassengerAuthHeadline({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      textAlign: TextAlign.center,
      style: PassengerAuthLook.titleStyle(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trailing == null)
          titleText
        else
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(child: titleText),
              SizedBox(width: 40, child: Center(child: trailing)),
            ],
          ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: PassengerAuthLook.subtitleStyle(context),
          ),
        ],
      ],
    );
  }
}

class PassengerAuthFieldPanel extends StatelessWidget {
  const PassengerAuthFieldPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: PassengerAuthLook.panelDecoration,
      child: Padding(padding: padding, child: child),
    );
  }
}

class PassengerAuthDialChip extends StatelessWidget {
  const PassengerAuthDialChip({
    super.key,
    required this.flagEmoji,
    required this.dialCode,
    required this.countryLabel,
  });

  final String flagEmoji;
  final String dialCode;
  final String countryLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: countryLabel,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: PassengerAuthLook.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flagEmoji.isNotEmpty) ...[
              Text(flagEmoji, style: const TextStyle(fontSize: 18, height: 1)),
              const SizedBox(width: 6),
            ],
            Text(
              dialCode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PassengerAuthBackButton extends StatelessWidget {
  const PassengerAuthBackButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            minimumSize: const Size(44, 44),
            maximumSize: const Size(44, 44),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
      ),
    );
  }
}

class PassengerAuthPrimaryButton extends StatelessWidget {
  const PassengerAuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PassengerAuthLook.actionHeight,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
