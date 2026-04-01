import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../config/app_config.dart';

/// Pantallas internas (labs / QA) visibles solo con `--dart-define` o allowlist por prefijo nacional.
///
/// Misma regla que conductor: [qaNationalPrefix] en el número local (p. ej. Bolivia +591 → `591` + `10011…`).
class PassengerInternalToolsGate {
  PassengerInternalToolsGate._();

  static const String qaNationalPrefix = '10011';

  static bool phoneAllowsInternalTools(String? digitsOnly) {
    if (digitsOnly == null || digitsOnly.isEmpty) return false;
    final d = digitsOnly.replaceAll(RegExp(r'\D'), '');
    if (d.length < 8) return false;
    if (d.startsWith('591') && d.length > 3) {
      return d.substring(3).startsWith(qaNationalPrefix);
    }
    return d.startsWith(qaNationalPrefix);
  }
}

/// `true` si el build fuerza labs o el teléfono guardado al login está en allowlist QA.
final passengerInternalToolsVisibleProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (AppConfig.passengerInternalToolsDartDefine) return true;
  final phone = await AuthService.readLoginPhoneE164Digits();
  return PassengerInternalToolsGate.phoneAllowsInternalTools(phone);
});
