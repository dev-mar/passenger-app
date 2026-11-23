String normalizeCurrencyCode(String? raw, {String fallback = 'BOB'}) {
  final code = raw?.trim().toUpperCase();
  if (code == null || code.isEmpty) return fallback;
  return code;
}

String currencyDisplaySymbol(String code) {
  if (code == 'BOB') return 'Bs';
  return code;
}

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
