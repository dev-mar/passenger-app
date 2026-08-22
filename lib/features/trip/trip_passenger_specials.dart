/// Requerimientos especiales. Cada ítem marcado aplica recargo % sobre el precio base de quote.
abstract final class TripPassengerSpecial {
  static const String seats6 = 'seats_6';
  static const String roofRack = 'roof_rack';
  static const String cargo = 'cargo';

  static const List<String> all = [seats6, roofRack, cargo];
}

class TripPassengerSpecials {
  const TripPassengerSpecials({
    this.seats6 = false,
    this.roofRack = false,
    this.cargo = false,
  });

  static const empty = TripPassengerSpecials();

  final bool seats6;
  final bool roofRack;
  final bool cargo;

  bool get isEmpty => !seats6 && !roofRack && !cargo;

  bool get isNotEmpty => !isEmpty;

  int get selectedCount =>
      (seats6 ? 1 : 0) + (roofRack ? 1 : 0) + (cargo ? 1 : 0);

  bool has(String code) {
    switch (code) {
      case TripPassengerSpecial.seats6:
        return seats6;
      case TripPassengerSpecial.roofRack:
        return roofRack;
      case TripPassengerSpecial.cargo:
        return cargo;
      default:
        return false;
    }
  }

  List<String> toCodes() => [
        if (seats6) TripPassengerSpecial.seats6,
        if (roofRack) TripPassengerSpecial.roofRack,
        if (cargo) TripPassengerSpecial.cargo,
      ];

  TripPassengerSpecials copyWith({
    bool? seats6,
    bool? roofRack,
    bool? cargo,
  }) {
    return TripPassengerSpecials(
      seats6: seats6 ?? this.seats6,
      roofRack: roofRack ?? this.roofRack,
      cargo: cargo ?? this.cargo,
    );
  }

  TripPassengerSpecials prunedTo(Iterable<String> allowed) {
    final set = allowed.toSet();
    return TripPassengerSpecials(
      seats6: seats6 && set.contains(TripPassengerSpecial.seats6),
      roofRack: roofRack && set.contains(TripPassengerSpecial.roofRack),
      cargo: cargo && set.contains(TripPassengerSpecial.cargo),
    );
  }

  TripPassengerSpecials toggled(String code) {
    switch (code) {
      case TripPassengerSpecial.seats6:
        return copyWith(seats6: !seats6);
      case TripPassengerSpecial.roofRack:
        return copyWith(roofRack: !roofRack);
      case TripPassengerSpecial.cargo:
        return copyWith(cargo: !cargo);
      default:
        return this;
    }
  }

  static TripPassengerSpecials fromCodes(Iterable<dynamic>? raw) {
    if (raw == null) return empty;
    var seats6 = false;
    var roofRack = false;
    var cargo = false;
    for (final item in raw) {
      final v = item.toString().trim().toLowerCase().replaceAll('-', '_');
      if (v == TripPassengerSpecial.seats6 || v == 'seats6') seats6 = true;
      if (v == TripPassengerSpecial.roofRack || v == 'roofrack') roofRack = true;
      if (v == TripPassengerSpecial.cargo) cargo = true;
    }
    return TripPassengerSpecials(
      seats6: seats6,
      roofRack: roofRack,
      cargo: cargo,
    );
  }
}

double applySpecialsSurcharge({
  required double basePrice,
  required int specialsCount,
  required double surchargePct,
}) {
  if (specialsCount <= 0) return basePrice;
  return (basePrice * (1 + (surchargePct / 100.0) * specialsCount) * 100)
          .round() /
      100.0;
}
