import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../../gen_l10n/app_localizations.dart';

class TexiBrandLoader extends StatefulWidget {
  const TexiBrandLoader({
    super.key,
    this.message,
    this.logoAsset = AppAssets.logo,
    this.showPinLabels = true,
  });

  final String? message;

  final String logoAsset;

  final bool showPinLabels;

  @override
  State<TexiBrandLoader> createState() => _TexiBrandLoaderState();
}

class _TexiBrandLoaderState extends State<TexiBrandLoader>
    with TickerProviderStateMixin {
  static const Color _canvas = Color(0xFF050505);
  static const Color _gold = Color(0xFFFACC15);
  static const Color _goldDeep = Color(0xFFEAB308);
  static const Color _goldBright = Color(0xFFFDE047);

  late final AnimationController _radar;
  late final AnimationController _route;
  late final AnimationController _logo;
  late final AnimationController _grid;
  late final AnimationController _pinFloat;
  late final AnimationController _pulse;
  late final AnimationController _enter;
  late final Listenable _tick;

  @override
  void initState() {
    super.initState();
    _radar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
    _route = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _logo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _grid = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _pinFloat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _tick = Listenable.merge([
      _radar,
      _route,
      _logo,
      _grid,
      _pinFloat,
      _pulse,
      _enter,
    ]);
    _enter.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _radar.value = 0;
      _route.value = 0.72;
      _logo.value = 0;
      _grid.value = 0;
      _pinFloat.value = 0;
      _pulse.value = 0;
      _enter.value = 1;
      return;
    }
    if (!_radar.isAnimating) {
      final narrow = MediaQuery.sizeOf(context).width < 640;
      _radar.duration = Duration(milliseconds: narrow ? 6500 : 5500);
      _radar.repeat();
      _route.repeat();
      _logo.repeat(reverse: true);
      _grid.repeat();
      _pinFloat.repeat(reverse: true);
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _radar.dispose();
    _route.dispose();
    _logo.dispose();
    _grid.dispose();
    _pinFloat.dispose();
    _pulse.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final cell = size.width < 640 ? 44.0 : 56.0;
    final showSm = size.width >= 640;
    final showMd = size.width >= 768;
    final showLg = size.width >= 1024;
    final logoWidth = size.width < 360
        ? 112.0
        : size.width < 600
        ? 128.0
        : 148.0;
    final a11y = l10n?.texiBrandLoaderA11y ?? 'Cargando TEXIAPP';
    final driverLabel = widget.showPinLabels
        ? (l10n?.texiBrandLoaderDriverPin ?? 'Conductor disponible')
        : null;
    final passengerLabel = widget.showPinLabels
        ? (l10n?.texiBrandLoaderPassengerPin ?? 'Pasajero')
        : null;
    final message = widget.message?.trim();

    return Semantics(
      label: a11y,
      liveRegion: true,
      child: ColoredBox(
        color: _canvas,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic),
          child: AnimatedBuilder(
            animation: _tick,
            builder: (context, _) {
              final radarTurns = reduce ? 0.0 : _radar.value;
              final gridShift = reduce ? 0.0 : _grid.value * cell;
              final floatY = reduce ? 0.0 : -5.0 * _pinFloat.value;
              final logoScale = reduce ? 1.0 : 1.0 + (0.055 * _logo.value);
              final logoGlow = reduce ? 0.16 : 0.16 + (0.14 * _logo.value);
              final routeT = reduce ? 0.72 : _route.value;
              final pulseT = reduce ? 0.0 : _pulse.value;
              final pulseT2 = reduce ? 0.0 : (pulseT + 0.42) % 1.0;

              return Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.08),
                        radius: 0.85,
                        colors: [Color(0x24FACC15), Color(0x00050505)],
                        stops: [0.0, 0.55],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.85, -0.7),
                        radius: 0.55,
                        colors: [Color(0x12FACC15), Color(0x00050505)],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.85, 0.75),
                        radius: 0.5,
                        colors: [Color(0x0FFACC15), Color(0x00050505)],
                      ),
                    ),
                  ),
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) {
                      return const RadialGradient(
                        colors: [
                          Colors.white,
                          Color(0xBFFFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [0.2, 0.55, 1],
                      ).createShader(rect);
                    },
                    child: CustomPaint(
                      painter: _MapGridPainter(offset: gridShift, cell: cell),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  CustomPaint(
                    painter: const _StreetLinesPainter(),
                    child: const SizedBox.expand(),
                  ),
                  _RadarLayer(turns: radarTurns),
                  CustomPaint(
                    painter: _RoutePainter(t: routeT),
                    child: const SizedBox.expand(),
                  ),
                  _MapPin(
                    left: 0.18,
                    top: 0.72,
                    isDriver: true,
                    active: true,
                    floatY: floatY,
                    pulseT: pulseT,
                    pulseT2: pulseT2,
                    label: driverLabel,
                  ),
                  _MapPin(
                    left: 0.78,
                    top: 0.28,
                    isDriver: false,
                    active: true,
                    floatY: floatY,
                    pulseT: pulseT,
                    pulseT2: pulseT2,
                    label: passengerLabel,
                    delayFactor: 0.35,
                  ),
                  if (showSm)
                    _MapPin(
                      left: 0.12,
                      top: 0.25,
                      isDriver: true,
                      floatY: floatY,
                      delayFactor: 0.15,
                    ),
                  _MapPin(
                    left: 0.67,
                    top: 0.72,
                    isDriver: true,
                    floatY: floatY,
                    delayFactor: 0.45,
                  ),
                  if (showMd)
                    _MapPin(
                      left: 0.88,
                      top: 0.58,
                      isDriver: true,
                      floatY: floatY,
                      delayFactor: 0.7,
                    ),
                  _MapPin(
                    left: 0.34,
                    top: 0.20,
                    isDriver: false,
                    floatY: floatY,
                    delayFactor: 0.3,
                  ),
                  if (showSm)
                    _MapPin(
                      left: 0.42,
                      top: 0.78,
                      isDriver: false,
                      floatY: floatY,
                      delayFactor: 0.58,
                    ),
                  if (showLg)
                    _MapPin(
                      left: 0.89,
                      top: 0.18,
                      isDriver: false,
                      floatY: floatY,
                      delayFactor: 0.8,
                    ),
                  Center(
                    child: Transform.scale(
                      scale: logoScale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: logoGlow),
                              blurRadius: 28 + (14 * _logo.value),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          widget.logoAsset,
                          width: logoWidth,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          semanticLabel: l10n?.appName ?? 'TEXIAPP',
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                  if (message != null && message.isNotEmpty)
                    Positioned(
                      left: 28,
                      right: 28,
                      bottom: 36 + MediaQuery.paddingOf(context).bottom,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.2,
                          shadows: const [
                            Shadow(color: Color(0xCC000000), blurRadius: 12),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RadarLayer extends StatelessWidget {
  const _RadarLayer({required this.turns});

  final double turns;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final vmax = math.max(constraints.maxWidth, constraints.maxHeight);
          final side = vmax * 1.3;
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _radarRing(side, 0.07),
                  _radarRing(side, 0.20),
                  _radarRing(side, 0.33),
                  _radarRing(side, 0.46),
                  Center(
                    child: Container(
                      width: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            _TexiBrandLoaderState._gold.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _TexiBrandLoaderState._gold.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(side * 0.03),
                    child: Transform.rotate(
                      angle: turns * math.pi * 2,
                      child: const CustomPaint(
                        painter: _RadarSweepPainter(),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _radarRing(double side, double insetFraction) {
    return Padding(
      padding: EdgeInsets.all(side * insetFraction),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _TexiBrandLoaderState._gold.withValues(
              alpha: 0.07 + insetFraction * 0.12,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  const _RadarSweepPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: const [
          Color(0x40FACC15),
          Color(0x21FACC15),
          Color(0x0BFACC15),
          Color(0x00FACC15),
          Color(0x00FACC15),
        ],
        stops: const [0.0, 0.078, 0.156, 0.239, 1.0],
      ).createShader(rect);
    canvas.saveLayer(rect, Paint());
    canvas.drawCircle(center, radius, paint);
    final mask = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0x00000000), Color(0x80000000), Color(0xFF000000)],
        stops: const [0.0, 0.18, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.dstIn;
    canvas.drawCircle(center, radius, mask);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.offset, required this.cell});

  final double offset;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x09FACC15)
      ..strokeWidth = 1;
    final shift = offset % cell;
    for (var x = -cell + shift; x <= size.width + cell; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = -cell + shift; y <= size.height + cell; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.cell != cell;
  }
}

class _StreetLinesPainter extends CustomPainter {
  const _StreetLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _stroke(
      canvas,
      size,
      left: -0.10,
      top: 0.23,
      widthFactor: 0.55,
      degrees: 15,
      color: const Color(0x1AFFFFFF),
    );
    _stroke(
      canvas,
      size,
      left: 0.50,
      top: 0.30,
      widthFactor: 0.65,
      degrees: -18,
      color: const Color(0x1AFFFFFF),
    );
    _stroke(
      canvas,
      size,
      left: -0.10,
      top: 0.82,
      widthFactor: 0.75,
      degrees: -8,
      color: const Color(0x1AFACC15),
    );
    _stroke(
      canvas,
      size,
      left: 0.53,
      top: 0.66,
      widthFactor: 0.65,
      degrees: 12,
      color: const Color(0x1AFFFFFF),
    );
  }

  void _stroke(
    Canvas canvas,
    Size size, {
    required double left,
    required double top,
    required double widthFactor,
    required double degrees,
    required Color color,
  }) {
    final origin = Offset(size.width * left, size.height * top);
    final length = size.width * widthFactor;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(degrees * math.pi / 180);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0x00FFFFFF), color, const Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, length, 2));
    canvas.drawRect(Rect.fromLTWH(0, 0, length, 1.2), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.t});

  final double t;

  static Path routePath(Size size) {
    final sx = size.width / 1000;
    final sy = size.height / 700;
    return Path()
      ..moveTo(180 * sx, 504 * sy)
      ..cubicTo(290 * sx, 430 * sy, 360 * sx, 520 * sy, 470 * sx, 420 * sy)
      ..cubicTo(580 * sx, 320 * sy, 630 * sx, 300 * sy, 780 * sx, 196 * sy);
  }

  double get _draw {
    if (t <= 0.72) return (t / 0.72).clamp(0.0, 1.0);
    return 1;
  }

  double get _opacity {
    if (t < 0.18) return 0.25 + 0.75 * (t / 0.18);
    if (t < 0.86) return 1;
    return (1 - ((t - 0.86) / 0.14)).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = routePath(size);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final length = metric.length;
    if (length <= 0) return;

    final bed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x1FFACC15);
    canvas.drawPath(path, bed);

    final drawn = metric.extractPath(0, length * _draw);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = _TexiBrandLoaderState._gold.withValues(alpha: 0.28 * _opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(drawn, glow);

    final lineSolid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.18, size.height * 0.72),
        Offset(size.width * 0.78, size.height * 0.28),
        [
          _TexiBrandLoaderState._goldDeep.withValues(alpha: _opacity),
          _TexiBrandLoaderState._gold.withValues(alpha: _opacity),
          _TexiBrandLoaderState._goldBright.withValues(alpha: _opacity),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawPath(drawn, lineSolid);

    final pos = metric.getTangentForOffset(length * t)?.position;
    if (pos == null) return;
    final halo = Paint()
      ..color = const Color(0x99FDE047)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(pos, 17, halo);
    canvas.drawCircle(pos, 9, Paint()..color = const Color(0xCCFDE047));
    canvas.drawCircle(pos, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.t != t;
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.left,
    required this.top,
    required this.isDriver,
    required this.floatY,
    this.active = false,
    this.pulseT = 0,
    this.pulseT2 = 0,
    this.label,
    this.delayFactor = 0,
  });

  final double left;
  final double top;
  final bool isDriver;
  final bool active;
  final double floatY;
  final double pulseT;
  final double pulseT2;
  final String? label;
  final double delayFactor;

  @override
  Widget build(BuildContext context) {
    final dy = floatY * (1 - delayFactor * 0.35);
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment(left * 2 - 1, top * 2 - 1),
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (active) ...[
                      _PulseRing(t: pulseT),
                      _PulseRing(t: pulseT2, faint: true),
                    ],
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDriver
                            ? const Color(0xFFFACC15)
                            : const Color(0xFF0B111D),
                        border: Border.all(
                          color: isDriver
                              ? const Color(0xFFFDE047)
                              : Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDriver
                                ? const Color(0x73FACC15)
                                : const Color(0x29FFFFFF),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Icon(
                        isDriver
                            ? Icons.directions_car_rounded
                            : Icons.person_rounded,
                        size: 20,
                        color: isDriver ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 26,
                  color: isDriver ? const Color(0xFFFACC15) : Colors.white,
                ),
              ),
              if (label != null && label!.isNotEmpty)
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xB3000000),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        label!.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.t, this.faint = false});

  final double t;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    final scale = 0.55 + (1.35 * t);
    final opacity = t < 0.75
        ? (0.8 - (0.66 * (t / 0.75)))
        : (0.14 * (1 - ((t - 0.75) / 0.25)));
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _TexiBrandLoaderState._gold.withValues(
              alpha: (faint ? 0.35 : 0.50) * opacity.clamp(0.0, 1.0),
            ),
          ),
        ),
      ),
    );
  }
}
