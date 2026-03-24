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
  });

  final String tripId;
  final String status;
  final double? estimatedPrice;
  final String? driverName;
  final String? carColor;
  final String? carPlate;
  final String? carModel;

  factory PassengerTripSyncResponse.fromJson(Map<String, dynamic> json) {
    final tripId = json['tripId']?.toString() ?? json['id']?.toString() ?? '';
    final status = json['status']?.toString() ?? '';
    final rawPrice = json['estimatedPrice'];
    double? estimatedPrice;
    if (rawPrice is num) estimatedPrice = rawPrice.toDouble();
    if (rawPrice is String) estimatedPrice = double.tryParse(rawPrice);

    // Algunos endpoints devuelven driver/vehicle anidado o campos planos.
    final driver = json['driver'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;

    final driverName = (driver?['fullName'] ?? driver?['driverName'] ?? json['fullName'] ?? json['driverName'])?.toString();
    final carColor = (vehicle?['carColor'] ?? vehicle?['car_color'] ?? json['carColor'] ?? json['car_color'])?.toString();
    final carPlate = (vehicle?['licensePlate'] ?? vehicle?['plate'] ?? json['carPlate'] ?? json['plate'] ?? json['car_plate'])?.toString();
    final carModel = (vehicle?['carModel'] ?? vehicle?['model'] ?? json['carModel'] ?? json['car_model'])?.toString();

    return PassengerTripSyncResponse(
      tripId: tripId,
      status: status,
      estimatedPrice: estimatedPrice,
      driverName: driverName,
      carColor: carColor,
      carPlate: carPlate,
      carModel: carModel,
    );
  }
}

