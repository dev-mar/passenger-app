import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Imagen embebida `data:image/...;base64,...` (foto de perfil desde backend sin S3).
Uint8List? _decodeDataImageUrl(String url) {
  final u = url.trim();
  if (!u.startsWith('data:image')) return null;
  final comma = u.indexOf(',');
  if (comma <= 0 || comma >= u.length - 1) return null;
  final header = u.substring(0, comma).toLowerCase();
  final payload = u.substring(comma + 1);
  try {
    if (header.contains(';base64')) {
      return base64Decode(payload.replaceAll(RegExp(r'\s'), ''));
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Avatar circular con anillo degradado, foto de red o iniciales; animación de entrada suave.
class DriverAvatarPremium extends StatefulWidget {
  const DriverAvatarPremium({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.showRefreshingRing = false,
    this.size = 52,
  });

  final String displayName;
  final String? photoUrl;
  final bool showRefreshingRing;
  final double size;

  @override
  State<DriverAvatarPremium> createState() => _DriverAvatarPremiumState();
}

class _DriverAvatarPremiumState extends State<DriverAvatarPremium>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late AnimationController _ringCtrl;
  late Animation<double> _ringPulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _ringPulse = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut);
    if (widget.showRefreshingRing) {
      _ringCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant DriverAvatarPremium oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showRefreshingRing == oldWidget.showRefreshingRing) return;
    if (widget.showRefreshingRing) {
      _ringCtrl.repeat(reverse: true);
    } else {
      _ringCtrl.stop();
      _ringCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'TX';
    if (parts.length == 1) {
      final w = parts[0];
      return w.length >= 2 ? w.substring(0, 2).toUpperCase() : w[0].toUpperCase();
    }
    final a = parts[0].isNotEmpty ? parts[0][0] : '';
    final b = parts[1].isNotEmpty ? parts[1][0] : '';
    return ('$a$b').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final url = widget.photoUrl;
    final hasUrl = url != null && url.trim().isNotEmpty;
    final initials = _initials(widget.displayName);

    Widget inner() {
      return ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _InitialsDisc(initials: initials, size: s),
            if (hasUrl) ...[
              Builder(
                builder: (context) {
                  final trimmed = url.trim();
                  final mem = _decodeDataImageUrl(trimmed);
                  if (mem != null) {
                    return Image.memory(
                      mem,
                      width: s,
                      height: s,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    );
                  }
                  return Image.network(
                    trimmed,
                    width: s,
                    height: s,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      final visible = wasSynchronouslyLoaded || frame != null;
                      return AnimatedOpacity(
                        opacity: visible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: child,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ringPulse,
      builder: (context, _) {
        final ringOpacity = 0.14 + (_ringPulse.value * 0.2);
        return ScaleTransition(
          scale: _scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s + 6,
                height: s + 6,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.95),
                      AppColors.primary.withValues(alpha: 0.35),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: inner(),
                ),
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  opacity: widget.showRefreshingRing ? 1 : 0,
                  child: Container(
                    width: s + 9,
                    height: s + 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: ringOpacity),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InitialsDisc extends StatelessWidget {
  const _InitialsDisc({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
