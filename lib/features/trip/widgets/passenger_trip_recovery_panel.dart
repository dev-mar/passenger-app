import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_safe_scrolling.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../gen_l10n/app_localizations.dart';

/// Overlay de recuperación de viaje activo: loading corto y, si no llega
/// el estado, diagnóstico de red/ubicación + reintentar (sin cancelar viaje).
class PassengerTripRecoveryPanel extends StatefulWidget {
  const PassengerTripRecoveryPanel({
    super.key,
    required this.onRetry,
    this.diagnosticAfter = const Duration(seconds: 8),
  });

  final VoidCallback onRetry;
  final Duration diagnosticAfter;

  @override
  State<PassengerTripRecoveryPanel> createState() =>
      _PassengerTripRecoveryPanelState();
}

class _PassengerTripRecoveryPanelState extends State<PassengerTripRecoveryPanel> {
  Timer? _timer;
  bool _showDiagnostic = false;
  bool _hasNetwork = true;
  bool _hasLocation = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.diagnosticAfter, () {
      if (!mounted) return;
      setState(() => _showDiagnostic = true);
      unawaited(_refreshDiagnostics());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshDiagnostics() async {
    if (!mounted) return;
    setState(() => _checking = true);
    var networkOk = true;
    var locationOk = true;
    try {
      final list = await Connectivity().checkConnectivity();
      networkOk = list.any((e) => e != ConnectivityResult.none);
    } catch (_) {
      networkOk = true;
    }
    try {
      final perm = await Geolocator.checkPermission();
      locationOk = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (locationOk) {
        locationOk = await Geolocator.isLocationServiceEnabled();
      }
    } catch (_) {
      locationOk = true;
    }
    if (!mounted) return;
    setState(() {
      _hasNetwork = networkOk;
      _hasLocation = locationOk;
      _checking = false;
    });
  }

  void _onRetry() {
    setState(() {
      _showDiagnostic = false;
      _checking = false;
    });
    _timer?.cancel();
    _timer = Timer(widget.diagnosticAfter, () {
      if (!mounted) return;
      setState(() => _showDiagnostic = true);
      unawaited(_refreshDiagnostics());
    });
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16 + AppSafeScrolling.systemNavBottom(context),
      child: Material(
        color: AppColors.surface,
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: _showDiagnostic
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.tripRecoveringStuckTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.tripRecoveringStuckBody,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _DiagRow(
                      ok: _hasNetwork,
                      label: l10n.tripRecoveringCheckNetwork,
                    ),
                    const SizedBox(height: 4),
                    _DiagRow(
                      ok: _hasLocation,
                      label: l10n.tripRecoveringCheckLocation,
                    ),
                    const SizedBox(height: 12),
                    TexiScalePress(
                      child: FilledButton(
                        onPressed: _checking ? null : _onRetry,
                        child: Text(l10n.tripRecoveringRetryCta),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.tripRecoveringStateTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
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

class _DiagRow extends StatelessWidget {
  const _DiagRow({required this.ok, required this.label});

  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.error_outline,
          size: 18,
          color: ok ? const Color(0xFF2E7D32) : AppColors.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
