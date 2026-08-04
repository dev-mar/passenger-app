import 'dart:convert';

import '../../features/login/models/passenger_auth_lockout.dart';
import 'passenger_secure_storage.dart';

/// Persiste bloqueo auth para reanudar countdown al cerrar/reabrir la app.
class PassengerAuthLockoutStorage {
  PassengerAuthLockoutStorage._();

  static const String _key = 'passenger_auth_lockout_v1';

  static Future<void> save(PassengerAuthLockout lockout) async {
    await PassengerSecureStorage.write(
      _key,
      jsonEncode(lockout.toJson()),
    );
  }

  static Future<PassengerAuthLockout?> readActive() async {
    try {
      final raw = await PassengerSecureStorage.read(
        _key,
        timeout: const Duration(seconds: 3),
      );
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final lockout = PassengerAuthLockout.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (!lockout.isActive) {
        await clear();
        return null;
      }
      return lockout;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await PassengerSecureStorage.delete(_key);
  }
}
