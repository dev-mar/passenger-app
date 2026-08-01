import 'package:flutter/material.dart';

/// Icono estilizado “G” de Google (sin asset externo).
class LoginGoogleBrandIcon extends StatelessWidget {
  const LoginGoogleBrandIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final stroke = size.width * 0.18;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    arcPaint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      -0.45,
      1.6,
      false,
      arcPaint,
    );
    arcPaint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      1.15,
      1.05,
      false,
      arcPaint,
    );
    arcPaint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      2.2,
      0.95,
      false,
      arcPaint,
    );
    arcPaint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      3.15,
      1.05,
      false,
      arcPaint,
    );

    final barPaint = Paint()
      ..color = blue
      ..strokeWidth = stroke * 0.95
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width * 0.82, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
