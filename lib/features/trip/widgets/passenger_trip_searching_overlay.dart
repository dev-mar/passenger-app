import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';

class _SearchingVisuals {
  static const Color accent = Color(0xFFFFC107);
  static const Color glow = Color(0xFF4FC3F7);
  static const Color softInk = Color(0xFFF2EDE4);
  static const Color muted = Color(0xFFB0A99C);
}

/// Overlay matching: 0–30s / 30–120s / ≥120s.
class TripSearchingDriverOverlay extends StatefulWidget {
  const TripSearchingDriverOverlay({
    super.key,
    required this.onCancel,
    required this.l10n,
    this.onContinue,
    this.onStage3Reached,
    this.initialStage = 1,
  });

  static const Duration stage2At = Duration(seconds: 30);
  static const Duration stage3At = Duration(seconds: 120);
  static const Duration rotateEvery = Duration(seconds: 10);
  static const Duration patienceAt = stage2At;
  static const Duration longWaitAt = stage3At;

  final VoidCallback onCancel;
  final AppLocalizations l10n;
  final VoidCallback? onContinue;
  final VoidCallback? onStage3Reached;

  /// Si ya estamos en hold (solicitud cancelada), arranca en etapa 3 sin reiniciar.
  final int initialStage;

  @override
  State<TripSearchingDriverOverlay> createState() =>
      _TripSearchingDriverOverlayState();
}

class _TripSearchingDriverOverlayState extends State<TripSearchingDriverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _stageTimer;
  Timer? _rotateTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  late int _stage;
  int _rotateIndex = 0;
  bool _offline = false;
  bool _locationOk = true;
  bool _stage3Notified = false;

  @override
  void initState() {
    super.initState();
    _stage = widget.initialStage.clamp(1, 3);
    _stage3Notified = _stage >= 3;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    if (_stage < 3) {
      final started = DateTime.now();
      // Si ya venimos en etapa 2, compensamos el reloj para no saltar atrás.
      final already = _stage >= 2 ? 30 : 0;
      _stageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _stage >= 3) return;
        final sec =
            DateTime.now().difference(started).inSeconds + already;
        final next = sec >= 120 ? 3 : (sec >= 30 ? 2 : 1);
        if (next != _stage) {
          setState(() => _stage = next);
          if (next == 3 && !_stage3Notified) {
            _stage3Notified = true;
            _stageTimer?.cancel();
            widget.onStage3Reached?.call();
          }
        }
      });
    } else {
      // Ya en hold: notificar cancel solo si aún no se hizo (no debería).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_stage3Notified) {
          _stage3Notified = true;
          widget.onStage3Reached?.call();
        }
      });
    }

    _rotateTimer = Timer.periodic(TripSearchingDriverOverlay.rotateEvery, (_) {
      if (!mounted) return;
      if (_stage < 2 || _stage >= 3) return;
      setState(() => _rotateIndex = (_rotateIndex + 1) % 3);
    });
    unawaited(_refreshConnectivity());
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) {
      unawaited(_refreshConnectivity());
    });
    unawaited(_refreshLocationPermission());
  }

  Future<void> _refreshConnectivity() async {
    try {
      final list = await Connectivity().checkConnectivity();
      final ok = list.any((e) => e != ConnectivityResult.none);
      if (!mounted) return;
      if (_offline == !ok) return;
      setState(() => _offline = !ok);
    } catch (_) {}
  }

  Future<void> _refreshLocationPermission() async {
    try {
      final perm = await Geolocator.checkPermission();
      final service = await Geolocator.isLocationServiceEnabled();
      final ok = service &&
          (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse);
      if (!mounted) return;
      if (_locationOk == ok) return;
      setState(() => _locationOk = ok);
    } catch (_) {}
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _rotateTimer?.cancel();
    _connectivitySub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _title {
    final l = widget.l10n;
    switch (_stage) {
      case 2:
        return l.tripSearchingStage2Title;
      case 3:
        return l.tripSearchingStage3Title;
      default:
        return l.searchingTitle;
    }
  }

  String get _body {
    final l = widget.l10n;
    switch (_stage) {
      case 2:
        return l.tripSearchingStage2Body;
      case 3:
        return l.tripSearchingStage3Body;
      default:
        return l.searchingSubtitle;
    }
  }

  String? get _rotating {
    if (_stage != 2) return null;
    final l = widget.l10n;
    switch (_rotateIndex % 3) {
      case 0:
        return l.tripSearchingRotateCheck2km;
      case 1:
        return l.tripSearchingRotateAvailability;
      default:
        return l.tripSearchingRotateOptimizeRoute;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, mathMax(bottomPad, 8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_offline || !_locationOk) ...[
            _StatusBanner(
              icon: _offline
                  ? Icons.wifi_off_rounded
                  : Icons.location_off_rounded,
              text: _offline
                  ? l10n.tripSearchingOfflineBanner
                  : l10n.tripSearchingLocationBanner,
              tone: _offline ? AppColors.error : const Color(0xFFFFB74D),
            ),
            const SizedBox(height: 8),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xE6121210),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _SearchingVisuals.accent.withValues(alpha: 0.32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              final t = _pulseController.value;
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _SearchingVisuals.accent
                                      .withValues(alpha: 0.14 + 0.1 * (1 - t)),
                                ),
                                child: const Icon(
                                  Icons.radar_rounded,
                                  size: 22,
                                  color: _SearchingVisuals.accent,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                child: Text(
                                  _title,
                                  key: ValueKey('t$_stage'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: _SearchingVisuals.softInk,
                                    letterSpacing: -0.2,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                child: Text(
                                  _body,
                                  key: ValueKey('b$_stage'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _SearchingVisuals.muted,
                                    fontSize: 12.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_rotating != null) ...[
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Align(
                          key: ValueKey('r$_rotateIndex'),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _rotating!,
                            style: TextStyle(
                              color: _SearchingVisuals.glow
                                  .withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      l10n.tripSearchingEtaHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _SearchingVisuals.softInk
                            .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_stage >= 3) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: TexiScalePress(
                          child: FilledButton(
                            onPressed: widget.onContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: _SearchingVisuals.accent,
                              foregroundColor: const Color(0xFF1A1408),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              l10n.tripSearchingContinueCta,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      TexiScalePress(
                        child: TextButton(
                          onPressed: widget.onCancel,
                          style: TextButton.styleFrom(
                            foregroundColor: _SearchingVisuals.muted,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(l10n.tripSearchingCancelRequest),
                        ),
                      ),
                    ] else
                      TexiScalePress(
                        child: TextButton(
                          onPressed: widget.onCancel,
                          style: TextButton.styleFrom(
                            foregroundColor: _SearchingVisuals.muted,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(l10n.tripSearchingCancelRequest),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double mathMax(double a, double b) => a > b ? a : b;

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.tone,
  });

  final IconData icon;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tone, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: tone,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
