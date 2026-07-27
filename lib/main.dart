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
import 'firebase_options.dart';
import 'gen_l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase y el handler de background DEBEN quedar registrados antes de `runApp`
  // (Firebase porque cualquier consumidor de FCM lo asume listo; el background handler
  // porque corre en un isolate aparte y se ata por puntero estable).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

  // Notification channel + permisos FCM se inicializan tras el primer frame
  // (ver `_TexiAppState.initState`) para no demorar la primera renderización.

  runApp(
    const ProviderScope(
      child: TexiApp(),
    ),
  );
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

  /// Inicialización diferida tras el primer frame: canal de notificaciones local,
  /// permisos/listeners de FCM. No bloquea la primera renderización.
  Future<void> _bootstrapDeferredServices() async {
    try {
      await PassengerNotificationService.instance.initialize();
    } catch (_) {
      // Falla silenciosa: la app sigue usable sin canal local; FCM puede reintentar más tarde.
    }
    try {
      await setupPassengerFirebaseMessaging();
    } catch (_) {
      // Permisos o listeners pueden completarse en sesiones siguientes; no bloquea login.
    }
  }

  /// App cerrada: el usuario abre desde el toque en la notificación (p. ej. conductor llegó).
  Future<void> _consumeInitialPassengerFcmMessage() async {
    try {
      final msg = await FirebaseMessaging.instance.getInitialMessage();
      if (msg == null) return;
      await handlePassengerFcmNotificationOpen(msg);
    } catch (_) {
      // Widget tests y arranques sin `Firebase.initializeApp` (no pasan por main).
    }
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
