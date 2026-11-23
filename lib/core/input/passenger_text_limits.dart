import 'package:flutter/services.dart';

const int kPassengerEmailMaxLength = 254;

const int kPassengerDisplayNameMaxLength = 80;

String clampPassengerText(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return value.substring(0, maxLength);
}

List<TextInputFormatter> passengerEmailInputFormatters() => [
      FilteringTextInputFormatter.deny(RegExp(r'\s')),
      LengthLimitingTextInputFormatter(kPassengerEmailMaxLength),
    ];

List<TextInputFormatter> passengerDisplayNameInputFormatters() => [
      LengthLimitingTextInputFormatter(kPassengerDisplayNameMaxLength),
    ];
