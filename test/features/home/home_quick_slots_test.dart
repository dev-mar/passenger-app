import 'package:flutter_test/flutter_test.dart';
import 'package:texi_passenger_app/core/network/trips_api.dart';
import 'package:texi_passenger_app/features/home/home_quick_slots.dart';

PassengerSavedPlace _place(String label) {
  return PassengerSavedPlace(
    id: label,
    label: label,
    address: 'Calle 1',
    lat: -17.78,
    lng: -63.18,
    isFavorite: false,
  );
}

void main() {
  test('Mis favoritos oculta aeropuerto, trabajo y casa', () {
    final visible = HomeQuickSlots.favoritesOnly([
      _place('Aeropuerto'),
      _place('Trabajo'),
      _place('Casa'),
      _place('__texi_slot_work'),
      _place('Gym'),
      _place('Mamá'),
    ]);

    expect(visible.map((p) => p.label), ['Gym', 'Mamá']);
  });

  test('una calle guardada no se confunde con coordenadas', () {
    expect(
      HomeQuickSlots.savedPlaceAddressIsCoordinates(
        'Trabajo \u00B7 -17.38900, -66.15670',
      ),
      isTrue,
    );
    expect(
      HomeQuickSlots.savedPlaceStreet(
        'Av. Blanco Galindo',
        reference: 'Casa',
      ),
      'Av. Blanco Galindo',
    );
    expect(
      HomeQuickSlots.savedPlaceStreet('Casa', reference: 'Casa'),
      isNull,
    );
  });

  test('el pasajero ve el nombre y la calle; el conductor solo la calle', () {
    const street = 'Av. Capitán Víctor Ustáriz · Cercado';
    expect(
      HomeQuickSlots.savedPlacePassengerLabel(
        reference: 'Casa',
        streetOrCoords: street,
      ),
      'Casa \u00B7 $street',
    );
    expect(
      HomeQuickSlots.savedPlaceDriverAddress(
        street: street,
        lat: -17.38,
        lng: -66.15,
      ),
      street,
    );
    expect(
      HomeQuickSlots.savedPlaceDriverAddress(
        street: null,
        lat: -17.38,
        lng: -66.15,
      ),
      '-17.380000, -66.150000',
    );
  });
}
