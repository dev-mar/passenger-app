import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// PNG de tipo de servicio con rim-light suave para legibilidad en fondos oscuros.
///
/// Idle: luz de borde tenue siempre visible (champagne).
/// Seleccionado: rim más intenso con tinte primary (se mantiene el look actual).
class ServiceTypeVehicleImage extends StatelessWidget {
  const ServiceTypeVehicleImage({
    super.key,
    required this.asset,
    this.selected = false,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  final String asset;
  final bool selected;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  static const Color _champagne = Color(0xFFFFF4D6);

  @override
  Widget build(BuildContext context) {
    final Color rimColor = selected
        ? Color.lerp(_champagne, AppColors.primary, 0.42)!.withValues(
            alpha: 0.48,
          )
        : _champagne.withValues(alpha: 0.40);

    // Scale > 1 hace que el halo asome fuera del alpha del PNG (no se pierde
    // por el clip del SizedBox). Idle también necesita rim legible.
    final rimScale = selected ? 1.055 : 1.045;
    final softSigma = selected ? 1.75 : 1.55;
    final edgeSigma = selected ? 0.55 : 0.70;
    final edgeAlpha = selected ? 0.34 : 0.28;

    Widget painted({ColorFilter? colorFilter}) {
      Widget image = Image.asset(
        asset,
        fit: fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: colorFilter == null ? errorBuilder : null,
      );
      if (colorFilter != null) {
        image = ColorFiltered(colorFilter: colorFilter, child: image);
      }
      return image;
    }

    Widget rimLayer({
      required Color color,
      required double sigma,
      required double scale,
    }) {
      return Transform.scale(
        scale: scale,
        filterQuality: FilterQuality.high,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
            tileMode: TileMode.decal,
          ),
          child: painted(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // Halo ambiental (siempre).
          rimLayer(color: rimColor, sigma: softSigma, scale: rimScale),
          // Micro-borde más nítido: define silueta sin look “neón”.
          rimLayer(
            color: _champagne.withValues(alpha: edgeAlpha),
            sigma: edgeSigma,
            scale: selected ? 1.022 : 1.018,
          ),
          painted(),
        ],
      ),
    );
  }
}
