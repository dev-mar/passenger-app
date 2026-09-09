import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, debugPrint;
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Renderer Android fuera del hilo de [runApp]. El splash cubre el arranque;
/// [ensureReady] espera un tope corto antes del primer [GoogleMap].
class PassengerMapsBootstrap {
  PassengerMapsBootstrap._();

  static Future<void>? _rendererFuture;

  static Future<void> startAndroidRenderer() {
    return _rendererFuture ??= _initAndroidRenderer();
  }

  static Future<void> ensureReady({
    Duration timeout = const Duration(milliseconds: 1800),
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await startAndroidRenderer().timeout(timeout);
    } catch (_) {}
  }

  static Future<void> _initAndroidRenderer() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final maps = GoogleMapsFlutterPlatform.instance;
    if (maps is! GoogleMapsFlutterAndroid) return;
    maps.useAndroidViewSurface = true;
    try {
      await maps.initializeWithRenderer(AndroidMapRenderer.latest);
    } catch (e) {
      debugPrint('[PassengerMaps] renderer: $e');
    }
  }
}
