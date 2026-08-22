/// Preferencia informativa de pago del viaje (`cash` | `qr`).
/// No es pasarela: el cobro ocurre fuera de Texi. Ausente = efectivo.
abstract final class TripPaymentMethod {
  static const String cash = 'cash';
  static const String qr = 'qr';

  static String normalize(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return v == qr ? qr : cash;
  }

  static bool isQr(String? raw) => normalize(raw) == qr;
}
