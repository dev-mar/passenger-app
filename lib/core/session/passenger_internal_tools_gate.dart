import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../config/passenger_app_environment.dart';

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

final passengerInternalToolsVisibleProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (PassengerAppEnvironment.showsInternalToolsByDefault) return true;
  final phone = await AuthService.readLoginPhoneE164Digits();
  return PassengerInternalToolsGate.phoneAllowsInternalTools(phone);
});
