import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Icono compacto orientable (flecha hacia el norte cuando `rotation` = 0).
Future<BitmapDescriptor> buildPassengerDriverOnTripMapIcon({
  double logicalSize = 56,
  Color fill = const Color(0xFF2E7D32),
  Color stroke = const Color(0xFFFFFFFF),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final w = logicalSize;
  final h = logicalSize;

  final strokePaint = Paint()
    ..color = stroke
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  final fillPaint = Paint()
    ..color = fill
    ..style = PaintingStyle.fill;

  final path = Path()
    ..moveTo(w * 0.5, h * 0.1)
    ..lineTo(w * 0.88, h * 0.82)
    ..lineTo(w * 0.5, h * 0.68)
    ..lineTo(w * 0.12, h * 0.82)
    ..close();

  canvas.drawPath(path, fillPaint);
  canvas.drawPath(path, strokePaint);

  final picture = recorder.endRecording();
  final img = await picture.toImage(logicalSize.ceil(), logicalSize.ceil());
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bd == null) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }
  return BitmapDescriptor.bytes(bd.buffer.asUint8List());
}
