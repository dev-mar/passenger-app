import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../gen_l10n/app_localizations.dart';

/// Reloj de recojo: usa `arrivedAt` del servidor + duraciones. La elegibilidad de
/// cancelar (más adelante) no se decide aquí.
enum PickupWaitPhase { waiting, grace, eligible }

class TripPickupWaitSpec {
  const TripPickupWaitSpec({
    required this.arrivedAt,
    required this.waitSec,
    required this.waitGraceSec,
  });

  final DateTime arrivedAt;
  final int waitSec;
  final int waitGraceSec;

  static TripPickupWaitSpec? tryParse(Map<dynamic, dynamic>? json) {
    if (json == null) return null;
    final arrivedRaw = json['arrivedAt'] ?? json['arrived_at'];
    final arrived = DateTime.tryParse('$arrivedRaw');
    if (arrived == null) return null;
    final waitMap = json['pickupWait'] ?? json['pickup_wait'];
    Map<String, dynamic>? wait;
    if (waitMap is Map) {
      wait = Map<String, dynamic>.from(waitMap);
    }
    int parseInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? fallback;
    }

    final waitSec = parseInt(
      json['waitSec'] ?? json['wait_sec'] ?? wait?['waitSec'] ?? wait?['wait_sec'],
      300,
    );
    final graceSec = parseInt(
      json['waitGraceSec'] ??
          json['wait_grace_sec'] ??
          wait?['waitGraceSec'] ??
          wait?['wait_grace_sec'],
      120,
    );
    return TripPickupWaitSpec(
      arrivedAt: arrived.toUtc(),
      waitSec: waitSec.clamp(60, 3600),
      waitGraceSec: graceSec.clamp(0, 1800),
    );
  }
}

class PickupWaitView {
  const PickupWaitView({
    required this.phase,
    required this.remainingSec,
  });

  final PickupWaitPhase phase;
  final int remainingSec;
}

PickupWaitView computePickupWaitView(
  TripPickupWaitSpec spec, {
  DateTime? now,
}) {
  final nowUtc = (now ?? DateTime.now()).toUtc();
  final elapsed = nowUtc.difference(spec.arrivedAt).inSeconds;
  final waitEnd = spec.waitSec;
  final graceEnd = spec.waitSec + spec.waitGraceSec;
  if (elapsed < waitEnd) {
    return PickupWaitView(
      phase: PickupWaitPhase.waiting,
      remainingSec: (waitEnd - elapsed).clamp(0, 24 * 3600),
    );
  }
  if (elapsed < graceEnd) {
    return PickupWaitView(
      phase: PickupWaitPhase.grace,
      remainingSec: (graceEnd - elapsed).clamp(0, 24 * 3600),
    );
  }
  return const PickupWaitView(phase: PickupWaitPhase.eligible, remainingSec: 0);
}

String formatPickupWaitClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final m = s ~/ 60;
  final r = s % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = r.toString().padLeft(2, '0');
  return '$mm:$ss';
}

TripPickupWaitSpec? pickupWaitSpecFromFields({
  required String? status,
  DateTime? arrivedAt,
  int? waitSec,
  int? waitGraceSec,
}) {
  if (status != 'arrived' || arrivedAt == null) return null;
  return TripPickupWaitSpec(
    arrivedAt: arrivedAt.toUtc(),
    waitSec: (waitSec ?? 300).clamp(60, 3600),
    waitGraceSec: (waitGraceSec ?? 120).clamp(0, 1800),
  );
}

String pickupWaitLabel(AppLocalizations l10n, PickupWaitView view) {
  switch (view.phase) {
    case PickupWaitPhase.waiting:
      return l10n.tripPickupWaitWaiting(formatPickupWaitClock(view.remainingSec));
    case PickupWaitPhase.grace:
      return l10n.tripPickupWaitGrace(formatPickupWaitClock(view.remainingSec));
    case PickupWaitPhase.eligible:
      return l10n.tripPickupWaitEnded;
  }
}

class PickupWaitClockStrip extends StatefulWidget {
  const PickupWaitClockStrip({
    super.key,
    required this.spec,
    this.accent,
  });

  final TripPickupWaitSpec spec;
  final Color? accent;

  @override
  State<PickupWaitClockStrip> createState() => _PickupWaitClockStripState();
}

class _PickupWaitClockStripState extends State<PickupWaitClockStrip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final view = computePickupWaitView(widget.spec);
    final accent = widget.accent ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom_rounded, size: 16, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              pickupWaitLabel(l10n, view),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PassengerEnRouteCta extends StatefulWidget {
  const PassengerEnRouteCta({
    super.key,
    required this.connected,
    required this.onPressed,
    this.cooldownUntilMs,
    this.errorCode,
  });

  final bool connected;
  final VoidCallback onPressed;
  final int? cooldownUntilMs;
  final String? errorCode;

  @override
  State<PassengerEnRouteCta> createState() => _PassengerEnRouteCtaState();
}

class _PassengerEnRouteCtaState extends State<PassengerEnRouteCta> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _cooldownLeftSec() {
    final until = widget.cooldownUntilMs;
    if (until == null || until <= 0) return 0;
    final left = ((until - DateTime.now().millisecondsSinceEpoch) / 1000)
        .ceil();
    return left > 0 ? left : 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final cooldownLeft = _cooldownLeftSec();
    final coolingDown = cooldownLeft > 0;
    final canSend = !coolingDown;
    String? helper;
    if (widget.errorCode == 'SOCKET' || widget.errorCode == 'NO_TOKEN') {
      helper = l10n.tripPassengerEnRouteNeedConnection;
    } else if (widget.errorCode == 'INVALID_STATUS_TRANSITION') {
      helper = l10n.tripPassengerEnRouteError;
    } else if (widget.errorCode != null && widget.errorCode!.isNotEmpty) {
      helper = l10n.tripPassengerEnRouteError;
    } else if (coolingDown) {
      helper = l10n.tripPassengerEnRouteCooldown(cooldownLeft);
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Tooltip(
            message: canSend
                ? l10n.tripPassengerEnRouteCta
                : l10n.tripPassengerEnRouteCooldown(cooldownLeft),
            child: SizedBox(
              height: AppSizes.buttonHeight,
              child: FilledButton.icon(
                onPressed: canSend
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onPressed();
                      }
                    : null,
                icon: Icon(
                  canSend
                      ? Icons.directions_walk_rounded
                      : Icons.timer_outlined,
                  size: AppIconSizes.lg,
                ),
                label: Text(l10n.tripPassengerEnRouteCta),
              ),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              helper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
