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
}
