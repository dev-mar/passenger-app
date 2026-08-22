/// Preferencias informativas del viaje. No cambian tarifa.
/// Códigos legacy `child_seat` / `over_4` se parsean pero ya no se envían.
abstract final class TripPassengerExtra {
  static const String pet = 'pet';
  static const String childSeat = 'child_seat';
  static const String wheelchair = 'wheelchair';
  static const String over4 = 'over_4';
  static const String luggage = 'luggage';
  static const String ac = 'ac';

  static const List<String> selectable = [pet, wheelchair, luggage, ac];
}

class TripPassengerExtras {
  const TripPassengerExtras({
    this.pet = false,
    this.childSeat = false,
    this.wheelchair = false,
    this.over4 = false,
    this.luggage = false,
    this.ac = false,
  });

  static const empty = TripPassengerExtras();

  final bool pet;
  final bool childSeat;
  final bool wheelchair;
  final bool over4;
  final bool luggage;
  final bool ac;

  bool get isEmpty =>
      !pet && !childSeat && !wheelchair && !over4 && !luggage && !ac;

  bool get isNotEmpty => !isEmpty;

  int get selectedCount =>
      (pet ? 1 : 0) +
      (wheelchair ? 1 : 0) +
      (luggage ? 1 : 0) +
      (ac ? 1 : 0);

  bool has(String code) {
    switch (code) {
      case TripPassengerExtra.pet:
        return pet;
      case TripPassengerExtra.childSeat:
        return childSeat;
      case TripPassengerExtra.wheelchair:
        return wheelchair;
      case TripPassengerExtra.over4:
        return over4;
      case TripPassengerExtra.luggage:
        return luggage;
      case TripPassengerExtra.ac:
        return ac;
      default:
        return false;
    }
  }

  List<String> toCodes() => [
        if (pet) TripPassengerExtra.pet,
        if (wheelchair) TripPassengerExtra.wheelchair,
        if (luggage) TripPassengerExtra.luggage,
        if (ac) TripPassengerExtra.ac,
      ];

  List<String> toDisplayCodes() => [
        if (pet) TripPassengerExtra.pet,
        if (childSeat) TripPassengerExtra.childSeat,
        if (wheelchair) TripPassengerExtra.wheelchair,
        if (over4) TripPassengerExtra.over4,
        if (luggage) TripPassengerExtra.luggage,
        if (ac) TripPassengerExtra.ac,
      ];

  TripPassengerExtras copyWith({
    bool? pet,
    bool? childSeat,
    bool? wheelchair,
    bool? over4,
    bool? luggage,
    bool? ac,
  }) {
    return TripPassengerExtras(
      pet: pet ?? this.pet,
      childSeat: childSeat ?? this.childSeat,
      wheelchair: wheelchair ?? this.wheelchair,
      over4: over4 ?? this.over4,
      luggage: luggage ?? this.luggage,
      ac: ac ?? this.ac,
    );
  }

  TripPassengerExtras prunedTo(Iterable<String> allowed) {
    final set = allowed.toSet();
    return TripPassengerExtras(
      pet: pet && set.contains(TripPassengerExtra.pet),
      wheelchair: wheelchair && set.contains(TripPassengerExtra.wheelchair),
      luggage: luggage && set.contains(TripPassengerExtra.luggage),
      ac: ac && set.contains(TripPassengerExtra.ac),
    );
  }

  TripPassengerExtras toggled(String code) {
    switch (code) {
      case TripPassengerExtra.pet:
        return copyWith(pet: !pet);
      case TripPassengerExtra.wheelchair:
        return copyWith(wheelchair: !wheelchair);
      case TripPassengerExtra.luggage:
        return copyWith(luggage: !luggage);
      case TripPassengerExtra.ac:
        return copyWith(ac: !ac);
      default:
        return this;
    }
  }

  static TripPassengerExtras fromCodes(Iterable<dynamic>? raw) {
    if (raw == null) return empty;
    var pet = false;
    var childSeat = false;
    var wheelchair = false;
    var over4 = false;
    var luggage = false;
    var ac = false;
    for (final item in raw) {
      final v = item.toString().trim().toLowerCase().replaceAll('-', '_');
      if (v == TripPassengerExtra.pet || v == 'pets') pet = true;
      if (v == TripPassengerExtra.childSeat || v == 'childseat') childSeat = true;
      if (v == TripPassengerExtra.wheelchair) wheelchair = true;
      if (v == TripPassengerExtra.over4 || v == 'over4') over4 = true;
      if (v == TripPassengerExtra.luggage || v == 'bags') luggage = true;
      if (v == TripPassengerExtra.ac || v == 'air_conditioning') ac = true;
    }
    return TripPassengerExtras(
      pet: pet,
      childSeat: childSeat,
      wheelchair: wheelchair,
      over4: over4,
      luggage: luggage,
      ac: ac,
    );
  }
}
