import 'package:dio/dio.dart';

import '../auth/auth_service.dart';
import '../config/app_config.dart';
import 'passenger_http_resilience.dart';

/// Cliente HTTP unificado del pasajero: auth (`/api/v2`) y viajes (raíz `/passengers/...`).
///
/// - Público: login, verify, registro (sin Bearer).
/// - Autenticado: Bearer vía [AuthService.getValidToken] + interceptor 401 → logout.
/// - Retry + telemetría: [requestWithRetry] (espejo conductor).
class PassengerApiClient {
  PassengerApiClient({
    String? authBaseUrl,
    String? tripsBaseUrl,
  })  : _authBaseUrl = authBaseUrl ?? AppConfig.baseUrlAuth,
        _tripsBaseUrl = tripsBaseUrl ?? AppConfig.baseUrlTripsRest;

  final String _authBaseUrl;
  final String _tripsBaseUrl;

  /// Dio sin Bearer (login, verify, registro).
  static Dio createPublicDio({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) {
    if (baseUrl != null && baseUrl != AppConfig.baseUrlAuth) {
      return Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          headers: const <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
    }
    return passengerAuthPublicHttpClient(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  Future<String> requireToken() async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const PassengerApiSessionException();
    }
    return token;
  }

  /// POST público sin Bearer. Sin retry — feedback inmediato al usuario.
  Future<Response<T>> postPublic<T>({
    required String path,
    Object? data,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) {
    final dio = createPublicDio(
      baseUrl: _authBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    return dio.post<T>(path, data: data);
  }

  /// GET público sin Bearer (p. ej. polling challenge-status pre-login).
  Future<Response<T>> getPublic<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) {
    final dio = createPublicDio(
      baseUrl: _authBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> getAuthWithRetry<T>({
    required String path,
    required String flow,
    Map<String, dynamic>? queryParameters,
    int maxAttempts = 3,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    ValidateStatus? validateStatus,
  }) async {
    final token = await requireToken();
    final dio = buildPassengerAuthAuthedDio(
      token: token,
      baseUrl: _authBaseUrl,
      connectTimeout: connectTimeout ?? const Duration(seconds: 15),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 20),
      validateStatus: validateStatus,
    );
    return requestWithRetry<Response<T>>(
      flow: flow,
      endpoint: path,
      maxAttempts: maxAttempts,
      operation: () => dio.get<T>(
        path,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<Response<T>> postAuthWithRetry<T>({
    required String path,
    required String flow,
    Object? data,
    int maxAttempts = 3,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) async {
    final token = await requireToken();
    final dio = buildPassengerAuthAuthedDio(
      token: token,
      baseUrl: _authBaseUrl,
      connectTimeout: connectTimeout ?? const Duration(seconds: 15),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 20),
    );
    return requestWithRetry<Response<T>>(
      flow: flow,
      endpoint: path,
      maxAttempts: maxAttempts,
      operation: () => dio.post<T>(path, data: data),
    );
  }

  Future<Response<T>> patchAuthWithRetry<T>({
    required String path,
    required String flow,
    Object? data,
    int maxAttempts = 3,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) async {
    final token = await requireToken();
    final dio = buildPassengerAuthAuthedDio(
      token: token,
      baseUrl: _authBaseUrl,
      connectTimeout: connectTimeout ?? const Duration(seconds: 15),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 20),
    );
    return requestWithRetry<Response<T>>(
      flow: flow,
      endpoint: path,
      maxAttempts: maxAttempts,
      operation: () => dio.patch<T>(path, data: data),
    );
  }

  /// DELETE autenticado (p. ej. eliminación de cuenta). Sin retry — acción destructiva.
  Future<Response<T>> deleteAuth<T>({
    required String path,
    required String flow,
    Object? data,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) async {
    final token = await requireToken();
    final dio = buildPassengerAuthAuthedDio(
      token: token,
      baseUrl: _authBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    return dio.delete<T>(path, data: data);
  }

  /// GET autenticado sin retry (p. ej. polling tickets).
  Future<Response<T>> getAuth<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) async {
    final token = await requireToken();
    final dio = buildPassengerAuthAuthedDio(
      token: token,
      baseUrl: _authBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  /// POST autenticado sin retry.
  Future<Response<T>> postAuth<T>({
    required String path,
    Object? data,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) async {
    final token = await requireToken();
    final dio = buildPassengerAuthAuthedDio(
      token: token,
      baseUrl: _authBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    return dio.post<T>(path, data: data);
  }

  /// PUT a URL presignada S3 (sin Bearer Texi).
  Future<void> uploadToPresignedUrl({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 60),
  }) async {
    final dio = buildPassengerPresignedUploadDio(
      contentType: contentType,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    );
    await dio.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(contentType: contentType),
    );
  }

  /// Factory para [TripsApi] y otros consumidores del dominio viajes.
  Dio createTripsAuthedDio(String token) {
    return buildPassengerTripsAuthedDio(
      token: token,
      baseUrl: _tripsBaseUrl,
    );
  }

  /// Parsea envelope `{ success, data }` o lanza [PassengerApiResponseException].
  static Map<String, dynamic> parseSuccessData(Map<String, dynamic>? root) {
    if (root == null) {
      throw const PassengerApiResponseException('empty_response');
    }
    final success = root['success'];
    final isOk = success == true || success == 'true';
    if (!isOk) {
      final code = root['code']?.toString();
      final msg = root['message']?.toString();
      throw PassengerApiResponseException(
        code ?? 'request_failed',
        msg,
      );
    }
    final data = root['data'];
    if (data is! Map) {
      throw const PassengerApiResponseException('bad_format');
    }
    return Map<String, dynamic>.from(data);
  }
}

class PassengerApiSessionException implements Exception {
  const PassengerApiSessionException();

  @override
  String toString() => 'no_token';
}

class PassengerApiResponseException implements Exception {
  const PassengerApiResponseException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}
