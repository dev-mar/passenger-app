/// Credenciales documentadas para revisión Google Play (anti-bloqueo en cliente).
/// Deben coincidir con `passenger-play-review-allowlist.service.js` en backend.
class PassengerPlayReviewCredentials {
  PassengerPlayReviewCredentials._();

  static const String email = 'pasajero@taxitexi.com';

  static const Set<String> _phoneE164 = {
    '+59170000005',
    '+59170000007',
  };

  static const Set<String> _otpCodes = {
    '123321',
    '012210',
  };

  static String? normalizePhoneE164({
    required String countryCode,
    required String phoneNumber,
  }) {
    final cc = countryCode.trim().startsWith('+')
        ? countryCode.trim()
        : '+${countryCode.trim()}';
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return '$cc$digits';
  }

  static bool isAllowlistedPhone({
    required String countryCode,
    required String phoneNumber,
  }) {
    final e164 = normalizePhoneE164(
      countryCode: countryCode,
      phoneNumber: phoneNumber,
    );
    return e164 != null && _phoneE164.contains(e164);
  }

  static bool isAllowlistedPhoneE164(String? phoneE164) {
    final raw = phoneE164?.trim();
    if (raw == null || raw.isEmpty) return false;
    return _phoneE164.contains(raw);
  }

  static bool isAllowlistedEmail(String? rawEmail) {
    final normalized = rawEmail?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return normalized == email;
  }

  static bool isAllowlistedOtp(String? code) {
    final normalized = code?.trim();
    if (normalized == null || normalized.isEmpty) return false;
    return _otpCodes.contains(normalized);
  }

  static bool shouldBypassClientLockout({
    String? countryCode,
    String? phoneNumber,
    String? email,
  }) {
    if (countryCode != null &&
        phoneNumber != null &&
        isAllowlistedPhone(
          countryCode: countryCode,
          phoneNumber: phoneNumber,
        )) {
      return true;
    }
    if (email != null && isAllowlistedEmail(email)) return true;
    return false;
  }
}
