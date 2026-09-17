import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/network/trips_api.dart';
import 'passenger_home_look.dart';

/// Carrusel de imágenes (estilo Yape): swipe + auto-avance. Solo imagen.
class PassengerHomeBannerCarousel extends StatefulWidget {
  const PassengerHomeBannerCarousel({
    super.key,
    required this.banners,
    required this.onTap,
  });

  final List<PassengerHomeBanner> banners;
  final VoidCallback onTap;

  @override
  State<PassengerHomeBannerCarousel> createState() =>
      _PassengerHomeBannerCarouselState();
}

class _PassengerHomeBannerCarouselState
    extends State<PassengerHomeBannerCarousel> {
  static const _autoAdvance = Duration(seconds: 5);
  late final PageController _page;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.92);
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant PassengerHomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _index = 0;
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(_autoAdvance, (_) {
      if (!mounted || !_page.hasClients) return;
      final next = (_index + 1) % widget.banners.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _page,
            itemCount: banners.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _restartTimer();
            },
            itemBuilder: (context, i) {
              final banner = banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(AppRadii.lg + 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.lg + 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: PassengerHomeLook.card,
                          border: Border.all(color: PassengerHomeLook.hairline),
                        ),
                        child: Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
                            return ColoredBox(
                              color: PassengerHomeLook.card,
                              child: Icon(
                                Icons.image_outlined,
                                color: PassengerHomeLook.muted,
                                size: AppIconSizes.hero,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : PassengerHomeLook.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
