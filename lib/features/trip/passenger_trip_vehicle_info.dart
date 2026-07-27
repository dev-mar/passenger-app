/// Normaliza etiquetas de vehículo (ignora placeholders «—» del backend legacy/v2).
String? normalizePassengerTripVehicleLabel(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty || s == '—' || s == '-') return null;
  return s;
}

/// Resuelve modelo visible desde payload WS/REST (campos planos o anidados).
String? resolvePassengerTripCarModel(Map<String, dynamic> json) {
  final direct = normalizePassengerTripVehicleLabel(
    json['carModel']?.toString() ?? json['car_model']?.toString(),
  );
  if (direct != null) return direct;

  final vehicle = json['vehicle'];
  if (vehicle is Map) {
    final brand = normalizePassengerTripVehicleLabel(vehicle['brand']?.toString());
    final model = normalizePassengerTripVehicleLabel(
      vehicle['model']?.toString() ?? vehicle['name']?.toString(),
    );
    final parts = [brand, model].whereType<String>().toList();
    if (parts.isNotEmpty) return parts.join(' ');
  }

  final driver = json['driver'];
  if (driver is Map) {
    final brand = normalizePassengerTripVehicleLabel(driver['brand']?.toString());
    final model = normalizePassengerTripVehicleLabel(
      driver['model']?.toString() ?? driver['carModel']?.toString(),
    );
    final parts = [brand, model].whereType<String>().toList();
    if (parts.isNotEmpty) return parts.join(' ');
  }

  return null;
}

String? resolvePassengerTripCarPlate(Map<String, dynamic> json) {
  final direct = normalizePassengerTripVehicleLabel(
    json['carPlate']?.toString() ??
        json['car_plate']?.toString() ??
        json['plate']?.toString(),
  );
  if (direct != null) return direct;

  for (final key in ['vehicle', 'driver']) {
    final nested = json[key];
    if (nested is! Map) continue;
    final plate = normalizePassengerTripVehicleLabel(
      nested['licensePlate']?.toString() ??
          nested['carPlate']?.toString() ??
          nested['plate']?.toString(),
    );
    if (plate != null) return plate;
  }
  return null;
}

String? resolvePassengerTripCarColor(Map<String, dynamic> json) {
  final direct = normalizePassengerTripVehicleLabel(
    json['carColor']?.toString() ?? json['car_color']?.toString(),
  );
  if (direct != null) return direct;

  for (final key in ['vehicle', 'driver']) {
    final nested = json[key];
    if (nested is! Map) continue;
    final color = normalizePassengerTripVehicleLabel(
      nested['color']?.toString() ?? nested['carColor']?.toString(),
    );
    if (color != null) return color;
  }
  return null;
}
