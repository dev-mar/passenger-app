import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/app_safe_scrolling.dart';
import 'passenger_auth_look.dart';

/// Fondo + gradiente compartido del embudo login / OTP / perfil.
class PassengerAuthShell extends StatelessWidget {
  const PassengerAuthShell({
    super.key,
    required this.child,
    this.leading,
    this.loading = false,
    this.loadingMessage,
    this.maxContentWidth = 400,
    this.horizontalPadding = 22,
  });

  final Widget child;
  final Widget? leading;
  final bool loading;
  final String? loadingMessage;
  final double maxContentWidth;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.loginBackground,
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.85),
                radius: 1.15,
                colors: [
                  Color(0x33FFD600),
                  Color(0x00000000),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.38),
                  Colors.black.withValues(alpha: 0.62),
                  const Color(0xF2070605),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?leading,
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        leading != null ? 8 : 20,
                        horizontalPadding,
                        20 + AppSafeScrolling.systemNavBottom(context),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                color: Colors.black.withValues(alpha: 0.52),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.8,
                            color: AppColors.primary,
                          ),
                        ),
                        if (loadingMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            loadingMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta glass para formularios de auth.
class PassengerAuthGlassCard extends StatelessWidget {
  const PassengerAuthGlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.dialog),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xE3181511),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Animación de entrada suave (fade + slide).
class PassengerAuthEntrance extends StatefulWidget {
  const PassengerAuthEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<PassengerAuthEntrance> createState() => _PassengerAuthEntranceState();
}

class _PassengerAuthEntranceState extends State<PassengerAuthEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.screenEntrance,
    );
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.standard);
    _slide = Tween<Offset>(
      begin: Offset(0, AppMotion.slideDySubtle + 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

InputDecoration passengerAuthFieldDecoration({
  required String label,
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint ?? label,
    hintStyle: const TextStyle(
      color: PassengerAuthLook.muted,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    suffixIcon: suffixIcon,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    counterText: '',
    filled: true,
    fillColor: AppColors.background.withValues(alpha: 0.55),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      borderSide: BorderSide(
        color: AppColors.primary.withValues(alpha: 0.85),
        width: 1.4,
      ),
    ),
  );
}

/// Campo dentro de [PassengerAuthFieldPanel]: guía solo como hint, nunca label flotante.
InputDecoration passengerAuthInlineFieldDecoration({
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: PassengerAuthLook.muted,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    suffixIcon: suffixIcon,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    counterText: '',
    filled: false,
    isDense: true,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
  );
}
