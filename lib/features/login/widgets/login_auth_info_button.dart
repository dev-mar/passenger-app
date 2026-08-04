import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';

const Duration _kLoginAuthInfoVisibleDuration = Duration(seconds: 10);
const IconData _kLoginAuthInfoIcon = Icons.info_outline_rounded;

/// Muestra información adicional centrada (seguridad + pasos) para botones (i).
Future<void> showLoginAuthInfoGuide(
  BuildContext context, {
  required String message,
  String? title,
  List<String>? steps,
}) {
  final l10n = AppLocalizations.of(context)!;
  final resolvedTitle = title ?? l10n.loginAuthInfoTitle;
  final resolvedSteps = _resolveSteps(message, steps);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: resolvedTitle,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _LoginAuthInfoGuideDialog(
        title: resolvedTitle,
        message: message,
        steps: resolvedSteps,
        secureNote: l10n.loginAuthInfoSecureNote,
        dismissLabel: l10n.loginAuthInfoGotIt,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

List<String> _resolveSteps(String message, List<String>? explicit) {
  if (explicit != null && explicit.isNotEmpty) {
    return explicit;
  }
  final parts = message
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return parts;
  }
  return [message.trim()];
}

/// Botón (i) informativo que abre detalle centrado en pantalla.
class LoginAuthInfoButton extends StatelessWidget {
  const LoginAuthInfoButton({
    super.key,
    required this.message,
    this.title,
    this.tooltip,
    this.steps,
    this.compact = false,
  });

  final String message;
  final String? title;
  final String? tooltip;
  final List<String>? steps;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 34.0;
    final iconSize = compact ? 17.0 : 19.0;

    return Semantics(
      button: true,
      label: tooltip ?? title ?? message,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            TexiUiFeedback.softImpact();
            HapticFeedback.selectionClick();
            showLoginAuthInfoGuide(
              context,
              message: message,
              title: title,
              steps: steps,
            );
          },
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.28),
                  AppColors.primary.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.72),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _kLoginAuthInfoIcon,
              size: iconSize,
              color: AppColors.primary.withValues(alpha: 0.98),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginAuthInfoGuideDialog extends StatefulWidget {
  const _LoginAuthInfoGuideDialog({
    required this.title,
    required this.message,
    required this.steps,
    required this.secureNote,
    required this.dismissLabel,
  });

  final String title;
  final String message;
  final List<String> steps;
  final String secureNote;
  final String dismissLabel;

  @override
  State<_LoginAuthInfoGuideDialog> createState() =>
      _LoginAuthInfoGuideDialogState();
}

class _LoginAuthInfoGuideDialogState extends State<_LoginAuthInfoGuideDialog>
    with SingleTickerProviderStateMixin {
  Timer? _autoDismissTimer;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _kLoginAuthInfoVisibleDuration,
    )..forward();
    _autoDismissTimer = Timer(_kLoginAuthInfoVisibleDuration, _dismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSteps = widget.steps.length > 1;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.dialog),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2A241C),
                      Color(0xFF1A1814),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.dialog),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.35),
                                    AppColors.primary.withValues(alpha: 0.14),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Icon(
                                _kLoginAuthInfoIcon,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (showSteps)
                              ...List.generate(widget.steps.length, (index) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == widget.steps.length - 1
                                        ? 0
                                        : 10,
                                  ),
                                  child: _GuideStepRow(
                                    index: index + 1,
                                    text: widget.steps[index],
                                  ),
                                );
                              })
                            else
                              Text(
                                widget.message,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.95),
                                  height: 1.5,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 18,
                                    color: AppColors.success.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.secureNote,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.96),
                                        height: 1.4,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: 1 - _progressController.value,
                            minHeight: 3,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.08),
                            color: AppColors.primary.withValues(alpha: 0.85),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: TextButton(
                          onPressed: _dismiss,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.lg),
                            ),
                          ),
                          child: Text(
                            widget.dismissLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideStepRow extends StatelessWidget {
  const _GuideStepRow({
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.2),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.96),
                    height: 1.45,
                    fontSize: 13.5,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
