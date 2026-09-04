import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_ui_tokens.dart';
import 'texi_motion.dart';

/// Tono visual de avisos inline del pasajero (no cambia lógica ni contratos).
enum PassengerInlineNoticeTone { warning, info, error }

/// Tarjeta de aviso alineada a [showPassengerAuthNotice]: fondo oscuro, borde
/// suave y texto legible. Por defecto [warning] para no pintar de rojo avisos
/// operativos (GPS, cotización, datos incompletos).
class PassengerInlineNotice extends StatelessWidget {
  const PassengerInlineNotice({
    super.key,
    required this.message,
    this.tone = PassengerInlineNoticeTone.warning,
    this.icon,
    this.compact = false,
  });

  final String message;
  final PassengerInlineNoticeTone tone;
  final IconData? icon;
  final bool compact;

  static const Color _card = Color(0xFF1A1A1A);
  static const Color _amber = Color(0xFFFFA726);

  Color get _accent {
    switch (tone) {
      case PassengerInlineNoticeTone.error:
        return AppColors.error;
      case PassengerInlineNoticeTone.info:
        return AppColors.primary;
      case PassengerInlineNoticeTone.warning:
        return _amber;
    }
  }

  IconData get _defaultIcon {
    switch (tone) {
      case PassengerInlineNoticeTone.error:
        return Icons.error_outline_rounded;
      case PassengerInlineNoticeTone.info:
        return Icons.info_outline_rounded;
      case PassengerInlineNoticeTone.warning:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
        vertical: compact ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? _defaultIcon, size: compact ? 20 : 22, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.94),
                fontSize: compact ? AppTypography.bodySmall : AppTypography.body,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrada fade + slide. El aviso **permanece** mientras [message] exista:
/// no se auto-cierra (el estado del viaje / cotización manda).
class PassengerAnimatedInlineNotice extends StatefulWidget {
  const PassengerAnimatedInlineNotice({
    super.key,
    required this.message,
    this.tone = PassengerInlineNoticeTone.warning,
    this.icon,
    this.compact = false,
  });

  final String message;
  final PassengerInlineNoticeTone tone;
  final IconData? icon;
  final bool compact;

  @override
  State<PassengerAnimatedInlineNotice> createState() =>
      _PassengerAnimatedInlineNoticeState();
}

class _PassengerAnimatedInlineNoticeState
    extends State<PassengerAnimatedInlineNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: TexiMotion.emphasized,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: TexiMotion.standard);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: TexiMotion.standard));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(PassengerAnimatedInlineNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: PassengerInlineNotice(
          message: widget.message,
          tone: widget.tone,
          icon: widget.icon,
          compact: widget.compact,
        ),
      ),
    );
  }
}
