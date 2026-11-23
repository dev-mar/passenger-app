import 'dart:async' show unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/config/app_config.dart';
import 'core/config/locale_provider.dart';
import 'core/l10n/passenger_locale_holder.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/passenger_session_expulsion.dart';
import 'features/trip/passenger_realtime_controller.dart';
import 'core/app_lifecycle/passenger_app_visibility.dart';
import 'core/notifications/passenger_notification_service.dart';
import 'core/notifications/passenger_fcm.dart';
import 'core/notifications/passenger_fcm_navigation.dart';
import 'core/notifications/passenger_push_token_service.dart';
import 'core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/maps/passenger_maps_bootstrap.dart';
import 'firebase_options.dart';
import 'gen_l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(PassengerMapsBootstrap.startAndroidRenderer());
  FirebaseMessaging.onBackgroundMessage(
    passengerFirebaseMessagingBackgroundHandler,
  );
  AuthService.onSessionEstablished = () {
    resetPassengerSessionExpulsionState();
    return PassengerPushTokenService.instance.syncTokenIfPossible();
  };
  void navigateToLogin() {
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).goNamed(AppRouter.login);
    }
  }
  AuthService.onSessionExpired = () {
    markPassengerSessionExpelled();
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      ProviderScope.containerOf(context)
          .read(passengerRealtimeProvider.notifier)
          .disconnect();
    }
    navigateToLogin();
  };
  AuthService.onSessionSuperseded = AuthService.onSessionExpired;

  final savedLocale = await readSavedPassengerLocale();
  runApp(
    ProviderScope(
      overrides: [
        if (savedLocale != null)
          localeProvider.overrideWith((ref) => savedLocale),
      ],
      child: const TexiApp(),
    ),
  );

  unawaited(_initializeFirebaseCore());
}

Future<void> _initializeFirebaseCore() async {
  try {
    final expected = DefaultFirebaseOptions.currentPlatform;
    if (Firebase.apps.isNotEmpty) {
      final current = Firebase.app().options;
      if (current.projectId == expected.projectId &&
          current.appId == expected.appId) {
        return;
      }
      await Firebase.app().delete();
    }
    await Firebase.initializeApp(options: expected)
        .timeout(const Duration(seconds: 12));
  } catch (e) {
    debugPrint('[main] Firebase init: $e');
  }
}

class TexiApp extends ConsumerStatefulWidget {
  const TexiApp({super.key});

  @override
  ConsumerState<TexiApp> createState() => _TexiAppState();
}

class _TexiAppState extends ConsumerState<TexiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapDeferredServices());
      unawaited(_consumeInitialPassengerFcmMessage());
    });
  }

  Future<void> _bootstrapDeferredServices() async {
    try {
      await PassengerNotificationService.instance.initialize();
    } catch (_) {} // ignore: empty_catches
    try {
      await setupPassengerFirebaseMessaging();
    } catch (_) {} // ignore: empty_catches
  }

  Future<void> _consumeInitialPassengerFcmMessage() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final msg = await FirebaseMessaging.instance.getInitialMessage();
      if (msg == null) return;
      await handlePassengerFcmNotificationOpen(msg);
    } catch (_) {} // ignore: empty_catches
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    PassengerAppVisibility.isInForeground.value = state == AppLifecycleState.resumed;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    PassengerLocaleHolder.appLocale = locale;

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      routerConfig: AppRouter.router,
    );
  }
}
