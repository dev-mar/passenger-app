import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../core/network/trips_api.dart';
import 'passenger_home_look.dart';

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
    _page = PageController();
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
        duration: const Duration(milliseconds: 520),
        curve: AppMotion.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 176,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg + 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PassengerHomeLook.card,
            border: Border.all(color: PassengerHomeLook.hairline),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  return notification.metrics.axis == Axis.vertical;
                },
                child: PageView.builder(
                  controller: _page,
                  scrollDirection: Axis.vertical,
                  physics: const PageScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: banners.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    _restartTimer();
                  },
                  itemBuilder: (context, i) {
                    final banner = banners[i];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
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
                    );
                  },
                ),
              ),
              if (banners.length > 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(banners.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          width: 7,
                          height: active ? 16 : 7,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
