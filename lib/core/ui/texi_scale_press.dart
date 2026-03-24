import 'package:flutter/material.dart';

import 'texi_motion.dart';

/// Envuelve botones o tarjetas con una **ligera escala al presionar** (estilo apps modernas).
///
/// No intercepta el tap: el hijo (p. ej. [FilledButton]) sigue recibiendo gestos.
/// Usar en CTAs principales para mantener la misma “línea” de micro-interacción.
class TexiScalePress extends StatefulWidget {
  const TexiScalePress({
    super.key,
    required this.child,
    this.minScale = 0.97,
    this.duration,
  });

  final Widget child;
  final double minScale;
  final Duration? duration;

  @override
  State<TexiScalePress> createState() => _TexiScalePressState();
}

class _TexiScalePressState extends State<TexiScalePress> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.duration ?? TexiMotion.fast,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.minScale).animate(
      CurvedAnimation(parent: _c, curve: TexiMotion.standard),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _c.forward(),
      onPointerUp: (_) => _c.reverse(),
      onPointerCancel: (_) => _c.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
