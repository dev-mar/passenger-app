import 'package:flutter/services.dart';

/// Código de discado de Bolivia (sin `+`).
const String kBoliviaDialDigits = '591';

/// Largo del número local boliviano (sin código de país).
const int kBoliviaLocalPhoneLength = 8;

final _nonDigits = RegExp(r'\D');
final _boliviaLocalMobile = RegExp(r'^[567]\d{7}$');

bool isBoliviaDialCode(String? dialCode) {
  return (dialCode ?? '').replaceAll(_nonDigits, '') == kBoliviaDialDigits;
}

/// Número local BO: exactamente 8 dígitos e inicia en 5, 6 o 7.
bool isValidBoliviaLocalMobile(String raw) {
  final d = raw.replaceAll(_nonDigits, '');
  return _boliviaLocalMobile.hasMatch(d);
}

/// Validación del campo de login/vínculo: Bolivia = regla 8 dígitos 5/6/7.
bool isValidPassengerLocalPhone({
  required String dialCode,
  required String localNumber,
}) {
  if (isBoliviaDialCode(dialCode)) {
    return isValidBoliviaLocalMobile(localNumber);
  }
  final d = localNumber.replaceAll(_nonDigits, '');
  return d.length >= 6 && d.length <= 15;
}

/// Solo dígitos; en Bolivia recorta a 8 y, si pegan `591` + local, deja el local.
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
  if (!isBoliviaDialCode(dialCode)) {
    return raw.replaceAll(_nonDigits, '');
  }
  return const BoliviaLocalPhoneInputFormatter()
      .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: raw),
      )
      .text;
}

List<TextInputFormatter> passengerLocalPhoneFormatters(String dialCode) {
  final formatters = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
  ];
  if (isBoliviaDialCode(dialCode)) {
    formatters.add(const BoliviaLocalPhoneInputFormatter());
  }
  return formatters;
}

/// Número completo `+591 71234567` (sin máscara).
/// No altera el valor enviado al backend.
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
