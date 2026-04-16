import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Marcador de navegación moderno (rombo/flecha alargada), orientable con `rotation` del mapa.
Future<BitmapDescriptor> buildPassengerDriverOnTripMapIcon({
  double logicalSize = 56,
  Color fill = const Color(0xFF1565C0),
  Color stroke = const Color(0xFFFFFFFF),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final w = logicalSize;
  final h = logicalSize;
  final cx = w * 0.5;
  final cy = h * 0.52;

  // Rombo alargado (punta hacia arriba = frente del vehículo en bearing 0).
  final path = Path()
    ..moveTo(cx, h * 0.12)
    ..lineTo(w * 0.78, cy)
    ..quadraticBezierTo(w * 0.72, h * 0.78, cx, h * 0.88)
    ..quadraticBezierTo(w * 0.28, h * 0.78, w * 0.22, cy)
    ..close();

  canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 5, true);

  canvas.drawPath(
    path,
    Paint()
      ..color = fill
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2,
  );

  // Franja interior “vidrio”
  final inner = Path()
    ..moveTo(cx, h * 0.22)
    ..lineTo(w * 0.65, cy * 0.96)
    ..lineTo(cx, h * 0.72)
    ..lineTo(w * 0.35, cy * 0.96)
    ..close();
  canvas.drawPath(
    inner,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill,
  );

  // Punto de mira suave en el frente
  canvas.drawCircle(
    Offset(cx, h * 0.26),
    w * 0.06,
    Paint()
      ..color = stroke.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill,
  );
  canvas.drawCircle(
    Offset(cx, h * 0.26),
    w * 0.06,
    Paint()
      ..color = fill.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(
    logicalSize.ceil(),
    logicalSize.ceil(),
  );
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bd == null) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }
  return BitmapDescriptor.bytes(bd.buffer.asUint8List());
}

Future<BitmapDescriptor> buildPassengerWaypointMapPinIcon({
  double logicalSize = 56,
  required Color fill,
  Color stroke = const Color(0xFFFFFFFF),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final w = logicalSize;
  final h = logicalSize;
  final center = Offset(w * 0.5, h * 0.38);
  final radius = w * 0.24;

  final pinPath = Path()
    ..addOval(Rect.fromCircle(center: center, radius: radius))
    ..moveTo(w * 0.5, h * 0.93)
    ..lineTo(w * 0.68, h * 0.56)
    ..lineTo(w * 0.32, h * 0.56)
    ..close();

  canvas.drawShadow(pinPath, Colors.black.withValues(alpha: 0.35), 5, true);
  canvas.drawPath(
    pinPath,
    Paint()
      ..color = fill
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    pinPath,
    Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2,
  );
  canvas.drawCircle(
    center,
    radius * 0.45,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill,
  );
  final haloRadius = radius * 0.62;
  canvas.drawCircle(
    center,
    haloRadius,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );

  final pulseAngle = math.pi / 6;
  final accentPath = Path()
    ..moveTo(
      center.dx + math.cos(pulseAngle) * radius * 1.08,
      center.dy - math.sin(pulseAngle) * radius * 1.08,
    )
    ..arcTo(
      Rect.fromCircle(center: center, radius: radius * 1.08),
      -pulseAngle,
      pulseAngle * 1.4,
      false,
    );
  canvas.drawPath(
    accentPath,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8,
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(logicalSize.ceil(), logicalSize.ceil());
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bd == null) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
  return BitmapDescriptor.bytes(bd.buffer.asUint8List());
}
