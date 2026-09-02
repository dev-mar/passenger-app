import 'package:flutter/material.dart';

import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/texi_scale_press.dart';
import 'login_auth_info_button.dart';
import 'passenger_auth_look.dart';

/// Fila compacta de acción en auth: icono, etiqueta, (i) y toda la fila es presionable.
class LoginAuthActionRow extends StatelessWidget {
  const LoginAuthActionRow({
    super.key,
    required this.enabled,
    required this.highlighted,
    required this.icon,
    required this.label,
    required this.infoMessage,
    required this.onTap,
    this.badge,
    this.accent,
    this.infoSteps,
  });

  final bool enabled;
  final bool highlighted;
  final Widget icon;
  final String label;
  final String infoMessage;
  final VoidCallback onTap;
  final String? badge;
  final Color? accent;
  final List<String>? infoSteps;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ??
        (highlighted
            ? AppColors.primary
            : AppColors.textSecondary.withValues(alpha: 0.85));

    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: TexiScalePress(
        child: DecoratedBox(
          decoration: highlighted
              ? PassengerAuthLook.highlightedDecoration(resolvedAccent)
              : PassengerAuthLook.panelDecoration,
          child: SizedBox(
            height: PassengerAuthLook.actionHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: enabled
                            ? () {
                                TexiUiFeedback.softImpact();
                                onTap();
                              }
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              icon,
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  badge!,
                                  style: const TextStyle(
                                    color: PassengerAuthLook.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  LoginAuthInfoButton(
                    message: infoMessage,
                    steps: infoSteps,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
