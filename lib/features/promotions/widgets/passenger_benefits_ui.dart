import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/ui/texi_motion.dart';
import '../../../core/ui/texi_scale_press.dart';

/// Paleta local de la pantalla de beneficios (marca TEXI + acentos tech).
abstract final class BenefitsVisual {
  BenefitsVisual._();

  static const Color canvas = Color(0xFF050505);
  static const Color card = Color(0xFF14110C);
  static const Color cardHi = Color(0xFF1C1810);
  static const Color line = Color(0x33FFD600);
  static const Color teal = Color(0xFF3DDC97);
  static const Color sky = Color(0xFF6EC8FF);
  static const Color violet = Color(0xFFB8A4FF);
}

class BenefitsGlowBackdrop extends StatelessWidget {
  const BenefitsGlowBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const ColoredBox(
            color: BenefitsVisual.canvas,
            child: SizedBox.expand(),
          ),
          Positioned(
            top: -80,
            left: -40,
            child: _Blob(
              size: 280,
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 120,
            right: -90,
            child: _Blob(
              size: 220,
              color: BenefitsVisual.sky.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class BenefitsStagger extends StatelessWidget {
  const BenefitsStagger({
    super.key,
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (0.07 * index).clamp(0.0, 0.7);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        (start + 0.42).clamp(0.0, 1.0),
        curve: TexiMotion.standard,
      ),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class BenefitsPanel extends StatelessWidget {
  const BenefitsPanel({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxx),
      decoration: BoxDecoration(
        color: BenefitsVisual.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BenefitsIconOrb(icon: icon, accent: accent),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class BenefitsIconOrb extends StatelessWidget {
  const BenefitsIconOrb({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 44,
  });

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, color: accent, size: size * 0.48),
    );
  }
}

class BenefitsHeroCard extends StatelessWidget {
  const BenefitsHeroCard({
    super.key,
    required this.pulse,
    required this.lead,
    this.walletTitle,
    this.walletAmount,
    this.walletMeta = const [],
    this.emptyMessage,
    this.activeTitle,
    this.activeCount,
  });

  final Animation<double> pulse;
  final String lead;
  final String? walletTitle;
  final String? walletAmount;
  final List<String> walletMeta;
  final String? emptyMessage;
  final String? activeTitle;
  final int? activeCount;

  @override
  Widget build(BuildContext context) {
    final hasWallet = walletAmount != null && walletAmount!.isNotEmpty;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = 0.12 + (pulse.value * 0.1);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A2414), Color(0xFF12100C), Color(0xFF0B0B0B)],
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.38),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: glow),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'TEXIAPP',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (hasWallet) ...[
            Text(
              walletTitle ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              walletAmount!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
            for (final line in walletMeta)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ] else if (activeCount != null && activeCount! > 0) ...[
            Text(
              activeTitle ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$activeCount',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
          ] else ...[
            Row(
              children: [
                BenefitsIconOrb(
                  icon: Icons.auto_awesome_rounded,
                  accent: AppColors.primary,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Text(
                    emptyMessage ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            lead,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class BenefitsTicketCode extends StatelessWidget {
  const BenefitsTicketCode({
    super.key,
    required this.code,
    required this.onCopy,
  });

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return TexiScalePress(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: BenefitsVisual.cardHi,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: BenefitsVisual.line, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
                const Icon(
                  Icons.copy_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BenefitsStatusNote extends StatelessWidget {
  const BenefitsStatusNote({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BenefitsInviteeRow extends StatelessWidget {
  const BenefitsInviteeRow({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'granted' => BenefitsVisual.teal,
      'rejected' => AppColors.error,
      _ => AppColors.primary,
    };
    final icon = switch (status) {
      'granted' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_rounded,
      _ => Icons.hourglass_top_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: BenefitsVisual.cardHi,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BenefitsRuleCard extends StatelessWidget {
  const BenefitsRuleCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxx),
      decoration: BoxDecoration(
        color: BenefitsVisual.cardHi,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.isEmpty ? '—' : text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BenefitsPrimaryButton extends StatelessWidget {
  const BenefitsPrimaryButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TexiScalePress(
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeight,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }
}

class BenefitsGhostButton extends StatelessWidget {
  const BenefitsGhostButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return TexiScalePress(
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeight,
        child: OutlinedButton.icon(
          onPressed: busy ? null : onPressed,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
        ),
      ),
    );
  }
}
