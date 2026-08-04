import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/passenger_api_client.dart';
import '../../core/network/passenger_api_providers.dart';
import '../../core/network/passenger_client_meta.dart';
import '../../core/config/passenger_app_environment.dart';
import '../../core/network/passenger_http_resilience.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/storage/passenger_auth_lockout_storage.dart';
import 'models/passenger_auth_lockout.dart';
import 'services/passenger_google_sign_in_service.dart';
import 'utils/passenger_play_review_credentials.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(passengerApiClientProvider));
});

/// Próximo paso del flujo de login.
enum LoginNextStep {
  tripRequest,
  verifyCode,
  verifyEmailCode,
  profileRequired,
  /// Step-up backend deshabilitado en UX: usar [authLockout] o [attemptsLimitReached].
  stepUp,
  attemptsLimitReached,
  authLockout,
  phoneRequired,
  error,
}

class LoginState {
  const LoginState({
    this.errorMessage,
    this.errorCode,
    this.accountDeletion,
    this.verificationChannel,
    this.challengeId,
    this.waDeepLink,
    this.googleLinkToken,
    this.googleEmail,
    this.googleDisplayName,
    this.loginEmail,
    this.entryCaptchaToken,
    this.authLockout,
  });

  final String? errorMessage;
  /// Código de negocio del backend (`PASS_AUTH_*`, etc.) cuando aplica.
  final String? errorCode;
  final Map<String, dynamic>? accountDeletion;
  final String? verificationChannel;
  final String? challengeId;
  final String? waDeepLink;
  final String? googleLinkToken;
  final String? googleEmail;
  final String? googleDisplayName;
  final String? loginEmail;
  /// Token Turnstile de la puerta de entrada (UX; backend lo validará en fase posterior).
  final String? entryCaptchaToken;
  final PassengerAuthLockout? authLockout;
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._api) : super(const LoginState());

  final PassengerApiClient _api;
  final PassengerGoogleSignInService _googleSignIn = PassengerGoogleSignInService();

  /// Mapea Dio → código de negocio / transporte (sin texto crudo de validateStatus).
  Future<LoginNextStep> _failFromDio(
    DioException e, {
    String? countryCode,
    String? phoneNumber,
    String fallbackCode = 'AUTH_LOGIN_FAILED',
  }) async {
    final networkCode = networkErrorCodeFromDio(e);
    if (networkCode != null) {
      return _fail(code: networkCode);
    }
    final data = e.response?.data;
    final businessCode = TexiBackendError.codeFromResponse(data);
    final unavailable = unavailableBackendCodeFromDio(e);
    final code = businessCode ?? unavailable ?? fallbackCode;
    final message = safeAuthErrorMessage(
      backendMessage: TexiBackendError.messageFromResponse(data),
      dioMessage: e.message,
    );
    if (PassengerAuthLockout.isLockoutCode(code)) {
      return _resolveAuthLockoutOrLimit(
        code: code,
        responseData: data,
        message: message,
        countryCode: countryCode,
        phoneNumber: phoneNumber,
      );
    }
    Map<String, dynamic>? payload;
    if (data is Map && data['data'] is Map) {
      payload = Map<String, dynamic>.from(data['data'] as Map);
    }
    return _fail(code: code, message: message, data: payload);
  }

  Future<LoginNextStep> _resolveAuthLockoutOrLimit({
    required String? code,
    dynamic responseData,
    String? message,
    String? countryCode,
    String? phoneNumber,
    String? email,
  }) async {
    if (PassengerPlayReviewCredentials.shouldBypassClientLockout(
      countryCode: countryCode,
      phoneNumber: phoneNumber,
      email: email,
    )) {
      await PassengerAuthLockoutStorage.clear();
      state = LoginState(
        errorCode: code,
        errorMessage: message,
      );
      return LoginNextStep.error;
    }
    final lockout = PassengerAuthLockout.tryParse(
      code: code,
      responseData: responseData,
      message: message,
      countryCode: countryCode,
      phoneNumber: phoneNumber,
    );
    if (lockout != null) {
      await PassengerAuthLockoutStorage.save(lockout);
      state = LoginState(
        errorCode: code,
        errorMessage: message,
        authLockout: lockout,
      );
      return LoginNextStep.authLockout;
    }
    if (PassengerAuthLockout.isLockoutCode(code)) {
      return LoginNextStep.attemptsLimitReached;
    }
    return LoginNextStep.error;
  }

  /// Login según contrato:
  /// - Si el usuario ya existe y está activo, devuelve token.
  /// - Si el usuario es nuevo o no verificado, devuelve status=pending y se solicita código de verificación.
  Future<LoginNextStep> login({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
    bool cancelPendingDeletion = false,
    String? otpChannel,
    String? entryCaptchaToken,
  }) async {
    state = LoginState(
      entryCaptchaToken: entryCaptchaToken,
    );

    if (PassengerPlayReviewCredentials.isAllowlistedPhone(
      countryCode: countryCode,
      phoneNumber: phoneNumber,
    )) {
      await PassengerAuthLockoutStorage.clear();
    }

    try {
      final clientMeta = await passengerAuthClientMeta();
      String? pushToken;
      try {
        if (Firebase.apps.isNotEmpty) {
          final t = await FirebaseMessaging.instance
              .getToken()
              .timeout(const Duration(milliseconds: 1500));
          if (t != null && t.trim().isNotEmpty) pushToken = t.trim();
        }
      } catch (_) {}

      final resolvedChannel = otpChannel ??
          (PassengerAppEnvironment.multichannelAuthEnabled
              ? 'whatsapp_inbound'
              : (pushToken != null ? 'push' : 'code'));

      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.loginPath,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': countryCode,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          'otp_channel': resolvedChannel,
          'push_token': ?pushToken,
          if (cancelPendingDeletion) 'cancel_pending_deletion': true,
          // Reservado contrato Fase 6 — backend ignorará hasta implementación.
          if (entryCaptchaToken != null &&
              entryCaptchaToken.trim().isNotEmpty &&
              entryCaptchaToken != 'dev-bypass-captcha')
            'entry_captcha_token': entryCaptchaToken.trim(),
        },
      );

      final body = response.data;
      if (body is! Map) {
        return _fail(code: 'CLIENT_INVALID_RESPONSE');
      }
      final envelope = Map<String, dynamic>.from(body as Map);

      final success = envelope['success'] == true;
      if (!success) {
        final code = envelope['code']?.toString();
        if (PassengerAuthLockout.isLockoutCode(code)) {
          return _resolveAuthLockoutOrLimit(
            code: code,
            responseData: envelope,
            message: envelope['message']?.toString(),
            countryCode: countryCode,
            phoneNumber: phoneNumber,
          );
        }
        final msg = envelope['message']?.toString();
        return _fail(
          code: code ?? 'AUTH_LOGIN_FAILED',
          message: msg,
          data: envelope['data'] is Map
              ? Map<String, dynamic>.from(envelope['data'] as Map)
              : null,
        );
      }

      final data = envelope['data'];
      if (data is! Map) {
        return _fail(code: 'CLIENT_EMPTY_DATA');
      }

      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        final status = data['status']?.toString();
        final isVerified = data['is_verified'] == true;
        if (status == 'pending' || !isVerified) {
          state = LoginState(
            verificationChannel: data['verification_channel']?.toString(),
            challengeId: data['challenge_id']?.toString(),
            waDeepLink: data['wa_deep_link']?.toString(),
          );
          return LoginNextStep.verifyCode;
        }
        return _fail(code: 'CLIENT_TOKEN_MISSING');
      }

      final refreshToken = data['refresh_token']?.toString();
      final expiresIn = data['expires_in'];
      int? expiresInSec;
      if (expiresIn is int) {
        expiresInSec = expiresIn;
      } else if (expiresIn is num) {
        expiresInSec = expiresIn.toInt();
      }

      await AuthService.saveSession(
        token: token,
        refreshToken: refreshToken,
        expiresInSeconds: expiresInSec,
      );
      await AuthService.persistLoginPhoneE164(fullPhone);
      return LoginNextStep.tripRequest;
    } on DioException catch (e) {
      return _failFromDio(
        e,
        countryCode: countryCode,
        phoneNumber: phoneNumber,
      );
    } catch (_) {
      return _fail(code: 'CLIENT_UNEXPECTED');
    }
  }

  bool get isGoogleAuthConfigured => _googleSignIn.isConfigured;

  Future<LoginNextStep> loginWithGoogle({String? entryCaptchaToken}) async {
    state = LoginState(entryCaptchaToken: entryCaptchaToken);
    try {
      final idToken = await _googleSignIn.signInAndGetIdToken();
      if (idToken == null) {
        return LoginNextStep.error;
      }
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.authGooglePath,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        data: <String, dynamic>{
          ...clientMeta,
          'id_token': idToken,
          if (entryCaptchaToken != null &&
              entryCaptchaToken.trim().isNotEmpty &&
              entryCaptchaToken != 'dev-bypass-captcha')
            'entry_captcha_token': entryCaptchaToken.trim(),
        },
      );
      final body = response.data;
      if (body is! Map) {
        return _fail(code: 'CLIENT_INVALID_RESPONSE');
      }
      final envelope = Map<String, dynamic>.from(body as Map);
      if (envelope['success'] != true) {
        final code = envelope['code']?.toString();
        if (PassengerAuthLockout.isLockoutCode(code)) {
          return _resolveAuthLockoutOrLimit(
            code: code,
            responseData: envelope,
            message: envelope['message']?.toString(),
          );
        }
        return _fail(
          code: code ?? 'PASS_AUTH_GOOGLE_FAILED',
          message: envelope['message']?.toString(),
        );
      }
      final code = envelope['code']?.toString();
      final data = envelope['data'];
      if (code == 'PASS_AUTH_PROFILE_REQUIRED' && data is Map) {
        final payload = Map<String, dynamic>.from(data);
        state = LoginState(
          googleEmail: payload['email']?.toString(),
          googleDisplayName: payload['display_name']?.toString(),
          loginEmail: payload['email']?.toString(),
        );
        return LoginNextStep.profileRequired;
      }
      if (data is! Map) {
        return _fail(code: 'CLIENT_EMPTY_DATA');
      }
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        return _fail(code: 'CLIENT_TOKEN_MISSING');
      }
      final refreshToken = data['refresh_token']?.toString();
      final expiresIn = data['expires_in'];
      int? expiresInSec;
      if (expiresIn is int) {
        expiresInSec = expiresIn;
      } else if (expiresIn is num) {
        expiresInSec = expiresIn.toInt();
      }
      await AuthService.saveSession(
        token: token,
        refreshToken: refreshToken,
        expiresInSeconds: expiresInSec,
      );
      final payload = Map<String, dynamic>.from(data);
      final display = payload['display_name']?.toString().trim();
      if (display != null && display.isNotEmpty) {
        await AuthService.savePassengerDisplayName(display);
      }
      return LoginNextStep.tripRequest;
    } on DioException catch (e) {
      return _failFromDio(e, fallbackCode: 'PASS_AUTH_GOOGLE_FAILED');
    } catch (_) {
      return _fail(code: 'CLIENT_UNEXPECTED');
    }
  }

  Future<LoginNextStep> requestEmailLoginChallenge({
    required String email,
    String? entryCaptchaToken,
  }) async {
    state = LoginState(
      entryCaptchaToken: entryCaptchaToken,
      loginEmail: email.trim(),
    );

    if (PassengerPlayReviewCredentials.isAllowlistedEmail(email)) {
      await PassengerAuthLockoutStorage.clear();
    }

    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.authEmailLoginChallengePath,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        data: <String, dynamic>{
          ...clientMeta,
          'email': email.trim(),
          if (entryCaptchaToken != null &&
              entryCaptchaToken.trim().isNotEmpty &&
              entryCaptchaToken != 'dev-bypass-captcha')
            'entry_captcha_token': entryCaptchaToken.trim(),
        },
      );
      final body = response.data;
      if (body is! Map) {
        return _fail(code: 'CLIENT_INVALID_RESPONSE');
      }
      final envelope = Map<String, dynamic>.from(body as Map);
      if (envelope['success'] != true) {
        final code = envelope['code']?.toString();
        if (PassengerAuthLockout.isLockoutCode(code)) {
          return _resolveAuthLockoutOrLimit(
            code: code,
            responseData: envelope,
            message: envelope['message']?.toString(),
            email: email.trim(),
          );
        }
        return _fail(
          code: code ?? 'PASS_AUTH_EMAIL_LOGIN_FAILED',
          message: envelope['message']?.toString(),
        );
      }
      state = LoginState(
        loginEmail: email.trim(),
        verificationChannel: 'email',
        entryCaptchaToken: entryCaptchaToken,
      );
      return LoginNextStep.verifyEmailCode;
    } on DioException catch (e) {
      return _failFromDio(e, fallbackCode: 'PASS_AUTH_EMAIL_LOGIN_FAILED');
    } catch (_) {
      return _fail(code: 'CLIENT_UNEXPECTED');
    }
  }

  Future<LoginNextStep> verifyEmailLoginCode({
    required String email,
    required String code,
  }) async {
    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.authEmailLoginVerifyPath,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        data: <String, dynamic>{
          ...clientMeta,
          'email': email.trim(),
          'email_code': code.trim(),
        },
      );
      final body = response.data;
      if (body is! Map) {
        return _fail(code: 'CLIENT_INVALID_RESPONSE');
      }
      final envelope = Map<String, dynamic>.from(body as Map);
      if (envelope['success'] != true) {
        final errCode = envelope['code']?.toString();
        if (PassengerAuthLockout.isLockoutCode(errCode)) {
          return _resolveAuthLockoutOrLimit(
            code: errCode,
            responseData: envelope,
            message: envelope['message']?.toString(),
            email: email.trim(),
          );
        }
        return _fail(
          code: errCode ?? 'PASS_AUTH_OTP_INVALID',
          message: envelope['message']?.toString(),
        );
      }
      final responseCode = envelope['code']?.toString();
      final data = envelope['data'];
      if (responseCode == 'PASS_AUTH_LOGIN_OK' && data is Map) {
        final payload = Map<String, dynamic>.from(data);
        final token = payload['token']?.toString();
        if (token == null || token.isEmpty) {
          return _fail(code: 'CLIENT_TOKEN_MISSING');
        }
        final refreshToken = payload['refresh_token']?.toString();
        final expiresIn = payload['expires_in'];
        int? expiresInSec;
        if (expiresIn is int) {
          expiresInSec = expiresIn;
        } else if (expiresIn is num) {
          expiresInSec = expiresIn.toInt();
        }
        await AuthService.saveSession(
          token: token,
          refreshToken: refreshToken,
          expiresInSeconds: expiresInSec,
        );
        final display = payload['display_name']?.toString().trim();
        if (display != null && display.isNotEmpty) {
          await AuthService.savePassengerDisplayName(display);
        }
        return LoginNextStep.tripRequest;
      }
      if (responseCode == 'PASS_AUTH_VERIFY_OK') {
        state = LoginState(loginEmail: email.trim());
        return LoginNextStep.profileRequired;
      }
      return _fail(code: responseCode ?? 'CLIENT_EMPTY_DATA');
    } on DioException catch (e) {
      return _failFromDio(e, fallbackCode: 'PASS_AUTH_OTP_INVALID');
    } catch (_) {
      return _fail(code: 'CLIENT_UNEXPECTED');
    }
  }

  Future<LoginNextStep> requestWhatsAppOutbound({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
    String? entryCaptchaToken,
  }) async {
    state = LoginState(entryCaptchaToken: entryCaptchaToken);
    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.loginPath,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': countryCode,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          'otp_channel': 'whatsapp_outbound',
          if (entryCaptchaToken != null &&
              entryCaptchaToken.trim().isNotEmpty &&
              entryCaptchaToken != 'dev-bypass-captcha')
            'entry_captcha_token': entryCaptchaToken.trim(),
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        final code = body is Map<String, dynamic> ? body['code']?.toString() : null;
        if (PassengerAuthLockout.isLockoutCode(code)) {
          return _resolveAuthLockoutOrLimit(
            code: code,
            responseData: body,
            message: body is Map<String, dynamic> ? body['message']?.toString() : null,
            countryCode: countryCode,
            phoneNumber: phoneNumber,
          );
        }
        return _fail(
          code: code ?? 'AUTH_LOGIN_FAILED',
          message: body is Map<String, dynamic> ? body['message']?.toString() : null,
        );
      }
      final data = body['data'];
      if (data is! Map) return _fail(code: 'CLIENT_EMPTY_DATA');
      final pending = Map<String, dynamic>.from(data);
      state = LoginState(
        verificationChannel: pending['verification_channel']?.toString() ?? 'whatsapp_outbound',
        challengeId: pending['challenge_id']?.toString(),
      );
      return LoginNextStep.verifyCode;
    } on DioException catch (e) {
      return _failFromDio(
        e,
        countryCode: countryCode,
        phoneNumber: phoneNumber,
      );
    } catch (_) {
      return _fail(code: 'CLIENT_UNEXPECTED');
    }
  }

  Future<LoginNextStep> requestSmsFirebase({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
    required String googleIdToken,
    String? entryCaptchaToken,
  }) async {
    state = LoginState(entryCaptchaToken: entryCaptchaToken);
    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.loginPath,
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': countryCode,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          'otp_channel': 'sms',
          'google_id_token': googleIdToken.trim(),
          if (entryCaptchaToken != null &&
              entryCaptchaToken.trim().isNotEmpty &&
              entryCaptchaToken != 'dev-bypass-captcha')
            'entry_captcha_token': entryCaptchaToken.trim(),
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        final map = body is Map<String, dynamic> ? body : null;
        final code = map?['code']?.toString();
        if (PassengerAuthLockout.isLockoutCode(code)) {
          return _resolveAuthLockoutOrLimit(
            code: code,
            responseData: body,
            message: map?['message']?.toString(),
            countryCode: countryCode,
            phoneNumber: phoneNumber,
          );
        }
        if (code == 'PASS_AUTH_SMS_GOOGLE_REQUIRED' ||
            code == 'PASS_AUTH_GOOGLE_TOKEN_INVALID' ||
            code == 'PASS_AUTH_GOOGLE_EMAIL_UNVERIFIED') {
          return _fail(
            code: code ?? 'PASS_AUTH_SMS_GOOGLE_REQUIRED',
            message: map?['message']?.toString(),
          );
        }
        return _fail(
          code: code ?? 'AUTH_LOGIN_FAILED',
          message: map?['message']?.toString(),
        );
      }
      final data = body['data'];
      if (data is! Map) return _fail(code: 'CLIENT_EMPTY_DATA');
      final pending = Map<String, dynamic>.from(data);
      state = LoginState(
        verificationChannel:
            pending['verification_channel']?.toString() ?? 'sms_firebase',
        googleEmail: pending['google_email']?.toString(),
      );
      return LoginNextStep.verifyCode;
    } on DioException catch (e) {
      return _failFromDio(
        e,
        countryCode: countryCode,
        phoneNumber: phoneNumber,
      );
    } catch (_) {
      return _fail(code: 'CLIENT_UNEXPECTED');
    }
  }

  Future<bool> recoverAccountFromPendingDeletion({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
  }) async {
    final step = await login(
      countryCode: countryCode,
      phoneNumber: phoneNumber,
      fullPhone: fullPhone,
      cancelPendingDeletion: true,
    );
    return step == LoginNextStep.tripRequest;
  }

  /// Fase 7 — emitir OTP para vincular teléfono a sesión autenticada.
  Future<LoginNextStep> linkPhoneChallenge({
    required String countryCode,
    required String phoneNumber,
    String? otpChannel,
  }) async {
    state = const LoginState();
    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postAuthWithRetry<Map<String, dynamic>>(
        path: AppConfig.authPhoneLinkChallengePath,
        flow: 'passenger_phone_link_challenge',
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': countryCode,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          if (otpChannel != null && otpChannel.isNotEmpty)
            'otp_channel': otpChannel,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        return _fail(
          code: body is Map<String, dynamic>
              ? (body['code']?.toString() ?? 'PASS_AUTH_ERROR')
              : 'PASS_AUTH_ERROR',
          message: body is Map<String, dynamic> ? body['message']?.toString() : null,
        );
      }
      final rawData = body['data'];
      String? channel;
      String? challengeId;
      String? waDeepLink;
      if (rawData is Map) {
        final m = Map<String, dynamic>.from(rawData);
        channel = m['verification_channel']?.toString();
        challengeId = m['challenge_id']?.toString();
        waDeepLink = m['wa_deep_link']?.toString();
      }
      state = LoginState(
        verificationChannel: channel ?? otpChannel ?? 'code',
        challengeId: challengeId,
        waDeepLink: waDeepLink,
      );
      return LoginNextStep.verifyCode;
    } on DioException catch (e) {
      return _failFromDio(e, fallbackCode: 'PASS_AUTH_ERROR');
    }
  }

  /// Fase 7 — verificar OTP y elevar sesión a full.
  Future<bool> linkPhoneVerify({
    required String countryCode,
    required String phoneNumber,
    required String verificationCode,
  }) async {
    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postAuthWithRetry<Map<String, dynamic>>(
        path: AppConfig.authPhoneLinkVerifyPath,
        flow: 'passenger_phone_link_verify',
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': countryCode,
          'phone_number': phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          'verification_code': verificationCode,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) return false;
      return body['code']?.toString() == 'PASS_AUTH_PHONE_LINKED';
    } on DioException catch (_) {
      return false;
    }
  }

  LoginNextStep _fail({
    required String code,
    String? message,
    Map<String, dynamic>? data,
  }) {
    Map<String, dynamic>? accountDeletion;
    if (data?['account_deletion'] is Map) {
      accountDeletion = Map<String, dynamic>.from(
        data!['account_deletion'] as Map,
      );
    }
    state = LoginState(
      errorMessage: message,
      errorCode: code,
      accountDeletion: accountDeletion,
    );
    return LoginNextStep.error;
  }
}
