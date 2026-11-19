/// País seleccionable en el login del pasajero y regla del número local.
class LoginCountryDial {
  const LoginCountryDial({
    required this.dialCode,
    required this.isoCode,
    required this.label,
    required this.minLocalDigits,
    required this.maxLocalDigits,
    required this.example,
    this.localPattern,
    this.stripTrunkZero = false,
  });

  final String dialCode;
  final String isoCode;
  final String label;
  final int minLocalDigits;
  final int maxLocalDigits;
  final String example;
  final RegExp? localPattern;
  /// Quita un 0 inicial (prefijo de larga distancia) al pegar el número.
  final bool stripTrunkZero;

  String get dialDigits => dialCode.replaceAll(_nonDigits, '');
}

final _nonDigits = RegExp(r'\D');

final _boliviaLocal = RegExp(r'^[567]\d{7}$');
final _usLocal = RegExp(r'^[2-9]\d{2}[2-9]\d{6}$');
final _colombiaMobile = RegExp(r'^3\d{9}$');
final _panamaMobile = RegExp(r'^6\d{7}$');

/// Bolivia queda marcada al abrir. La tienda no elige este prefijo.
final LoginCountryDial kDefaultLoginCountry = LoginCountryDial(
  dialCode: '+591',
  isoCode: 'BO',
  label: 'Bolivia',
  minLocalDigits: 8,
  maxLocalDigits: 8,
  example: '70000000',
  localPattern: _boliviaLocal,
);

/// Prueba inicial: Bolivia y los países de origen de turistas.
final List<LoginCountryDial> kLoginCountryChoices = [
  kDefaultLoginCountry,
  LoginCountryDial(
    dialCode: '+1',
    isoCode: 'US',
    label: 'Estados Unidos',
    minLocalDigits: 10,
    maxLocalDigits: 10,
    example: '2025550123',
    localPattern: _usLocal,
  ),
  LoginCountryDial(
    dialCode: '+55',
    isoCode: 'BR',
    label: 'Brasil',
    minLocalDigits: 10,
    maxLocalDigits: 11,
    example: '11987654321',
    stripTrunkZero: true,
  ),
  LoginCountryDial(
    dialCode: '+57',
    isoCode: 'CO',
    label: 'Colombia',
    minLocalDigits: 10,
    maxLocalDigits: 10,
    example: '3001234567',
    localPattern: _colombiaMobile,
    stripTrunkZero: true,
  ),
  LoginCountryDial(
    dialCode: '+507',
    isoCode: 'PA',
    label: 'Panamá',
    minLocalDigits: 8,
    maxLocalDigits: 8,
    example: '61234567',
    localPattern: _panamaMobile,
  ),
  LoginCountryDial(
    dialCode: '+49',
    isoCode: 'DE',
    label: 'Alemania',
    minLocalDigits: 10,
    maxLocalDigits: 13,
    example: '15123456789',
    stripTrunkZero: true,
  ),
];

String loginCountryFlagEmoji(String isoCode) {
  final upper = isoCode.trim().toUpperCase();
  if (upper.length != 2) return '';
  return String.fromCharCodes(
    upper.codeUnits.map((unit) => unit + 0x1F1A5),
  );
}

String _normalizeDial(String dialCode) {
  final trimmed = dialCode.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.startsWith('+') ? trimmed : '+$trimmed';
}

/// País del catálogo, o null si el prefijo no está en la prueba.
LoginCountryDial? loginCountryExact(String dialCode) {
  final normalized = _normalizeDial(dialCode);
  for (final entry in kLoginCountryChoices) {
    if (entry.dialCode == normalized) return entry;
  }
  return null;
}

/// Si el prefijo no está en la lista, la pantalla sigue mostrando Bolivia.
LoginCountryDial loginCountryFromDialCode(String dialCode) {
  return loginCountryExact(dialCode) ?? kDefaultLoginCountry;
}

/// Prefijo más largo que encabeza un E.164 solo con dígitos (`59170000000`).
LoginCountryDial? loginCountryMatchingDigits(String digits) {
  final d = digits.replaceAll(_nonDigits, '');
  LoginCountryDial? best;
  for (final entry in kLoginCountryChoices) {
    final code = entry.dialDigits;
    if (code.isEmpty || !d.startsWith(code)) continue;
    if (best == null || code.length > best.dialDigits.length) best = entry;
  }
  return best;
}
