import 'package:flutter/material.dart';

import '../../home/widgets/passenger_home_look.dart';

class BenefitsCanvasIcon extends StatelessWidget {
  const BenefitsCanvasIcon({
    super.key,
    required this.kind,
    this.size = 40,
    this.color = PassengerHomeLook.sky,
  });

  final BenefitsIconKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BenefitsIconPainter(kind: kind, color: color),
    );
  }
}

enum BenefitsIconKind { ticket, people, wallet, spark, check, gift, clock }

class _BenefitsIconPainter extends CustomPainter {
  _BenefitsIconPainter({required this.kind, required this.color});

  final BenefitsIconKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    switch (kind) {
      case BenefitsIconKind.ticket:
        _ticket(canvas, size, stroke, fill);
      case BenefitsIconKind.people:
        _people(canvas, size, stroke, fill);
      case BenefitsIconKind.wallet:
        _wallet(canvas, size, stroke, fill);
      case BenefitsIconKind.spark:
        _spark(canvas, size, stroke, fill);
      case BenefitsIconKind.check:
        _check(canvas, size, stroke, fill);
      case BenefitsIconKind.gift:
        _gift(canvas, size, stroke, fill);
      case BenefitsIconKind.clock:
        _clock(canvas, size, stroke, fill);
    }
  }

  void _ticket(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.14, size.height * 0.22, size.width * 0.72, size.height * 0.56),
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(r, fill);
    canvas.drawRRect(r, stroke);
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.28),
      Offset(size.width * 0.38, size.height * 0.72),
      stroke,
    );
  }

  void _people(Canvas canvas, Size size, Paint stroke, Paint fill) {
    canvas.drawCircle(Offset(size.width * 0.36, size.height * 0.32), size.width * 0.12, fill);
    canvas.drawCircle(Offset(size.width * 0.36, size.height * 0.32), size.width * 0.12, stroke);
    canvas.drawCircle(Offset(size.width * 0.64, size.height * 0.3), size.width * 0.1, fill);
    canvas.drawCircle(Offset(size.width * 0.64, size.height * 0.3), size.width * 0.1, stroke);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.36, size.height * 0.78),
        width: size.width * 0.46,
        height: size.height * 0.36,
      ),
      3.4,
      2.5,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.66, size.height * 0.76),
        width: size.width * 0.36,
        height: size.height * 0.3,
      ),
      3.5,
      2.3,
      false,
      stroke,
    );
  }

  void _wallet(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.16, size.height * 0.28, size.width * 0.68, size.height * 0.48),
      Radius.circular(size.width * 0.1),
    );
    canvas.drawRRect(r, fill);
    canvas.drawRRect(r, stroke);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.52), size.width * 0.07, stroke);
  }

  void _spark(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width * 0.6, size.height * 0.42)
      ..lineTo(size.width * 0.88, size.height * 0.5)
      ..lineTo(size.width * 0.6, size.height * 0.58)
      ..lineTo(size.width * 0.5, size.height * 0.88)
      ..lineTo(size.width * 0.4, size.height * 0.58)
      ..lineTo(size.width * 0.12, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.42)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _gift(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.38, size.width * 0.6, size.height * 0.42),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(box, fill);
    canvas.drawRRect(box, stroke);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.38),
      Offset(size.width * 0.5, size.height * 0.8),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.52),
      Offset(size.width * 0.8, size.height * 0.52),
      stroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.16, size.width * 0.22, size.height * 0.24),
      3.4,
      2.4,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.16, size.width * 0.22, size.height * 0.24),
      3.5,
      2.3,
      false,
      stroke,
    );
  }

  void _clock(Canvas canvas, Size size, Paint stroke, Paint fill) {
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.32, fill);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.32, stroke);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.34),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.66, size.height * 0.5),
      stroke,
    );
  }

  void _check(Canvas canvas, Size size, Paint stroke, Paint fill) {
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.36, fill);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.36, stroke);
    final path = Path()
      ..moveTo(size.width * 0.32, size.height * 0.52)
      ..lineTo(size.width * 0.46, size.height * 0.66)
      ..lineTo(size.width * 0.7, size.height * 0.36);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BenefitsIconPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.color != color;
  }
}
