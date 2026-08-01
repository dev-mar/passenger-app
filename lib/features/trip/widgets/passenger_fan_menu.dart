import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';

enum PassengerFanMenuAction {
  safety,
  operator,
  profile,
  history,
  logout,
}

class PassengerFanMenuItem {
  const PassengerFanMenuItem({
    required this.action,
    required this.label,
    this.icon,
    this.assetIcon,
    this.danger = false,
  }) : assert(icon != null || assetIcon != null);

  final PassengerFanMenuAction action;
  final IconData? icon;
  final String? assetIcon;
  final String label;
  final bool danger;
}

/// Menú en abanico denso hacia la izquierda.
/// El último ítem es la referencia (casi a la altura del FAB, un poco más abajo);
/// el resto se reparte uniformemente hacia arriba.
Future<PassengerFanMenuAction?> showPassengerFanMenu({
  required BuildContext context,
  required Offset anchorGlobal,
}) {
  final l10n = AppLocalizations.of(context)!;
  // Orden (arriba → abajo): Seguridad, Perfil, Operador, Mis viajes, Cerrar sesión.
  final items = <PassengerFanMenuItem>[
    PassengerFanMenuItem(
      action: PassengerFanMenuAction.safety,
      assetIcon: AppAssets.safetyButton,
      label: l10n.menuSupportHelp,
    ),
    PassengerFanMenuItem(
      action: PassengerFanMenuAction.profile,
      icon: Icons.person_rounded,
      label: l10n.menuProfile,
    ),
    PassengerFanMenuItem(
      action: PassengerFanMenuAction.operator,
      icon: Icons.phone_in_talk_rounded,
      label: l10n.menuOperatorTexi,
    ),
    PassengerFanMenuItem(
      action: PassengerFanMenuAction.history,
      icon: Icons.history_rounded,
      label: l10n.menuTripHistory,
    ),
    PassengerFanMenuItem(
      action: PassengerFanMenuAction.logout,
      icon: Icons.logout_rounded,
      label: l10n.tripLogout,
      danger: true,
    ),
  ];

  return showGeneralDialog<PassengerFanMenuAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim, secondary) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (ctx, anim, secondary, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return _PassengerFanMenuOverlay(
        animation: curved,
        anchorGlobal: anchorGlobal,
        items: items,
        onSelect: (action) => Navigator.of(ctx).pop(action),
        onDismiss: () => Navigator.of(ctx).pop(),
      );
    },
  );
}

class _PassengerFanMenuOverlay extends StatelessWidget {
  const _PassengerFanMenuOverlay({
    required this.animation,
    required this.anchorGlobal,
    required this.items,
    required this.onSelect,
    required this.onDismiss,
  });

  final Animation<double> animation;
  final Offset anchorGlobal;
  final List<PassengerFanMenuItem> items;
  final ValueChanged<PassengerFanMenuAction> onSelect;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final anchor = Offset(
      anchorGlobal.dx.clamp(40.0, size.width - 28),
      anchorGlobal.dy,
    );

    const itemSize = 48.0;
    const fabSize = 56.0;
    // Separación entre centros > tamaño del círculo para que se lean como opciones distintas.
    // El último ítem queda fijo (endAngle); el resto se reparte hacia arriba desde ahí.
    const itemArcSpacing = itemSize + AppSpacing.xl; // 48 + 12 = 60
    const radius = 128.0;
    final arcStepRad = itemArcSpacing / radius;
    // Último ítem (referente): un poco más abajo que el FAB ancla — no mover.
    final endAngle = math.pi + 0.22;
    final n = items.length;
    final startAngle = endAngle - arcStepRad * (n - 1);

    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
                child: const SizedBox.expand(),
              ),
            ),
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _FanArcPainter(
                    anchor: anchor,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    progress: animation.value.clamp(0.0, 1.0),
                  ),
                );
              },
            ),
            for (var i = 0; i < n; i++)
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final t = Curves.easeOutBack.transform(
                    animation.value.clamp(0.0, 1.0),
                  );
                  // i=0 arriba … i=n-1 último (referente, un poco bajo el FAB).
                  final angle = endAngle - arcStepRad * (n - 1 - i);
                  final r = radius * t;
                  final cx = anchor.dx + math.cos(angle) * r;
                  final cy = anchor.dy - math.sin(angle) * r;
                  final item = items[i];
                  final stagger = (1 - (i * 0.035)).clamp(0.78, 1.0);
                  final opacity = (t * stagger).clamp(0.0, 1.0);

                  return Positioned(
                    left: cx - itemSize / 2,
                    top: cy - itemSize / 2,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: 0.7 + 0.3 * t,
                        child: _FanMenuIconButton(
                          item: item,
                          circleSize: itemSize,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onSelect(item.action);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            Positioned(
              left: anchor.dx - fabSize / 2,
              top: anchor.dy - fabSize / 2,
              child: _FanAnchorButton(onTap: onDismiss),
            ),
          ],
        ),
      ),
    );
  }
}

class _FanMenuIconButton extends StatelessWidget {
  const _FanMenuIconButton({
    required this.item,
    required this.circleSize,
    required this.onTap,
  });

  final PassengerFanMenuItem item;
  final double circleSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAsset = item.assetIcon != null;
    final accent = item.danger ? const Color(0xFFE05140) : AppColors.textPrimary;
    final ring = item.danger
        ? const Color(0xFFE05140)
        : Colors.white.withValues(alpha: 0.35);

    return Tooltip(
      message: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: hasAsset
            ? SizedBox(
                width: circleSize,
                height: circleSize,
                child: Image.asset(
                  item.assetIcon!,
                  fit: BoxFit.contain,
                ),
              )
            : Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.92),
                  border: Border.all(color: ring, width: item.danger ? 2 : 1.4),
                  boxShadow: [
                    if (item.danger)
                      BoxShadow(
                        color: const Color(0xFFE05140).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 0.5,
                      )
                    else
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 10,
                      ),
                  ],
                ),
                child: Icon(item.icon, color: accent, size: 22),
              ),
      ),
    );
  }
}

class _FanAnchorButton extends StatelessWidget {
  const _FanAnchorButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.close_rounded,
          color: AppColors.onPrimary,
          size: 28,
        ),
      ),
    );
  }
}

class _FanArcPainter extends CustomPainter {
  _FanArcPainter({
    required this.anchor,
    required this.radius,
    required this.startAngle,
    required this.endAngle,
    required this.progress,
  });

  final Offset anchor;
  final double radius;
  final double startAngle;
  final double endAngle;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary.withValues(alpha: 0.28 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final rect = Rect.fromCircle(center: anchor, radius: radius * progress);
    canvas.drawArc(rect, -endAngle, endAngle - startAngle, false, paint);

    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = AppColors.primary.withValues(alpha: 0.07 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawArc(rect, -endAngle, endAngle - startAngle, false, soft);
  }

  @override
  bool shouldRepaint(covariant _FanArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.anchor != anchor ||
        oldDelegate.radius != radius;
  }
}
