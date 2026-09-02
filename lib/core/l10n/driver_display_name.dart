/// Fallback cuando el backend envía username (teléfono) en lugar de un nombre.
const String driverNameFallbackDefault = 'Conductor TEXI';

final _phoneLikeName = RegExp(r'^[\d\s+\-()]+$');
final _nameWs = RegExp(r'\s+');

/// Primer nombre + primer apellido.
///
/// En LATAM el último token suele ser el apellido materno: se omite.
/// Ej.: `Juan Carlos Pérez García` → `Juan Pérez`.
String? shortPublicPersonName(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (_phoneLikeName.hasMatch(t)) return null;
  final parts = t.split(_nameWs).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return null;
  if (parts.length == 1) return parts[0];
  if (parts.length == 2) return '${parts[0]} ${parts[1]}';
  return '${parts[0]} ${parts[parts.length - 2]}';
}

/// Nombre a mostrar en ficha, chat y calificación.
/// Teléfono, vacío o ilegible → [fallback].
String displayDriverName(
  String? raw, [
  String fallback = driverNameFallbackDefault,
]) {
  final short = shortPublicPersonName(raw);
  if (short == null || short.isEmpty) return fallback;
  return short;
}

/// Nombre para la alerta de llegada: solo si hay nombre y apellido.
/// Si no, el copy debe decir «tu conductor» (aviso al pasajero)
/// o «el conductor» (estado del viaje), sin interpolar el nombre.
String? driverNameForPassengerAlert(String? raw) {
  final short = shortPublicPersonName(raw);
  if (short == null || short.isEmpty) return null;
  if (short.toLowerCase() == driverNameFallbackDefault.toLowerCase()) {
    return null;
  }
  if (short.split(_nameWs).length < 2) return null;
  return short;
}
