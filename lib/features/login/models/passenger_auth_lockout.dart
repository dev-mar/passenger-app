import '../../../core/network/passenger_http_resilience.dart';

/// Bloqueo temporal de auth pasajero (fuente de verdad: backend 429).
class PassengerAuthLockout {
  const PassengerAuthLockout({
    required this.retryAfterSec,
    required this.lockTier,
    required this.lockScope,
    required this.expiresAtEpochSec,
    this.alternateChannels = const [],
    this.countryCode,
    this.phoneNumber,
    this.errorCode,
    this.message,
  });

  final int retryAfterSec;
  final int lockTier;
  final String lockScope;
  final int expiresAtEpochSec;
  final List<String> alternateChannels;
  final String? countryCode;
  final String? phoneNumber;
  final String? errorCode;
  final String? message;

  int get remainingSec {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final left = expiresAtEpochSec - now;
    return left > 0 ? left : 0;
  }

  bool get isActive => remainingSec > 0;

  bool get canTryWhatsAppInbound =>
      lockScope == 'verify' &&
      alternateChannels.contains('whatsapp_inbound');

  static const Set<String> lockoutCodes = {
    'PASS_AUTH_LOCKOUT',
    'PASS_AUTH_RATE_LIMIT',
    'PASS_AUTH_OTP_RATE_LIMIT',
    'PASS_AUTH_OTP_ISSUE_LOCKED',
    'PASS_AUTH_OTP_VERIFY_LOCKED',
    'PASS_AUTH_SMS_RATE_LIMIT',
    'PASS_AUTH_WA_OUTBOUND_RATE_LIMIT',
    'PASS_AUTH_STEP_UP_REQUIRED',
  };

  static bool isLockoutCode(String? code) {
    if (code == null || code.isEmpty) return false;
    return lockoutCodes.contains(code);
  }

  static Map<String, dynamic>? _payloadFromResponse(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    if (map['error'] is Map) {
      return Map<String, dynamic>.from(map['error'] as Map);
    }
    if (map.containsKey('retry_after_sec') ||
        map.containsKey('lock_tier') ||
        map.containsKey('lock_scope')) {
      return map;
    }
    return null;
  }

  static int _tierDurationDefault(int tier) {
    switch (tier) {
      case 1:
        return 120;
      case 2:
        return 600;
      default:
        return 7200;
    }
  }

  static PassengerAuthLockout? tryParse({
    required String? code,
    dynamic responseData,
    String? countryCode,
    String? phoneNumber,
    String? message,
  }) {
    if (!isLockoutCode(code)) return null;

    final payload = _payloadFromResponse(responseData);
    final retryMs = payload != null
        ? retryAfterMsFromResponse(payload, null)
        : retryAfterMsFromResponse(responseData, null);

    var retryAfterSec = retryMs != null ? (retryMs / 1000).ceil() : 0;
    if (payload != null) {
      final secRaw = payload['retry_after_sec'];
      if (secRaw is num && secRaw > 0) {
        retryAfterSec = secRaw.ceil();
      }
    }

    var lockTier = 1;
    if (payload?['lock_tier'] is num) {
      lockTier = (payload!['lock_tier'] as num).toInt().clamp(1, 3);
    } else if (code == 'PASS_AUTH_RATE_LIMIT' ||
        code == 'PASS_AUTH_STEP_UP_REQUIRED') {
      lockTier = 2;
    }

    if (retryAfterSec <= 0) {
      retryAfterSec = _tierDurationDefault(lockTier);
    }

    final lockScope = payload?['lock_scope']?.toString().trim().isNotEmpty == true
        ? payload!['lock_scope'].toString()
        : _scopeFromCode(code);

    final channelsRaw = payload?['alternate_channels'];
    final alternateChannels = <String>[];
    if (channelsRaw is List) {
      for (final item in channelsRaw) {
        final s = item?.toString().trim();
        if (s != null && s.isNotEmpty) alternateChannels.add(s);
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return PassengerAuthLockout(
      retryAfterSec: retryAfterSec,
      lockTier: lockTier,
      lockScope: lockScope,
      expiresAtEpochSec: now + retryAfterSec,
      alternateChannels: alternateChannels,
      countryCode: countryCode,
      phoneNumber: phoneNumber,
      errorCode: code,
      message: message,
    );
  }

  static String _scopeFromCode(String? code) {
    switch (code) {
      case 'PASS_AUTH_OTP_RATE_LIMIT':
      case 'PASS_AUTH_OTP_VERIFY_LOCKED':
        return 'verify';
      case 'PASS_AUTH_OTP_ISSUE_LOCKED':
      case 'PASS_AUTH_SMS_RATE_LIMIT':
      case 'PASS_AUTH_WA_OUTBOUND_RATE_LIMIT':
        return 'issue';
      case 'PASS_AUTH_RATE_LIMIT':
      case 'PASS_AUTH_STEP_UP_REQUIRED':
        return 'login';
      default:
        return 'issue';
    }
  }

  Map<String, dynamic> toJson() => {
        'retry_after_sec': retryAfterSec,
        'lock_tier': lockTier,
        'lock_scope': lockScope,
        'expires_at_epoch_sec': expiresAtEpochSec,
        'alternate_channels': alternateChannels,
        if (countryCode != null) 'country_code': countryCode,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (errorCode != null) 'error_code': errorCode,
        if (message != null) 'message': message,
      };

  factory PassengerAuthLockout.fromJson(Map<String, dynamic> json) {
    final expiresAt = json['expires_at_epoch_sec'];
    final retryRaw = json['retry_after_sec'];
    final tierRaw = json['lock_tier'];
    final channelsRaw = json['alternate_channels'];
    final alternateChannels = <String>[];
    if (channelsRaw is List) {
      for (final item in channelsRaw) {
        final s = item?.toString().trim();
        if (s != null && s.isNotEmpty) alternateChannels.add(s);
      }
    }
    return PassengerAuthLockout(
      retryAfterSec: retryRaw is num ? retryRaw.toInt() : 120,
      lockTier: tierRaw is num ? tierRaw.toInt().clamp(1, 3) : 1,
      lockScope: json['lock_scope']?.toString() ?? 'issue',
      expiresAtEpochSec: expiresAt is num
          ? expiresAt.toInt()
          : DateTime.now().millisecondsSinceEpoch ~/ 1000,
      alternateChannels: alternateChannels,
      countryCode: json['country_code']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      errorCode: json['error_code']?.toString(),
      message: json['message']?.toString(),
    );
  }
}
