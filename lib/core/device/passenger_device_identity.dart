import 'dart:math';

import '../storage/passenger_secure_storage.dart';

/// UUID estable por instalación para gestión de sesión (no vinculación permanente).
class PassengerDeviceIdentity {
  PassengerDeviceIdentity._();

  static const _storageKey = 'passenger_stable_device_id';

  static Future<String> stableDeviceId() async {
    final existing = await PassengerSecureStorage.read(_storageKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    final created = _generateUuidV4();
    await PassengerSecureStorage.write(_storageKey, created);
    return created;
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();
    return '${b[0]}${b[1]}${b[2]}${b[3]}-'
        '${b[4]}${b[5]}-'
        '${b[6]}${b[7]}-'
        '${b[8]}${b[9]}-'
        '${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }
}
