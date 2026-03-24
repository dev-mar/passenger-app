import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Locale seleccionado por el usuario. Null = usar el del sistema.
final localeProvider = StateProvider<Locale?>((ref) => null);

/// Locales soportados (es, en).
List<Locale> get supportedLocales => const [
      Locale('es'),
      Locale('en'),
    ];
