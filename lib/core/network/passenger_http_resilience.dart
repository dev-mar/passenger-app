import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_service.dart';
import '../auth/passenger_session_expulsion.dart';
import '../config/app_config.dart';
import 'passenger_resilience_telemetry_service.dart';

final Random _retryJitterRandom = Random();

int? retryAfterMsFromDio(DioException error) {
  final retryAfterRaw = error.response?.headers.value('retry-after');
  if (retryAfterRaw != null) {
    final sec = int.tryParse(retryAfterRaw.trim());
    if (sec != null && sec > 0) return sec * 1000;
  }
  return retryAfterMsFromResponse(error.response?.data, error.response?.headers);
}

int? retryAfterMsFromResponse(dynamic data, Headers? headers) {
  int? fromPayload(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final errorObj = map['error'];
    if (errorObj is Map) {
      final err = Map<String, dynamic>.from(errorObj);
      final msRaw = err['retry_after_ms'];
      if (msRaw is num && msRaw > 0) return msRaw.toInt();
      final secRaw = err['retry_after_sec'];
      if (secRaw is num && secRaw > 0) return secRaw.toInt() * 1000;
    }
    final msTop = map['retry_after_ms'];
    if (msTop is num && msTop > 0) return msTop.toInt();
    final secTop = map['retry_after_sec'];
    if (secTop is num && secTop > 0) return secTop.toInt() * 1000;
    return null;
  }

  final payloadMs = fromPayload(data);
  if (payloadMs != null && payloadMs > 0) return payloadMs;
  final rawRetryAfter = headers?.value('retry-after');
  if (rawRetryAfter != null) {
    final sec = int.tryParse(rawRetryAfter.trim());
    if (sec != null && sec > 0) return sec * 1000;
  }
  return null;
}

bool isRetryableDioFailure(DioException error) {
  final status = error.response?.statusCode ?? 0;
  if (status == 429 || status >= 500) return true;
  return error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.unknown;
}

/// Códigos estables para UI de login/verify (sin depender del mensaje Dio).
String? networkErrorCodeFromDio(DioException error) {
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return 'NETWORK_TIMEOUT';
  }
  if (error.type == DioExceptionType.connectionError) {
    return 'NETWORK_CONNECTION';
  }
  return null;
}

Future<T> requestWithRetry<T>({
  required Future<T> Function() operation,
  required String flow,
  required String endpoint,
  int maxAttempts = 3,
  int baseDelayMs = 320,
  int maxDelayMs = 4500,
}) async {
  var attempt = 0;
  while (true) {
    attempt += 1;
    try {
      return await operation();
    } on DioException catch (e) {
      final shouldRetry = attempt < maxAttempts && isRetryableDioFailure(e);
      if (!shouldRetry) {
        unawaited(
          PassengerResilienceTelemetryService.sendEvent(
            flow: flow,
            endpoint: endpoint,
            event: 'retry_exhausted',
            attempt: attempt,
            statusCode: e.response?.statusCode,
          ),
        );
        rethrow;
      }
      final retryAfterMs = retryAfterMsFromDio(e);
      final expDelay = baseDelayMs * (1 << (attempt - 1).clamp(0, 5));
      final jitter = _retryJitterRandom.nextInt(260);
      final waitMs = max(retryAfterMs ?? 0, expDelay + jitter)
          .clamp(250, maxDelayMs)
          .toInt();
      final statusCode = e.response?.statusCode;
      unawaited(
        PassengerResilienceTelemetryService.sendEvent(
          flow: flow,
          endpoint: endpoint,
          event: statusCode == 429 ? 'rate_limited' : 'retry_attempt',
          attempt: attempt,
          waitMs: waitMs,
          statusCode: statusCode,
        ),
      );
      await Future<void>.delayed(Duration(milliseconds: waitMs));
    }
  }
}

void attachPassengerSessionExpiredInterceptor(Dio dio) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          markPassengerSessionExpelled();
          AuthService.logout();
          AuthService.onSessionExpired?.call();
        }
        return handler.next(error);
      },
    ),
  );
}

Dio buildPassengerAuthAuthedDio({
  required String token,
  String? baseUrl,
  Duration connectTimeout = const Duration(seconds: 15),
  Duration receiveTimeout = const Duration(seconds: 20),
  ValidateStatus? validateStatus,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? AppConfig.baseUrlAuth,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: validateStatus,
    ),
  );
  attachPassengerSessionExpiredInterceptor(dio);
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }
  return dio;
}

Dio buildPassengerTripsAuthedDio({
  required String token,
  String? baseUrl,
  Duration connectTimeout = const Duration(seconds: 15),
  Duration receiveTimeout = const Duration(seconds: 15),
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? AppConfig.baseUrlTripsRest,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  attachPassengerSessionExpiredInterceptor(dio);
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }
  return dio;
}

Dio? _passengerAuthPublicDio;

/// Dio compartido contra `AppConfig.baseUrlAuth` sin Bearer (refresh, telemetría, push).
Dio passengerAuthPublicHttpClient({
  Duration connectTimeout = const Duration(seconds: 15),
  Duration receiveTimeout = const Duration(seconds: 15),
}) {
  final existing = _passengerAuthPublicDio;
  if (existing != null) return existing;
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrlAuth,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  _passengerAuthPublicDio = dio;
  return dio;
}

Dio? _passengerGoogleMapsDio;

/// Dio compartido para APIs externas Google (Geocoding, Directions, Places).
Dio passengerGoogleMapsHttpClient({
  Duration connectTimeout = const Duration(seconds: 12),
  Duration receiveTimeout = const Duration(seconds: 12),
}) {
  final existing = _passengerGoogleMapsDio;
  if (existing != null) return existing;
  final dio = Dio(
    BaseOptions(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    ),
  );
  _passengerGoogleMapsDio = dio;
  return dio;
}

/// PUT a URL presignada S3 (sin base URL Texi ni Bearer).
Dio buildPassengerPresignedUploadDio({
  required String contentType,
  Duration connectTimeout = const Duration(seconds: 30),
  Duration receiveTimeout = const Duration(seconds: 60),
}) {
  return Dio(
    BaseOptions(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: <String, String>{'Content-Type': contentType},
    ),
  );
}
