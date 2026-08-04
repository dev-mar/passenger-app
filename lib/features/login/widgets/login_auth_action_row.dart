import 'package:flutter/material.dart';

import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_scale_press.dart';
import 'login_auth_info_button.dart';

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
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          color: highlighted
              ? resolvedAccent.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: highlighted
                ? resolvedAccent.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: TexiScalePress(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: enabled
                          ? () {
                              TexiUiFeedback.softImpact();
                              onTap();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            icon,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      badge!,
                                      style: TextStyle(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.85),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
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
    );
  }
}
