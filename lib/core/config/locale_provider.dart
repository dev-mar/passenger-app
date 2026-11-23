import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/passenger_secure_storage.dart';

final localeProvider = StateProvider<Locale?>((ref) => null);

List<Locale> get supportedLocales => const [
      Locale('es'),
      Locale('en'),
    ];

const passengerLocaleStorageKey = 'passenger_app_locale';

Future<Locale?> readSavedPassengerLocale() async {
  try {
    final raw = await PassengerSecureStorage.read(
      passengerLocaleStorageKey,
      timeout: const Duration(milliseconds: 1200),
    );
    if (raw == 'en') return const Locale('en');
    if (raw == 'es') return const Locale('es');
  } catch (_) {}
  return null;
}

void applyPassengerLocale(ProviderContainer container, Locale locale) {
  final code = locale.languageCode.toLowerCase() == 'en' ? 'en' : 'es';
  container.read(localeProvider.notifier).state = Locale(code);
  unawaited(PassengerSecureStorage.write(passengerLocaleStorageKey, code));
}
