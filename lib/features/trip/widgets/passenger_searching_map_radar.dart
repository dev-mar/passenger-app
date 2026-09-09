import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Radar de matching anclado al pin de origen (coords de pantalla del mapa).
/// Solo reconstruye este overlay; no hace setState del [GoogleMap].
class PassengerSearchingMapRadarOverlay extends StatelessWidget {
  const PassengerSearchingMapRadarOverlay({
    super.key,
    required this.controller,
    required this.anchorListenable,
  });

  final Animation<double> controller;
  final ValueListenable<Offset?> anchorListenable;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[controller, anchorListenable]),
        builder: (context, _) {
          final anchor = anchorListenable.value;
          if (anchor == null) return const SizedBox.shrink();
          return CustomPaint(
            painter: _SearchingRadarPainter(controller.value, anchor),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SearchingRadarPainter extends CustomPainter {
  _SearchingRadarPainter(this.t, this.anchor);

  final double t;
  final Offset anchor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxR = 92.0;
    final radius = 26 + (maxR * t);
    final fade = (1 - t).clamp(0.0, 1.0);

    canvas.drawCircle(
      anchor,
      radius,
      Paint()
        ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.10 * fade)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      anchor,
      radius,
      Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.42 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      anchor,
      20,
      Paint()..color = const Color(0xFFFFC107).withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      anchor,
      20,
      Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _SearchingRadarPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.anchor != anchor;
}
