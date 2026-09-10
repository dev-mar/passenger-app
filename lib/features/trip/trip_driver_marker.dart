import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Asset del marcador del vehículo en mapa (pasajero).
///
/// El PNG debe mirar **hacia arriba** (frente del auto = bearing 0).
const String kPassengerDriverOnTripMapIconAsset =
    'assets/icons/map_driver_car.png';

/// Tamaño lógico del auto en mapa.
///
/// Los pines origen/destino se dibujan a 56 px; el auto top-down llena más
/// el lienzo, así que 48 mantiene paridad visual sin saturar el mapa.
const double kPassengerDriverOnTripMapIconLogicalSize = 48;

/// Marcador del conductor en viaje: PNG personalizado, orientable con `rotation`.
Future<BitmapDescriptor> buildPassengerDriverOnTripMapIcon({
  double logicalSize = kPassengerDriverOnTripMapIconLogicalSize,
}) async {
  try {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(),
      kPassengerDriverOnTripMapIconAsset,
      width: logicalSize,
      height: logicalSize,
      bitmapScaling: MapBitmapScaling.auto,
    );
  } catch (_) {
    return _buildPassengerDriverOnTripMapIconFallback(logicalSize: logicalSize);
  }
}

/// Fallback vectorial (rombo) si el asset no carga.
Future<BitmapDescriptor> _buildPassengerDriverOnTripMapIconFallback({
  double logicalSize = kPassengerDriverOnTripMapIconLogicalSize,
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
  return BitmapDescriptor.bytes(
    bd.buffer.asUint8List(),
    width: logicalSize,
    height: logicalSize,
  );
}

enum PassengerWaypointPinStyle { pickupPerson, destinationX }

/// Amarillo / negro de marca.
const Color kPassengerPinBrandYellow = Color(0xFFF9AB00);
const Color kPassengerPinBrandBlack = Color(0xFF111111);

/// Punta del pin en la textura (0–1). El Marker debe usar el mismo ancla.
const double kPassengerWaypointPinTipAnchorY = 0.97;

const double kPassengerMapPinPixelRatio = 3;

double _waypointPinPixelRatio() {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return kPassengerMapPinPixelRatio;
  return math.max(kPassengerMapPinPixelRatio, views.first.devicePixelRatio);
}

Future<BitmapDescriptor> buildPassengerWaypointMapPinIcon({
  double logicalWidth = 54,
  double logicalHeight = 72,
  required Color fill,
  Color? stroke,
  PassengerWaypointPinStyle style = PassengerWaypointPinStyle.pickupPerson,
}) async {
  final outline = stroke ??
      (style == PassengerWaypointPinStyle.destinationX
          ? kPassengerPinBrandYellow
          : kPassengerPinBrandBlack);
  final dpr = _waypointPinPixelRatio();
  final pixelW = (logicalWidth * dpr).ceil();
  final pixelH = (logicalHeight * dpr).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(dpr);
  _paintModernWaypointPin(
    canvas,
    Size(logicalWidth, logicalHeight),
    fill: fill,
    stroke: outline,
    style: style,
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(pixelW, pixelH);
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bd == null) {
    return BitmapDescriptor.defaultMarkerWithHue(
      style == PassengerWaypointPinStyle.destinationX
          ? BitmapDescriptor.hueRed
          : BitmapDescriptor.hueYellow,
    );
  }
  return BitmapDescriptor.bytes(
    bd.buffer.asUint8List(),
    width: logicalWidth,
    height: logicalHeight,
    imagePixelRatio: dpr,
  );
}

void _paintModernWaypointPin(
  Canvas canvas,
  Size size, {
  required Color fill,
  required Color stroke,
  required PassengerWaypointPinStyle style,
}) {
  final w = size.width;
  final h = size.height;
  final cx = w * 0.5;
  final headCenter = Offset(cx, h * 0.34);
  final headR = w * 0.30;

  final pinPath = Path()
    ..moveTo(cx, h * 0.97)
    ..quadraticBezierTo(
      cx + headR * 0.42,
      headCenter.dy + headR * 0.92,
      cx + headR,
      headCenter.dy,
    )
    ..arcToPoint(
      Offset(cx - headR, headCenter.dy),
      radius: Radius.circular(headR),
      clockwise: true,
    )
    ..quadraticBezierTo(
      cx - headR * 0.42,
      headCenter.dy + headR * 0.92,
      cx,
      h * 0.97,
    )
    ..close();

  canvas.drawShadow(pinPath, Colors.black.withValues(alpha: 0.38), 6, true);
  canvas.drawPath(
    pinPath,
    Paint()
      ..isAntiAlias = true
      ..color = fill
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    pinPath,
    Paint()
      ..isAntiAlias = true
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round,
  );

  canvas.drawCircle(
    headCenter,
    headR * 0.62,
    Paint()
      ..isAntiAlias = true
      ..color = Colors.white
      ..style = PaintingStyle.fill,
  );
  canvas.drawCircle(
    headCenter,
    headR * 0.62,
    Paint()
      ..isAntiAlias = true
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );

  if (style == PassengerWaypointPinStyle.pickupPerson) {
    _paintWavingPerson(canvas, headCenter, headR * 0.52, stroke);
  } else {
    _paintDestinationX(canvas, headCenter, headR * 0.36, stroke);
  }
}

void _paintWavingPerson(Canvas canvas, Offset center, double r, Color color) {
  final paint = Paint()
    ..isAntiAlias = true
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(2.2, r * 0.22)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final fill = Paint()
    ..isAntiAlias = true
    ..color = color
    ..style = PaintingStyle.fill;

  canvas.drawCircle(Offset(center.dx, center.dy - r * 0.42), r * 0.22, fill);
  canvas.drawLine(
    Offset(center.dx, center.dy - r * 0.16),
    Offset(center.dx, center.dy + r * 0.28),
    paint,
  );
  canvas.drawLine(
    Offset(center.dx, center.dy + r * 0.02),
    Offset(center.dx - r * 0.38, center.dy + r * 0.22),
    paint,
  );
  canvas.drawLine(
    Offset(center.dx, center.dy),
    Offset(center.dx + r * 0.46, center.dy - r * 0.48),
    paint,
  );
  canvas.drawLine(
    Offset(center.dx, center.dy + r * 0.28),
    Offset(center.dx - r * 0.26, center.dy + r * 0.62),
    paint,
  );
  canvas.drawLine(
    Offset(center.dx, center.dy + r * 0.28),
    Offset(center.dx + r * 0.24, center.dy + r * 0.62),
    paint,
  );
}

void _paintDestinationX(Canvas canvas, Offset center, double r, Color color) {
  final paint = Paint()
    ..isAntiAlias = true
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(2.6, r * 0.38)
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    Offset(center.dx - r, center.dy - r),
    Offset(center.dx + r, center.dy + r),
    paint,
  );
  canvas.drawLine(
    Offset(center.dx + r, center.dy - r),
    Offset(center.dx - r, center.dy + r),
    paint,
  );
}
