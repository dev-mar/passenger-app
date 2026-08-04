/// Formato de cuenta regresiva según tier de bloqueo.
/// Tier 1: solo segundos (ej. 120).
/// Tier 2: minutos:segundos (ej. 10:00).
/// Tier 3+: horas:minutos:segundos (ej. 2:00:00).
class PassengerAuthLockoutTimeFormatter {
  PassengerAuthLockoutTimeFormatter._();

  static String format({required int remainingSec, required int lockTier}) {
    final total = remainingSec < 0 ? 0 : remainingSec;
    if (lockTier <= 1) {
      return '$total';
    }
    if (lockTier == 2) {
      final minutes = total ~/ 60;
      final seconds = total % 60;
      return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
    }
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    return '${hours.toString()}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String unitHint({required int lockTier, required String secondsLabel}) {
    if (lockTier <= 1) return secondsLabel;
    return '';
  }
}
