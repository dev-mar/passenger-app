import 'package:flutter/services.dart';

import 'passenger_phone_countries.dart';

const String kBoliviaDialDigits = '591';

const int kBoliviaLocalPhoneLength = 8;

final _nonDigits = RegExp(r'\D');
final _boliviaLocalMobile = RegExp(r'^[567]\d{7}$');

bool isBoliviaDialCode(String? dialCode) {
  return (dialCode ?? '').replaceAll(_nonDigits, '') == kBoliviaDialDigits;
}

bool isValidBoliviaLocalMobile(String raw) {
  final d = raw.replaceAll(_nonDigits, '');
  return _boliviaLocalMobile.hasMatch(d);
}

bool isValidPassengerLocalPhone({
  required String dialCode,
  required String localNumber,
}) {
  final country = loginCountryExact(dialCode);
  if (country == null) {
    final d = localNumber.replaceAll(_nonDigits, '');
    return d.length >= 6 && d.length <= 15;
  }
  if (isBoliviaDialCode(country.dialCode)) {
    return isValidBoliviaLocalMobile(localNumber);
  }
  final d = localNumber.replaceAll(_nonDigits, '');
  if (d.length < country.minLocalDigits || d.length > country.maxLocalDigits) {
    return false;
  }
  final pattern = country.localPattern;
  if (pattern != null && !pattern.hasMatch(d)) return false;
  return true;
}

class BoliviaLocalPhoneInputFormatter extends TextInputFormatter {
  const BoliviaLocalPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = newValue.text.replaceAll(_nonDigits, '');
    if (d.startsWith(kBoliviaDialDigits) && d.length > kBoliviaLocalPhoneLength) {
      d = d.substring(kBoliviaDialDigits.length);
    }
    if (d.isNotEmpty && !RegExp(r'^[567]').hasMatch(d)) {
      d = '';
    }
    if (d.length > kBoliviaLocalPhoneLength) {
      d = d.substring(0, kBoliviaLocalPhoneLength);
    }
    return TextEditingValue(
      text: d,
      selection: TextSelection.collapsed(offset: d.length),
    );
  }
}

String sanitizePassengerLocalPhone({
  required String dialCode,
  required String raw,
}) {
  return PassengerLocalPhoneInputFormatter(dialCode)
      .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: raw),
      )
      .text;
}

List<TextInputFormatter> passengerLocalPhoneFormatters(String dialCode) {
  return <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    PassengerLocalPhoneInputFormatter(dialCode),
  ];
}

class PassengerLocalPhoneInputFormatter extends TextInputFormatter {
  const PassengerLocalPhoneInputFormatter(this.dialCode);

  final String dialCode;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (isBoliviaDialCode(dialCode)) {
      return const BoliviaLocalPhoneInputFormatter()
          .formatEditUpdate(oldValue, newValue);
    }
    final country = loginCountryExact(dialCode);
    final maxDigits = country?.maxLocalDigits ?? 15;
    var d = newValue.text.replaceAll(_nonDigits, '');
    final cc = country?.dialDigits ?? '';
    if (cc.isNotEmpty && d.startsWith(cc)) {
      final rest = d.substring(cc.length);
      final within = country != null &&
          rest.length >= country.minLocalDigits &&
          rest.length <= country.maxLocalDigits;
      if (within || d.length > maxDigits) d = rest;
    }
    if (country?.stripTrunkZero == true && d.startsWith('0')) {
      d = d.substring(1);
    }
    if (d.length > maxDigits) d = d.substring(0, maxDigits);
    return TextEditingValue(
      text: d,
      selection: TextSelection.collapsed(offset: d.length),
    );
  }
}

String formatPassengerPhoneDisplay({
  required String dialCode,
  required String localNumber,
}) {
  final parts = passengerPhoneDisplayParts(
    dialCode: dialCode,
    localNumber: localNumber,
  );
  if (parts.local.isEmpty) return parts.cc;
  if (parts.cc.isEmpty) return parts.local;
  return '${parts.cc} ${parts.local}';
}

({String cc, String local}) passengerPhoneDisplayParts({
  required String dialCode,
  required String localNumber,
}) {
  final rawCc = dialCode.trim();
  final cc = rawCc.isEmpty
      ? ''
      : (rawCc.startsWith('+') ? rawCc : '+$rawCc');
  var local = localNumber.replaceAll(_nonDigits, '');
  final ccDigits = cc.replaceAll(_nonDigits, '');
  if (ccDigits.isNotEmpty &&
      local.startsWith(ccDigits) &&
      local.length > ccDigits.length) {
    local = local.substring(ccDigits.length);
  }
  return (cc: cc, local: local);
}
