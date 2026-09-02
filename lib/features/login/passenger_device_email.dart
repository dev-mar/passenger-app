import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'services/passenger_google_sign_in_service.dart';

const _deviceEmailChannel = MethodChannel('texi_passenger/device_email');

/// Correo de una cuenta del dispositivo.
/// Android: selector nativo de cuentas Google (igual que conductor).
/// iOS: Google Sign-In si el build tiene `GOOGLE_OAUTH_SERVER_CLIENT_ID`; si no, Autofill del teclado.
Future<String?> pickPassengerDeviceEmail() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final native = await _pickAndroidAccountEmail();
    if (native != null) return native;
  }
  final google = PassengerGoogleSignInService();
  if (google.isConfigured) {
    try {
      return await google.pickAccountEmail();
    } catch (_) {
      return null;
    }
  }
  return null;
}

Future<String?> _pickAndroidAccountEmail() async {
  try {
    final raw = await _deviceEmailChannel.invokeMethod<String>('pickEmail');
    final email = raw?.trim();
    if (email == null || email.isEmpty || !email.contains('@')) return null;
    return email;
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
