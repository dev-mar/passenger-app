import '../../core/utils/service_type_display.dart';
import 'trip_passenger_extras.dart';
import 'trip_passenger_specials.dart';

enum TripPassengerServiceFamily {
  economy,
  comfort,
  exclusive,
  motorbike,
  other,
}

TripPassengerServiceFamily passengerServiceFamily({
  int? serviceTypeId,
  String? serviceTypeName,
}) {
  final id = serviceTypeId ?? 0;
  if (id == 1) return TripPassengerServiceFamily.economy;
  if (id == 2) return TripPassengerServiceFamily.comfort;
  if (id == 3) return TripPassengerServiceFamily.exclusive;
  if (id == 4) return TripPassengerServiceFamily.motorbike;
  final key = serviceTypeIconKey(
    serviceTypeName ?? '',
    serviceTypeId: serviceTypeId,
  );
  switch (key) {
    case 'two_wheeler':
      return TripPassengerServiceFamily.motorbike;
    case 'premium':
      return TripPassengerServiceFamily.exclusive;
    case 'comfort':
      return TripPassengerServiceFamily.comfort;
    case 'standard':
      return TripPassengerServiceFamily.economy;
    default:
      return TripPassengerServiceFamily.other;
  }
}

List<String> allowedExtrasForFamily(TripPassengerServiceFamily family) {
  switch (family) {
    case TripPassengerServiceFamily.economy:
      return const [
        TripPassengerExtra.pet,
        TripPassengerExtra.wheelchair,
        TripPassengerExtra.luggage,
      ];
    case TripPassengerServiceFamily.comfort:
      return const [
        TripPassengerExtra.pet,
        TripPassengerExtra.wheelchair,
        TripPassengerExtra.luggage,
        TripPassengerExtra.ac,
      ];
    case TripPassengerServiceFamily.exclusive:
    case TripPassengerServiceFamily.motorbike:
    case TripPassengerServiceFamily.other:
      return const [];
  }
}

List<String> allowedSpecialsForFamily(TripPassengerServiceFamily family) {
  switch (family) {
    case TripPassengerServiceFamily.economy:
    case TripPassengerServiceFamily.comfort:
      return List<String>.from(TripPassengerSpecial.all);
    case TripPassengerServiceFamily.exclusive:
    case TripPassengerServiceFamily.motorbike:
    case TripPassengerServiceFamily.other:
      return const [];
  }
}

/// Precio a mostrar en cotización: aplica recargo solo en Estándar/Confort.
double displayQuotedPriceForOption({
  required double basePrice,
  required int? serviceTypeId,
  required String? serviceTypeName,
  required int specialsCount,
  required double surchargePct,
}) {
  final family = passengerServiceFamily(
    serviceTypeId: serviceTypeId,
    serviceTypeName: serviceTypeName,
  );
  if (allowedSpecialsForFamily(family).isEmpty || specialsCount <= 0) {
    return basePrice;
  }
  return applySpecialsSurcharge(
    basePrice: basePrice,
    specialsCount: specialsCount,
    surchargePct: surchargePct,
  );
}
