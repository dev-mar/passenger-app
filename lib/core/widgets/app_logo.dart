import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// Logo de la app. Usa el PNG definido en [AppAssets.logo].
/// Si más adelante añades logo.svg, aquí se puede cambiar a SvgPicture con fallback a PNG.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width = 120,
    this.height = 120,
    this.fit = BoxFit.contain,
  });

  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.local_taxi_rounded,
        size: width * 0.8,
        color: AppColors.primary,
      ),
    );
  }
}
