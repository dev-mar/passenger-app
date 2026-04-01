import 'dart:async' show unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/config/app_config.dart';
import 'core/config/locale_provider.dart';
import 'core/auth/auth_service.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(
    passengerFirebaseMessagingBackgroundHandler,
  );
  await PassengerNotificationService.instance.initialize();
  await setupPassengerFirebaseMessaging();
  AuthService.onSessionEstablished = () => PassengerPushTokenService.instance.syncTokenIfPossible();
  // Cuando el backend devuelve 401 (token expirado), se cierra sesión y se redirige a login.
  AuthService.onSessionExpired = () {
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).goNamed(AppRouter.login);
    }
  };

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
      unawaited(_consumeInitialPassengerFcmMessage());
    });
  }

  /// App cerrada: el usuario abre desde el toque en la notificación (p. ej. conductor llegó).
  Future<void> _consumeInitialPassengerFcmMessage() async {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg == null) return;
    await handlePassengerFcmNotificationOpen(msg);
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
