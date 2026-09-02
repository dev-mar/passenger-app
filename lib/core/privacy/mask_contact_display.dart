import '../phone/bolivia_local_phone.dart';

/// Teléfono para copy de OTP: `+591 ***4567`.
/// Deja el código de país y los últimos dígitos; el resto va en `***`.
String maskPassengerPhoneDisplay({
  required String dialCode,
  required String localNumber,
}) {
  final parts = passengerPhoneDisplayParts(
    dialCode: dialCode,
    localNumber: localNumber,
  );
  if (parts.local.isEmpty) return parts.cc;
  final keep = parts.local.length >= 6
      ? 4
      : (parts.local.length > 2 ? 2 : parts.local.length);
  final tail = parts.local.substring(parts.local.length - keep);
  final maskedLocal = '***$tail';
  if (parts.cc.isEmpty) return maskedLocal;
  return '${parts.cc} $maskedLocal';
}

/// Correo para copy de OTP: `ju***ez@gmail.com`.
/// Deja primeras y últimas letras del local; el dominio queda visible.
String maskPassengerEmailDisplay(String email) {
  final trimmed = email.trim();
  final at = trimmed.lastIndexOf('@');
  if (at <= 0 || at == trimmed.length - 1) return trimmed;
  final local = trimmed.substring(0, at);
  final domain = trimmed.substring(at + 1);
  if (local.isEmpty) return trimmed;

  final String maskedLocal;
  if (local.length == 1) {
    maskedLocal = '$local***';
  } else if (local.length < 5) {
    maskedLocal = '${local[0]}***${local[local.length - 1]}';
  } else {
    maskedLocal =
        '${local.substring(0, 2)}***${local.substring(local.length - 2)}';
  }
  return '$maskedLocal@$domain';
}
