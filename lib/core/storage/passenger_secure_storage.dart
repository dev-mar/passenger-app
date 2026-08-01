import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Acceso serializado a KeyStore/EncryptedSharedPreferences (Android release).
///
/// Varias instancias de [FlutterSecureStorage] en paralelo pueden bloquear el arranque.
class PassengerSecureStorage {
  PassengerSecureStorage._();

  static const FlutterSecureStorage instance = FlutterSecureStorage();

  static Future<void>? _chain = Future<void>.value();

  static Future<T> run<T>(Future<T> Function(FlutterSecureStorage storage) operation) {
    final scheduled = _chain!.then((_) => operation(instance));
    _chain = scheduled.then((_) {}, onError: (_) {});
    return scheduled;
  }

  static Future<String?> read(String key, {Duration timeout = const Duration(seconds: 4)}) {
    return run(
      (storage) => storage.read(key: key).timeout(timeout, onTimeout: () => null),
    );
  }

  static Future<void> write(String key, String value) {
    return run((storage) => storage.write(key: key, value: value));
  }

  static Future<void> delete(String key) {
    return run((storage) => storage.delete(key: key));
  }
}
