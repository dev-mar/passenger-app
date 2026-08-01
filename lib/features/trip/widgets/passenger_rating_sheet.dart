import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/feedback/texi_ui_feedback.dart';
import '../../../core/network/trips_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../gen_l10n/app_localizations.dart';

/// Sheet compacto de calificación (pasajero → conductor).
class PassengerRatingSheetContent extends StatefulWidget {
  const PassengerRatingSheetContent({
    super.key,
    this.driverName,
    required this.title,
    required this.subtitle,
    required this.sendLabel,
    required this.skipLabel,
    required this.onSubmitted,
    required this.onSkipped,
  });

  final String? driverName;
  final String title;
  final String subtitle;
  final String sendLabel;
  final String skipLabel;
  final void Function(int stars, List<String> feedbackCodes) onSubmitted;
  final VoidCallback onSkipped;

  @override
  State<PassengerRatingSheetContent> createState() =>
      _PassengerRatingSheetContentState();
}

class _PassengerRatingSheetContentState
    extends State<PassengerRatingSheetContent>
    with SingleTickerProviderStateMixin {
  int _rating = 5;
  bool _loadingCatalog = true;
  List<TripRatingFeedbackItem> _feedbackLow = const [];
  List<TripRatingFeedbackItem> _feedbackHigh = const [];
  final Set<String> _selectedFeedbackCodes = <String>{};
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  List<TripRatingFeedbackItem> get _displayedOptions =>
      _rating <= 3 ? _feedbackLow : _feedbackHigh;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: AppMotion.sheetEntrance,
    );
    _fade = CurvedAnimation(parent: _entrance, curve: AppMotion.standard);
    _slide = Tween<Offset>(
      begin: Offset(0, AppMotion.slideDySubtle),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: AppMotion.standard));
    _entrance.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_preloadFeedbackCatalogs());
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _preloadFeedbackCatalogs() async {
    setState(() => _loadingCatalog = true);
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        _applyFallbackCatalogs();
        return;
      }
      final api = TripsApi(token: token);
      final results = await Future.wait([
        api.getPassengerRatingFeedbackCatalog(stars: 3),
        api.getPassengerRatingFeedbackCatalog(stars: 5),
      ]);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final lowRaw = results[0];
      final highRaw = results[1];
      setState(() {
        _feedbackLow = (lowRaw.isEmpty ? _fallbackFeedback(l10n, 2) : lowRaw)
            .take(4)
            .toList(growable: false);
        _feedbackHigh = (highRaw.isEmpty ? _fallbackFeedback(l10n, 5) : highRaw)
            .take(4)
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      _applyFallbackCatalogs();
    } finally {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  void _applyFallbackCatalogs() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _feedbackLow = _fallbackFeedback(l10n, 2).take(4).toList(growable: false);
      _feedbackHigh =
          _fallbackFeedback(l10n, 5).take(4).toList(growable: false);
    });
  }

  void _setRating(int stars) {
    HapticFeedback.selectionClick();
    final prevBucket = _rating <= 3;
    final nextBucket = stars <= 3;
    setState(() {
      _rating = stars;
      if (prevBucket != nextBucket) {
        _selectedFeedbackCodes.removeWhere(
          (code) => !_displayedOptions.any((item) => item.code == code),
        );
      }
    });
  }

  List<TripRatingFeedbackItem> _fallbackFeedback(
    AppLocalizations l10n,
    int stars,
  ) {
    if (stars <= 3) {
      return [
        TripRatingFeedbackItem(
          code: 'fallback_delay',
          label: l10n.passengerRatingFallbackDelay,
          minStars: 1,
          maxStars: 3,
        ),
        TripRatingFeedbackItem(
          code: 'fallback_route',
          label: l10n.passengerRatingFallbackRoute,
          minStars: 1,
          maxStars: 3,
        ),
        TripRatingFeedbackItem(
          code: 'fallback_cleanliness',
          label: l10n.passengerRatingFallbackCleanliness,
          minStars: 1,
          maxStars: 3,
        ),
        TripRatingFeedbackItem(
          code: 'fallback_attitude',
          label: l10n.passengerRatingFallbackAttitude,
          minStars: 1,
          maxStars: 3,
        ),
      ];
    }
    return [
      TripRatingFeedbackItem(
        code: 'fallback_safe',
        label: l10n.passengerRatingFallbackSafe,
        minStars: 4,
        maxStars: 5,
      ),
      TripRatingFeedbackItem(
        code: 'fallback_clean',
        label: l10n.passengerRatingFallbackClean,
        minStars: 4,
        maxStars: 5,
      ),
      TripRatingFeedbackItem(
        code: 'fallback_kind',
        label: l10n.passengerRatingFallbackKind,
        minStars: 4,
        maxStars: 5,
      ),
      TripRatingFeedbackItem(
        code: 'fallback_punctual',
        label: l10n.passengerRatingFallbackPunctual,
        minStars: 4,
        maxStars: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final driverName = widget.driverName?.trim();
    final hasDriver = driverName != null && driverName.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                top: 4,
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 22,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (hasDriver) ...[
                        const SizedBox(height: 4),
                        Text(
                          driverName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final filled = _rating >= index + 1;
                          return GestureDetector(
                            onTap: () => _setRating(index + 1),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 34,
                                color: filled
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        }),
                      ),
                      if (_rating > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          _rating <= 3
                              ? l10n.tripRatingFeedbackPromptLow
                              : l10n.tripRatingFeedbackPromptHigh,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_loadingCatalog)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        else if (_displayedOptions.isNotEmpty)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: _displayedOptions.map((item) {
                              final selected =
                                  _selectedFeedbackCodes.contains(item.code);
                              return FilterChip(
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                selected: selected,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedFeedbackCodes.add(item.code);
                                    } else {
                                      _selectedFeedbackCodes.remove(item.code);
                                    }
                                  });
                                },
                                label: Text(
                                  item.label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _rating == 0 || _loadingCatalog
                            ? null
                            : () {
                                TexiUiFeedback.lightTap();
                                widget.onSubmitted(
                                  _rating,
                                  _selectedFeedbackCodes.toList(
                                    growable: false,
                                  ),
                                );
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          widget.sendLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          TexiUiFeedback.lightTap();
                          widget.onSkipped();
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: Text(
                          widget.skipLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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
