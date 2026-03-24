import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/login/verify_code_screen.dart';
import '../../features/login/profile_setup_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/passenger_profile_preview_screen.dart';
import '../../features/trip/trip_request_screen.dart';
import '../../features/trip/trip_quote_screen.dart';
import '../../features/trip/trip_confirm_screen.dart';
import '../../features/trip/trip_searching_screen.dart';

/// Rutas con nombres alineados a PASAJERO-APP-SETUP.md.
/// Cambiar paths o pantallas solo aquí.
class AppRouter {
  AppRouter._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String verifyCode = 'verify_code';
  static const String profileSetup = 'profile_setup';
  static const String home = 'home';
  static const String passengerProfile = 'passenger_profile';
  static const String tripRequest = 'trip_request';
  static const String tripQuote = 'trip_quote';
  static const String tripConfirm = 'trip_confirm';
  static const String tripSearching = 'trip_searching';

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/verify',
        name: verifyCode,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final cc = q['cc'] ?? '+591';
          final phone = q['phone'] ?? '';
          return VerifyCodeScreen(
            countryCode: cc,
            phoneNumber: phone,
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
          );
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
    ],
  );
}
