import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/auth/auth_service.dart';
import '../../core/storage/passenger_auth_lockout_storage.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../core/widgets/app_logo.dart';
import '../../gen_l10n/app_localizations.dart';
import '../login/utils/passenger_play_review_credentials.dart';
import '../trip/trip_request_state.dart';

/// Pantalla Splash: logo + comprobar sesión → Login o solicitud de viaje.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _intro;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
    );
    _intro.forward();
    // ignore: discarded_futures
    _navigateAfterDelay();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// Mínimo amortiguador para que la animación de marca no parpadee.
  static const Duration _minBrandDwell = Duration(milliseconds: 400);

  /// Tope duro del splash: nunca quedarse pegado en release.
  static const Duration _bootHardDeadline = Duration(seconds: 6);
  static const Duration _sessionResolveTimeout = Duration(seconds: 3);
  static const Duration _storageReadTimeout = Duration(seconds: 3);

  Future<bool> _resolveHasSession() async {
    try {
      return await AuthService.hasStoredSession().timeout(
        _sessionResolveTimeout,
        onTimeout: () => false,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Splash] hasStoredSession: $e');
      }
      return false;
    }
  }

  Future<String?> _resolveStoredTripId() async {
    try {
      return await TripSessionStorage.getActiveTripId().timeout(
        _storageReadTimeout,
        onTimeout: () => null,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Splash] getActiveTripId: $e');
      }
      return null;
    }
  }

  void _goLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.goNamed('login');
  }

  void _goAuthLockout({
    required String countryCode,
    required String phoneNumber,
  }) {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.goNamed(
      'auth_lockout',
      queryParameters: {
        'cc': countryCode,
        'phone': phoneNumber,
      },
    );
  }

  void _goTripRequest() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.goNamed('trip_request');
  }

  Future<void> _navigateAfterDelay() async {
    try {
      await _resolveAndNavigate().timeout(
        _bootHardDeadline,
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('[Splash] hard deadline → login');
          }
          _goLogin();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Splash] boot error → login: $e');
      }
      _goLogin();
    }
  }

  Future<void> _resolveAndNavigate() async {
    // No refrescar token aquí: evita red + lecturas extra de KeyStore en release prod.
    final brandWait = Future<void>.delayed(_minBrandDwell);
    final hasSession = await _resolveHasSession();
    final storedId = hasSession ? await _resolveStoredTripId() : null;
    await brandWait;
    if (!mounted || _navigated) return;

    if (hasSession) {
      if (storedId != null && storedId.isNotEmpty) {
        ref.read(tripRequestProvider.notifier).setTripId(storedId);
      }
      _goTripRequest();
      return;
    }

    final lockout = await PassengerAuthLockoutStorage.readActive();
    if (!mounted || _navigated) return;
    if (lockout != null &&
        lockout.isActive &&
        lockout.countryCode != null &&
        lockout.phoneNumber != null) {
      if (PassengerPlayReviewCredentials.isAllowlistedPhone(
        countryCode: lockout.countryCode!,
        phoneNumber: lockout.phoneNumber!,
      )) {
        await PassengerAuthLockoutStorage.clear();
      } else {
        _goAuthLockout(
          countryCode: lockout.countryCode!,
          phoneNumber: lockout.phoneNumber!,
        );
        return;
      }
    }

    _goLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.15,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _intro,
            builder: (context, child) {
              return FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(width: 120, height: 120),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)?.appName ?? 'TEXIAPP',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
