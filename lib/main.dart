import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_config.dart';
import 'core/config/locale_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'gen_l10n/app_localizations.dart';

void main() {
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

class TexiApp extends ConsumerWidget {
  const TexiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
