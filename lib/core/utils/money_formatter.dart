String normalizeCurrencyCode(String? raw, {String fallback = 'BOB'}) {
  final code = raw?.trim().toUpperCase();
  if (code == null || code.isEmpty) return fallback;
  return code;
}

String currencyDisplaySymbol(String code) {
  if (code == 'BOB') return 'Bs';
  return code;
}

/// Redondeo de tarifas de viaje: el único decimal válido es **0.5**.
///
/// Trabaja en céntimos para evitar errores de punto flotante.
/// - Entero exacto → se queda (12.00 → 12.0).
/// - Hasta 0.54 inclusive → .5 (12.36 → 12.5, 12.53 → 12.5).
/// - 0.55 o más → entero siguiente (12.67 → 13.0).
///
/// Misma regla que la app conductor. Créditos/Club no usan esto.
double roundTripAmount(double amount) {
  if (amount.isNaN || amount.isInfinite) return amount;
  final sign = amount < 0 ? -1.0 : 1.0;
  final cents = (amount.abs() * 100).round();
  final whole = cents ~/ 100;
  final rem = cents % 100;
  if (rem == 0) return sign * whole.toDouble();
  if (rem <= 54) return sign * (whole + 0.5);
  return sign * (whole + 1.0);
}

String formatMoney(
  double? amount, {
  String? currencyCode,
  int decimals = 2,
  String empty = '—',
}) {
  if (amount == null) return empty;
  final code = normalizeCurrencyCode(currencyCode);
  final symbol = currencyDisplaySymbol(code);
  return '$symbol ${amount.toStringAsFixed(decimals)}';
}

/// Precio de viaje (cotización, oferta, activo, “tú pagas”): 1 decimal y redondeo .0/.5.
String formatTripMoney(
  double? amount, {
  String? currencyCode,
  String empty = '—',
}) {
  if (amount == null) return empty;
  return formatMoney(
    roundTripAmount(amount),
    currencyCode: currencyCode,
    decimals: 1,
  );
}
