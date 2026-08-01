/// Bandera emoji y metadatos mínimos por código de marcación.
class LoginCountryDial {
  const LoginCountryDial({
    required this.dialCode,
    required this.isoCode,
    required this.label,
  });

  final String dialCode;
  final String isoCode;
  final String label;
}

/// Bolivia por defecto (mercado principal Texi).
const LoginCountryDial kDefaultLoginCountry = LoginCountryDial(
  dialCode: '+591',
  isoCode: 'BO',
  label: 'Bolivia',
);

String loginCountryFlagEmoji(String isoCode) {
  final upper = isoCode.trim().toUpperCase();
  if (upper.length != 2) return '';
  return String.fromCharCodes(
    upper.codeUnits.map((unit) => unit + 0x1F1A5),
  );
}

LoginCountryDial loginCountryFromDialCode(String dialCode) {
  final normalized = dialCode.trim().startsWith('+')
      ? dialCode.trim()
      : '+${dialCode.trim()}';
  for (final entry in _dialCatalog) {
    if (entry.dialCode == normalized) return entry;
  }
  return kDefaultLoginCountry;
}

const List<LoginCountryDial> _dialCatalog = [
  kDefaultLoginCountry,
  LoginCountryDial(dialCode: '+54', isoCode: 'AR', label: 'Argentina'),
  LoginCountryDial(dialCode: '+55', isoCode: 'BR', label: 'Brasil'),
  LoginCountryDial(dialCode: '+56', isoCode: 'CL', label: 'Chile'),
  LoginCountryDial(dialCode: '+51', isoCode: 'PE', label: 'Perú'),
  LoginCountryDial(dialCode: '+1', isoCode: 'US', label: 'Estados Unidos'),
];
