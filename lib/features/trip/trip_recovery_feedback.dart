import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/ui/texi_motion.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../gen_l10n/app_localizations.dart';
import 'trip_request_state.dart';

/// Limpia el seguimiento del SnackBar de recuperación (p. ej. al terminar o cancelar el viaje).
void clearTripRecoverySnackTracking(WidgetRef ref) {
  ref.read(tripRecoverySnackShownForTripIdProvider.notifier).state = null;
}

/// Igual que [clearTripRecoverySnackTracking], para uso desde código sin [WidgetRef] (p. ej. apertura FCM).
void clearTripRecoverySnackTrackingForContainer(ProviderContainer container) {
  container.read(tripRecoverySnackShownForTripIdProvider.notifier).state = null;
}

/// Muestra el aviso solo una vez por [tripId] mientras siga activo el mismo pedido.
void showTripRecoveredSnackBarOncePerTrip(
  WidgetRef ref,
  BuildContext context,
  String tripId,
) {
  if (tripId.isEmpty) return;
  final shown = ref.read(tripRecoverySnackShownForTripIdProvider);
  if (shown == tripId) return;
  ref.read(tripRecoverySnackShownForTripIdProvider.notifier).state = tripId;
  showTripRecoveredSnackBar(context);
}

/// SnackBar flotante Material 3: mensaje breve, estética sobria y sonido discreto.
void showTripRecoveredSnackBar(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  TexiUiFeedback.softImpact();
  unawaited(TexiUiFeedback.instance.playSoftChime());

  final bottomInset = MediaQuery.paddingOf(context).bottom;
  final snack = Theme.of(context).snackBarTheme;

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: snack.behavior ?? SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      elevation: snack.elevation ?? 12,
      shape: snack.shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
          ),
      backgroundColor: snack.backgroundColor ?? cs.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      duration: const Duration(seconds: 4),
      content: _TripRecoverySnackBody(
        onDismiss: () => messenger.hideCurrentSnackBar(),
      ),
    ),
  );
}

class _TripRecoverySnackBody extends StatefulWidget {
  const _TripRecoverySnackBody({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<_TripRecoverySnackBody> createState() => _TripRecoverySnackBodyState();
}

class _TripRecoverySnackBodyState extends State<_TripRecoverySnackBody>
    with TickerProviderStateMixin {
  late AnimationController _entry;
  late AnimationController _pulse;
  late Animation<double> _entryScale;
  late Animation<double> _entryFade;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: TexiMotion.emphasized,
    );
    _pulse = AnimationController(
      vsync: this,
      duration: TexiMotion.pulseLoop,
    );
    _entryScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _entry, curve: TexiMotion.emphasizedCurve),
    );
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic),
    );
    _entry.forward().then((_) {
      if (mounted) {
        _pulse.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_entry, _pulse]),
          builder: (context, child) {
            final pulse = 1.0 + 0.055 * _pulse.value;
            return FadeTransition(
              opacity: _entryFade,
              child: Transform.scale(
                scale: _entryScale.value * pulse,
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.verified_rounded,
                size: 26,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tripRecoverySnackbarTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.tripRecoverySnackbarBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        TexiScalePress(
          minScale: 0.94,
          child: TextButton(
            onPressed: () {
              TexiUiFeedback.lightTap();
              widget.onDismiss();
            },
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.tripRecoverySnackbarAction,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
