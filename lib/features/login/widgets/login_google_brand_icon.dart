import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo multicolor oficial de Google (asset SVG vectorial).
class LoginGoogleBrandIcon extends StatelessWidget {
  const LoginGoogleBrandIcon({super.key, this.size = 22});

  final double size;

  static const _assetPath = 'assets/icons/google_g.svg';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticsLabel: 'Google',
      ),
    );
  }
}
