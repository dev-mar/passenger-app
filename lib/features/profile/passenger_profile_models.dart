enum PassengerProfileLoadError { noSession, empty, badFormat }

/// Error con código de negocio del backend (`code` en JSON).
class PassengerProfileApiException implements Exception {
  PassengerProfileApiException(this.apiCode, this.message);

  final String? apiCode;
  final String message;

  @override
  String toString() => message;
}

class PassengerProfileVm {
  const PassengerProfileVm({
    required this.displayName,
    required this.phone,
    this.email,
    required this.hasProfilePhoto,
    this.profilePhotoUrl,
    required this.isVerified,
    this.accountStatus,
    required this.biometricsEnabled,
    this.lastAccessAt,
  });

  final String displayName;
  final String phone;
  final String? email;
  final bool hasProfilePhoto;
  final String? profilePhotoUrl;
  final bool isVerified;
  final String? accountStatus;
  final bool biometricsEnabled;
  final DateTime? lastAccessAt;

  factory PassengerProfileVm.fromJson(Map<String, dynamic> j) {
    return PassengerProfileVm(
      displayName: j['display_name']?.toString().trim() ?? '',
      phone: j['phone_number']?.toString().trim() ?? '',
      email: () {
        final e = j['email']?.toString().trim();
        if (e == null || e.isEmpty) return null;
        return e;
      }(),
      hasProfilePhoto: j['has_profile_photo'] == true,
      profilePhotoUrl: () {
        final u = j['profile_picture_url']?.toString().trim();
        if (u == null || u.isEmpty) return null;
        return u;
      }(),
      isVerified: j['is_verified'] == true,
      accountStatus: j['account_status']?.toString().trim(),
      biometricsEnabled: j['biometrics_enabled'] == true,
      lastAccessAt: () {
        final raw = j['last_access_at']?.toString().trim();
        if (raw == null || raw.isEmpty) return null;
        return DateTime.tryParse(raw)?.toLocal();
      }(),
    );
  }
}
