import 'package:flutter/material.dart';

/// Aguja tipo alfiler (punta fina) mientras se mueve el mapa para confirmar un punto.
///
/// La **punta** debe coincidir con el centro del mapa (el lat/lng real). El
/// overlay se desplaza con [tipOffsetFromCenter] para no marcar el centro del widget.
class PassengerMapPickingNeedle extends StatelessWidget {
  const PassengerMapPickingNeedle({
    super.key,
    required this.forOrigin,
  });

  final bool forOrigin;

  static const double pinWidth = 40;
  static const double pinHeight = 76;

  /// Fracción vertical de la punta dentro del lienzo (0–1).
  static const double tipYFraction = 0.96;

  /// Cuánto subir el widget para que la punta quede en el centro del mapa.
  static double get tipOffsetFromCenter =>
      pinHeight * (tipYFraction - 0.5);

  @override
  Widget build(BuildContext context) {
    final fill =
        forOrigin ? const Color(0xFFF9AB00) : const Color(0xFF111111);
    final stroke =
        forOrigin ? const Color(0xFF111111) : const Color(0xFFF9AB00);
    return SizedBox(
      width: pinWidth,
      height: pinHeight,
      child: CustomPaint(
        painter: _FineMapPinPainter(fill: fill, stroke: stroke),
      ),
    );
  }
}

class _FineMapPinPainter extends CustomPainter {
  const _FineMapPinPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final tipY = size.height * PassengerMapPickingNeedle.tipYFraction;
    final headCenter = Offset(cx, size.height * 0.22);
    final headR = size.width * 0.28;

    final stem = Path()
      ..moveTo(cx, tipY)
      ..lineTo(cx + 2.1, headCenter.dy + headR * 0.55)
      ..lineTo(cx - 2.1, headCenter.dy + headR * 0.55)
      ..close();

    canvas.drawPath(
      Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(cx, tipY + 1.5),
            width: 10,
            height: 4,
          ),
        ),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    canvas.drawShadow(stem, Colors.black.withValues(alpha: 0.28), 4, true);
    canvas.drawPath(
      stem,
      Paint()
        ..isAntiAlias = true
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      stem,
      Paint()
        ..isAntiAlias = true
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      headCenter,
      headR + 1.2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(
      headCenter,
      headR,
      Paint()
        ..isAntiAlias = true
        ..color = fill,
    );
    canvas.drawCircle(
      headCenter,
      headR,
      Paint()
        ..isAntiAlias = true
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(
      headCenter,
      headR * 0.38,
      Paint()
        ..isAntiAlias = true
        ..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _FineMapPinPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.stroke != stroke;
  }
}
