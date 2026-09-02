import 'package:flutter/services.dart';

/// Máximo RFC 5321 para una dirección de correo.
const int kPassengerEmailMaxLength = 254;

/// Nombre visible (un solo campo): suficiente para nombre y apellido.
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
