String normalizeCurrencyCode(String? raw, {String fallback = 'BOB'}) {
  final code = raw?.trim().toUpperCase();
  if (code == null || code.isEmpty) return fallback;
  return code;
}

String formatMoney(
  double? amount, {
  String? currencyCode,
  int decimals = 2,
  String empty = '—',
}) {
  if (amount == null) return empty;
  final code = normalizeCurrencyCode(currencyCode);
  return '$code ${amount.toStringAsFixed(decimals)}';
}
