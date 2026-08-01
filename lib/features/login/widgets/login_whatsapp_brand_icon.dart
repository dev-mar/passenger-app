import 'package:flutter/material.dart';

/// Icono estilizado WhatsApp (UX auth; no asset de marca embebido).
class LoginWhatsAppBrandIcon extends StatelessWidget {
  const LoginWhatsAppBrandIcon({
    super.key,
    this.size = 28,
  });

  final double size;

  static const Color brandGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.52;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brandGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: brandGreen.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(
        Icons.chat_rounded,
        color: Colors.white,
        size: inner,
      ),
    );
  }
}
