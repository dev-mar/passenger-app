import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_service.dart';
import '../config/passenger_app_environment.dart';
import '../session/passenger_internal_tools_gate.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/login/passenger_auth_lockout_screen.dart';
import '../../features/login/auth_step_up_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/login/verify_code_screen.dart';
import '../../features/login/verify_sms_screen.dart';
import '../../features/login/profile_setup_screen.dart';
import '../../features/login/passenger_phone_link_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/passenger_profile_preview_screen.dart';
import '../../features/support/passenger_support_help_screen.dart';
import '../../features/support/passenger_operator_texi_screen.dart';
import '../../features/support/passenger_safety_hub_screen.dart';
import '../../features/trip/trip_request_screen.dart';
import '../../features/trip/trip_quote_screen.dart';
import '../../features/trip/trip_confirm_screen.dart';
import '../../features/trip/trip_searching_screen.dart';
import '../../features/trip/passenger_trip_history_screen.dart';
import '../../features/labs/passenger_labs_screen.dart';

/// Rutas con nombres alineados a PASAJERO-APP-SETUP.md.
/// Cambiar paths o pantallas solo aquí.
class AppRouter {
  AppRouter._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String verifyCode = 'verify_code';
  static const String verifySms = 'verify_sms';
  static const String authStepUp = 'auth_step_up';
  static const String authLockout = 'auth_lockout';
  static const String profileSetup = 'profile_setup';
  static const String phoneLink = 'phone_link';
  static const String home = 'home';
  static const String passengerProfile = 'passenger_profile';
  static const String supportHelp = 'support_help';
  static const String operatorTexi = 'operator_texi';
  static const String safetyHub = 'safety_hub';
  static const String safetyVerifiedDrivers = 'safety_verified_drivers';
  static const String tripRequest = 'trip_request';
  static const String tripQuote = 'trip_quote';
  static const String tripConfirm = 'trip_confirm';
  static const String tripSearching = 'trip_searching';
  static const String tripHistory = 'trip_history';
  static const String labs = 'passenger_labs';

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Rutas públicas (onboarding / splash). El resto exige sesión persistida.
  static const Set<String> _publicPaths = {
    '/',
    '/login',
    '/auth/verify',
    '/auth/verify-sms',
    '/auth/lockout',
    '/auth/step-up',
    '/auth/profile',
  };

  static bool _isProtectedPath(String location) {
    if (_publicPaths.contains(location)) return false;
    if (location == '/home' ||
        location == '/profile' ||
        location == '/support' ||
        location == '/safety' ||
        location == '/operator' ||
        location == '/labs' ||
        location == '/trip/history') {
      return true;
    }
    return location.startsWith('/trip/') || location.startsWith('/safety/');
  }

  static Future<bool> _hasStoredSession() async {
    try {
      return await AuthService.hasStoredSession()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[AppRouter] Error leyendo sesión: $e');
      return false;
    }
  }

  static Future<String?> _labsRedirectIfDenied() async {
    if (PassengerAppEnvironment.showsInternalToolsByDefault) return null;
    try {
      final phone = await AuthService.readLoginPhoneE164Digits()
          .timeout(const Duration(seconds: 3));
      if (PassengerInternalToolsGate.phoneAllowsInternalTools(phone)) {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppRouter] gate labs: $e');
      }
    }
    return '/home';
  }

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) async {
      final location = state.matchedLocation;

      // Splash resuelve sesión por su cuenta; evitar lectura segura duplicada al arrancar.
      if (location == '/') return null;

      final hasSession = await _hasStoredSession();

      if (location == '/login' && hasSession) {
        return '/trip/request';
      }

      if (_isProtectedPath(location) && !hasSession) {
        return '/login';
      }

      if (location == '/labs' && hasSession) {
        return await _labsRedirectIfDenied();
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: login,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return LoginScreen(
            initialCountryCode: q['cc'],
            initialPhone: q['phone'],
            stepUpCompleted: q['step_up_done'] == '1',
          );
        },
      ),
      GoRoute(
        path: '/auth/verify',
        name: verifyCode,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final cc = q['cc'] ?? '+591';
          final phone = q['phone'] ?? '';
          final channel = q['channel'];
          if (channel == 'sms' || channel == 'sms_firebase') {
            return VerifySmsScreen(
              countryCode: cc,
              phoneNumber: phone,
            );
          }
          return VerifyCodeScreen(
            countryCode: cc,
            phoneNumber: phone,
            email: q['email'],
            verificationChannel: channel,
            challengeId: q['challenge_id'],
            waDeepLink: q['wa_deep_link'],
            linkPhoneMode: q['link'] == '1',
            returnTo: q['return_to'],
            waResumeMode: q['wa_resume'],
          );
        },
      ),
      GoRoute(
        path: '/auth/verify-sms',
        name: verifySms,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return VerifySmsScreen(
            countryCode: q['cc'] ?? '+591',
            phoneNumber: q['phone'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/auth/lockout',
        name: authLockout,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return PassengerAuthLockoutScreen(
            countryCode: q['cc'] ?? '+591',
            phoneNumber: q['phone'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/auth/step-up',
        name: authStepUp,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return AuthStepUpScreen(
            countryCode: q['cc'] ?? '+591',
            phoneNumber: q['phone'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/auth/profile',
        name: profileSetup,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final cc = q['cc'] ?? '+591';
          final phone = q['phone'] ?? '';
          return ProfileSetupScreen(
            countryCode: cc,
            phoneNumber: phone,
            email: q['email'],
          );
        },
      ),
      GoRoute(
        path: '/auth/link-phone',
        name: phoneLink,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return PassengerPhoneLinkScreen(returnTo: q['return_to']);
        },
      ),
      GoRoute(
        path: '/home',
        name: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: passengerProfile,
        builder: (context, state) => const PassengerProfilePreviewScreen(),
      ),
      GoRoute(
        path: '/support',
        name: supportHelp,
        builder: (context, state) => const PassengerSupportHelpScreen(),
      ),
      GoRoute(
        path: '/safety',
        name: safetyHub,
        builder: (context, state) => const PassengerSafetyHubScreen(),
      ),
      GoRoute(
        path: '/safety/verified-drivers',
        name: safetyVerifiedDrivers,
        builder: (context, state) => const PassengerVerifiedDriversScreen(),
      ),
      GoRoute(
        path: '/operator',
        name: operatorTexi,
        builder: (context, state) => const PassengerOperatorTexiScreen(),
      ),
      GoRoute(
        path: '/trip/request',
        name: tripRequest,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final lat = q['lat'] != null ? double.tryParse(q['lat']!) : null;
          final lng = q['lng'] != null ? double.tryParse(q['lng']!) : null;
          return TripRequestScreen(originLat: lat, originLng: lng);
        },
      ),
      GoRoute(
        path: '/trip/quote',
        name: tripQuote,
        builder: (context, state) => const TripQuoteScreen(),
      ),
      GoRoute(
        path: '/trip/confirm',
        name: tripConfirm,
        builder: (context, state) => const TripConfirmScreen(),
      ),
      GoRoute(
        path: '/trip/searching',
        name: tripSearching,
        builder: (context, state) => const TripSearchingScreen(),
      ),
      GoRoute(
        path: '/trip/history',
        name: tripHistory,
        builder: (context, state) => const PassengerTripHistoryScreen(),
      ),
      GoRoute(
        path: '/labs',
        name: labs,
        builder: (context, state) => const PassengerLabsScreen(),
      ),
    ],
  );
}
