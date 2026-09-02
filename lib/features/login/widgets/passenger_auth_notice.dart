import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../gen_l10n/app_localizations.dart';
import 'login_auth_info_button.dart';

/// Aviso flotante de 5 s para errores de auth (visible, sin empujar la pantalla).
void showPassengerAuthNotice(
  BuildContext context, {
  String? title,
  required String message,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null || message.trim().isEmpty) return;
  final resolvedTitle =
      (title ?? AppLocalizations.of(context)?.loginReviewDataTitle)?.trim();
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: LoginAuthInfoGlyph(size: 36),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resolvedTitle != null && resolvedTitle.isNotEmpty) ...[
                    Text(
                      resolvedTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
