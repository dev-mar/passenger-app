import '../../features/trip/passenger_trip_vehicle_info.dart';

/// Respuesta de sincronización del estado de un trip para pasajero.
///
/// La estructura real puede variar, por eso el parsing es defensivo.
class PassengerTripSyncResponse {
  const PassengerTripSyncResponse({
    required this.tripId,
    required this.status,
    this.estimatedPrice,
    this.driverName,
    this.carColor,
    this.carPlate,
    this.carModel,
    this.currencyCode,
  });

  final String tripId;
  final String status;
  final double? estimatedPrice;
  final String? driverName;
  final String? carColor;
  final String? carPlate;
  final String? carModel;
  final String? currencyCode;

  factory PassengerTripSyncResponse.fromJson(Map<String, dynamic> json) {
    final tripId = json['tripId']?.toString() ?? json['id']?.toString() ?? '';
    final status = json['status']?.toString() ?? '';
    double? readPrice(dynamic raw) {
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw);
      return null;
    }

    final agreedPrice = readPrice(json['agreedPrice'] ?? json['agreed_price']);
    final estimatedPrice =
        agreedPrice ?? readPrice(json['estimatedPrice'] ?? json['estimated_price']);

    // Algunos endpoints devuelven driver/vehicle anidado o campos planos.
    final driver = json['driver'] as Map<String, dynamic>?;

    final driverName = (driver?['fullName'] ?? driver?['driverName'] ?? json['fullName'] ?? json['driverName'])?.toString();
    final carColor = resolvePassengerTripCarColor(json);
    final carPlate = resolvePassengerTripCarPlate(json);
    final carModel = resolvePassengerTripCarModel(json);

    return PassengerTripSyncResponse(
      tripId: tripId,
      status: status,
      estimatedPrice: estimatedPrice,
      driverName: driverName,
      carColor: carColor,
      carPlate: carPlate,
      carModel: carModel,
      currencyCode: (json['currencyCode'] ?? json['currency'])?.toString(),
    );
  }
}

