// Generado por scripts/generate-firebase-options.ps1
// Fuentes: android/app/src/{dev|prod}/google-services.json
//
// Dev:  texi-prod - com.taxitexi.texi_passenger_app.dev
// Prod: prodtexiappgm - com.taxitexi.texi_passenger_app

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/passenger_app_environment.dart';

/// Configuracion Firebase - app pasajero.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions: web no configurado para esta app.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PassengerAppEnvironment.isProd ? androidProd : androidDev;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions: anade GoogleService-Info.plist y flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions: plataforma no soportada.',
        );
    }
  }

  static const FirebaseOptions androidDev = FirebaseOptions(
    apiKey: 'AIzaSyBjgqer8v1_GaXV6zzwl5UQhTMV9GUBSTs',
    appId: '1:935442837361:android:94a27f405c552edddf50d0',
    messagingSenderId: '935442837361',
    projectId: 'texi-prod',
    storageBucket: 'texi-prod.firebasestorage.app',
  );

  static const FirebaseOptions androidProd = FirebaseOptions(
    apiKey: 'AIzaSyC9tAzsQNcJOh91C5JlZxVXYmGW9j67WNk',
    appId: '1:464855616265:android:112ed9f31d26c508c6a1d8',
    messagingSenderId: '464855616265',
    projectId: 'prodtexiappgm',
    storageBucket: 'prodtexiappgm.firebasestorage.app',
  );
}
