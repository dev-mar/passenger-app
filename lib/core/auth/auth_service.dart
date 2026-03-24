import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

/// Claves de almacenamiento seguro.
const String _keyAuthToken = 'auth_token';
const String _keyRefreshToken = 'refresh_token';
const String _keyExpiresAt = 'auth_token_expires_at';
const String _keyPassengerDisplayName = 'passenger_display_name';

/// Margen en segundos para considerar el token "por vencer" y refrescarlo antes.
const int _expiryMarginSeconds = 300; // 5 minutos

/// Servicio centralizado de autenticación: token de acceso, refresh y sesión persistente.
/// - Si el backend devuelve [refresh_token] y [expires_in] en login, se guardan.
/// - [getValidToken()] devuelve el token actual o refresca con [refresh_token] si está por vencer/vencido.
/// - Si no hay refresh en el backend, el comportamiento es el de antes (solo token, sin refresh).
/// - Si una petición devuelve 401, se llama [logout] y [onSessionExpired] para desloguear y llevar a login.
class AuthService {
  AuthService._();
  static const _storage = FlutterSecureStorage();

  /// Callback que la app debe asignar al arrancar (main). Se invoca cuando el backend
  /// responde 401 (token expirado/inválido) para cerrar sesión y redirigir a login.
  static void Function()? onSessionExpired;

  static final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrlAuth,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  /// Devuelve un token válido para usar en APIs. Si hay refresh_token y el token
  /// está vencido o por vencer, intenta refrescar. Retorna null si no hay sesión o el refresh falla.
  static Future<String?> getValidToken() async {
    String? token = await _storage.read(key: _keyAuthToken);
    String? refreshToken = await _storage.read(key: _keyRefreshToken);
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);
    int? expiresAt = expiresAtStr != null ? int.tryParse(expiresAtStr) : null;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isExpired = expiresAt != null && nowSeconds >= (expiresAt - _expiryMarginSeconds);

    if (token != null && token.isNotEmpty && !isExpired) {
      return token;
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      final newToken = await _refresh(refreshToken);
      return newToken;
    }

    return token; // puede estar vencido pero no hay refresh; el backend devolverá 401
  }

  /// Guarda token (y opcionalmente refresh_token y expires_in) tras login o refresh.
  static Future<void> saveSession({
    required String token,
    String? refreshToken,
    int? expiresInSeconds,
  }) async {
    await _storage.write(key: _keyAuthToken, value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } else {
      await _storage.delete(key: _keyRefreshToken);
    }
    if (expiresInSeconds != null && expiresInSeconds > 0) {
      final expiresAt = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expiresInSeconds;
      await _storage.write(key: _keyExpiresAt, value: expiresAt.toString());
    } else {
      await _storage.delete(key: _keyExpiresAt);
    }
  }

  /// Cierra sesión: borra token y refresh.
  static Future<void> logout() async {
    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyExpiresAt);
    await _storage.delete(key: _keyPassengerDisplayName);
  }

  /// Guarda el nombre visible del pasajero localmente (simulación de perfil).
  static Future<void> savePassengerDisplayName(String name) async {
    await _storage.write(key: _keyPassengerDisplayName, value: name);
  }

  static Future<String?> getPassengerDisplayName() async {
    return _storage.read(key: _keyPassengerDisplayName);
  }

  /// Indica si hay al menos un token guardado (puede estar vencido).
  static Future<bool> hasStoredSession() async {
    final token = await _storage.read(key: _keyAuthToken);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> _refresh(String refreshToken) async {
    try {
      final path = AppConfig.refreshPath;
      final response = await _dio.post(
        path,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      if (data is! Map) return null;

      final newToken = data['token']?.toString();
      if (newToken == null || newToken.isEmpty) return null;

      final newRefresh = data['refresh_token']?.toString();
      final expiresIn = data['expires_in'];
      int? expiresInSec;
      if (expiresIn is int) {
        expiresInSec = expiresIn;
      } else if (expiresIn is num) {
        expiresInSec = expiresIn.toInt();
      }

      await saveSession(
        token: newToken,
        refreshToken: newRefresh ?? refreshToken,
        expiresInSeconds: expiresInSec,
      );
      if (kDebugMode) {
        debugPrint('[AuthService] Token refrescado correctamente');
      }
      return newToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] Error al refrescar token: $e');
      }
      return null;
    }
  }
}
