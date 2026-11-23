import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import '../../core/storage/passenger_auth_lockout_storage.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../core/ui/texi_brand_loader.dart';
import '../login/utils/passenger_play_review_credentials.dart';
import '../../core/version/app_version_gate.dart';
import '../trip/trip_request_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _navigateAfterDelay();
  }

  static const Duration _minBrandDwell = Duration(milliseconds: 2000);

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
      queryParameters: {'cc': countryCode, 'phone': phoneNumber},
    );
  }

  void _goTripRequest() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.goNamed('trip_request');
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.goNamed('home');
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
    final canProceed = await AppVersionGate.runStartupCheck(context);
    if (!mounted || _navigated || !canProceed) return;

    final brandWait = Future<void>.delayed(_minBrandDwell);
    final hasSession = await _resolveHasSession();
    final storedId = hasSession ? await _resolveStoredTripId() : null;
    await brandWait;
    if (!mounted || _navigated) return;

    if (hasSession) {
      if (storedId != null && storedId.isNotEmpty) {
        ref.read(tripRequestProvider.notifier).setTripId(storedId);
        _goTripRequest();
      } else {
        _goHome();
      }
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
    return const Scaffold(
      backgroundColor: Color(0xFF050505),
      body: TexiBrandLoader(),
    );
  }
}
