import 'package:dio/dio.dart';

/// Extrae `code` de respuestas tipo envelope OK/fail del backend unificado.
class TexiBackendError {
  static String? codeFromDio (Object? e) {
    if (e is! DioException) return null;
    return codeFromResponse(e.response?.data);
  }

  static String? codeFromResponse (dynamic data) {
    if (data is Map) {
      final direct = data['code']?.toString().trim();
      if (direct != null && direct.isNotEmpty) return direct;
      final err = data['error'];
      if (err is Map) {
        final c = err['code']?.toString().trim();
        if (c != null && c.isNotEmpty) return c;
      }
    }
    return null;
  }

  static String? messageFromResponse (dynamic data) {
    if (data is Map) {
      final m = data['message']?.toString().trim();
      if (m != null && m.isNotEmpty) return m;
      final err = data['error'];
      if (err is Map) {
        final mm = err['message']?.toString().trim();
        if (mm != null && mm.isNotEmpty) return mm;
      }
    }
    return null;
  }

  /// True si el texto parece nota interna, HTML de gateway o error de red crudo.
  static bool looksInternal (String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return true;
    final lower = s.toLowerCase();
    if (lower.contains('<!doctype') ||
        lower.contains('<html') ||
        lower.contains('validatestatus') ||
        lower.contains('status code of')) {
      return true;
    }
    if (RegExp(r'\b(PASS_AUTH_|RBAC_|TRIP_|CLIENT_|BACKEND_|NETWORK_)').hasMatch(s)) {
      return true;
    }
    if (RegExp(r'\b(4\d\d|5\d\d)\s*:').hasMatch(s)) return true;
    const needles = <String>[
      'firebase',
      'turnstile',
      'cloudflare',
      'presign',
      'redis',
      'postgres',
      'sqlstate',
      'exception',
      'stack trace',
      'dioexception',
      'socketexception',
      'econn',
      'etimedout',
      'internal error',
      'error code:',
      'dart-define',
      'sha-1',
      'sha1',
      'null is not',
      'undefined is not',
      'cannot read',
    ];
    for (final n in needles) {
      if (lower.contains(n)) return true;
    }
    if (lower.contains('json') &&
        (lower.contains('parse') ||
            lower.contains('decode') ||
            lower.contains('unexpected'))) {
      return true;
    }
    if (s.length > 220) return true;
    return false;
  }

  /// Mensaje del backend apto para UI; null si es técnico.
  static String? userSafeMessage (String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty || looksInternal(s)) return null;
    return s;
  }
}
