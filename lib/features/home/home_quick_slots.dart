import '../../core/network/trips_api.dart';
import '../../gen_l10n/app_localizations.dart';

enum HomeQuickSlotKind { airport, work, home, favorite }

class HomeQuickPlaceResult {
  const HomeQuickPlaceResult({
    required this.lat,
    required this.lng,
    this.address,
  });

  final double lat;
  final double lng;

  /// Calle o dirección leída al guardar. Casa y trabajo pueden omitirla.
  final String? address;
}

/// Empareja slots de viajes rápidos con `operations.passenger_saved_places`.
abstract final class HomeQuickSlots {
  static const canonicalWork = '__texi_slot_work';
  static const canonicalHome = '__texi_slot_home';
  static const canonicalFavorite = '__texi_slot_favorite';

  static const workAliases = <String>{
    canonicalWork,
    'trabajo',
    'work',
    'oficina',
    'office',
    'ir al trabajo',
    'go to work',
    'al trabajo',
  };

  static const homeAliases = <String>{
    canonicalHome,
    'casa',
    'home',
    'hogar',
    'ir a casa',
    'go home',
    'mi casa',
  };

  static const favoriteAliases = <String>{
    canonicalFavorite,
    'favorito',
    'favorite',
    'mi favorito',
    'my favorite',
    'favorita',
  };

  static bool isConfigurable(HomeQuickSlotKind kind) =>
      kind != HomeQuickSlotKind.airport;

  /// Casa, trabajo y aeropuerto tienen su propia tarjeta. No van en Mis favoritos.
  static bool isPrincipalSavedLabel(String label, {AppLocalizations? l10n}) {
    final key = label.trim().toLowerCase();
    if (key.isEmpty) return false;
    final hidden = <String>{
      ...workAliases,
      ...homeAliases,
      'aeropuerto',
      'airport',
      'ir al aeropuerto',
      'go to the airport',
    };
    if (l10n != null) {
      hidden
        ..add(storageLabel(HomeQuickSlotKind.work, l10n).trim().toLowerCase())
        ..add(
          displayLabel(
            kind: HomeQuickSlotKind.work,
            l10n: l10n,
          ).trim().toLowerCase(),
        )
        ..add(storageLabel(HomeQuickSlotKind.home, l10n).trim().toLowerCase())
        ..add(
          displayLabel(
            kind: HomeQuickSlotKind.home,
            l10n: l10n,
          ).trim().toLowerCase(),
        )
        ..add(l10n.homeAirportCta.trim().toLowerCase());
    }
    return hidden.contains(key);
  }

  static List<PassengerSavedPlace> favoritesOnly(
    List<PassengerSavedPlace> saved, {
    AppLocalizations? l10n,
  }) {
    return saved
        .where((place) => !isPrincipalSavedLabel(place.label, l10n: l10n))
        .toList(growable: false);
  }

  static Set<String> aliasesFor(HomeQuickSlotKind kind) {
    switch (kind) {
      case HomeQuickSlotKind.airport:
        return const {};
      case HomeQuickSlotKind.work:
        return workAliases;
      case HomeQuickSlotKind.home:
        return homeAliases;
      case HomeQuickSlotKind.favorite:
        return favoriteAliases;
    }
  }

  static String storageLabel(HomeQuickSlotKind kind, AppLocalizations l10n) {
    switch (kind) {
      case HomeQuickSlotKind.airport:
        return l10n.homeAirportCta;
      case HomeQuickSlotKind.work:
        return l10n.homeSlotWorkLabel;
      case HomeQuickSlotKind.home:
        return l10n.homeSlotHomeLabel;
      case HomeQuickSlotKind.favorite:
        return l10n.homeSlotFavoriteLabel;
    }
  }

  static String storageAddress({
    required HomeQuickSlotKind kind,
    required AppLocalizations l10n,
    required double lat,
    required double lng,
  }) {
    final title = storageLabel(kind, l10n);
    final coords = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    final raw = '$title · $coords';
    if (raw.length <= 180) return raw;
    return coords;
  }

  static String displayLabel({
    required HomeQuickSlotKind kind,
    required AppLocalizations l10n,
  }) {
    switch (kind) {
      case HomeQuickSlotKind.airport:
        return l10n.homeAirportCta;
      case HomeQuickSlotKind.work:
        return l10n.homeWorkCta;
      case HomeQuickSlotKind.home:
        return l10n.homeHomeCta;
      case HomeQuickSlotKind.favorite:
        return l10n.homeFavoriteCta;
    }
  }

  static String tripDestLabel({
    required HomeQuickSlotKind kind,
    required AppLocalizations l10n,
    PassengerSavedPlace? place,
  }) {
    final raw = place?.label.trim() ?? '';
    if (raw.isNotEmpty && !raw.startsWith('__texi_slot_')) return raw;
    return storageLabel(kind, l10n);
  }

  /// La dirección guardada no es una calle: es un par lat, lng o «nombre · lat, lng».
  static bool savedPlaceAddressIsCoordinates(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return true;
    if (_savedPlaceCoordPair.hasMatch(text)) return true;
    final parts = text
        .split('\u00B7')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    return parts.length >= 2 && _savedPlaceCoordPair.hasMatch(parts.last);
  }

  /// Calle usable. Descarta coordenadas y un texto que es solo el nombre de referencia.
  static String? savedPlaceStreet(String? address, {String? reference}) {
    final text = address?.trim() ?? '';
    if (text.length < 3 || savedPlaceAddressIsCoordinates(text)) return null;
    final ref = reference?.trim().toLowerCase() ?? '';
    if (ref.isNotEmpty && text.toLowerCase() == ref) return null;
    if (isPrincipalSavedLabel(text)) return null;
    return text;
  }

  static String savedPlaceReferenceName(String label, AppLocalizations l10n) {
    final raw = label.trim();
    if (raw.isEmpty || savedPlaceAddressIsCoordinates(raw)) return '';
    final key = raw.toLowerCase();
    if (homeAliases.contains(key)) {
      return storageLabel(HomeQuickSlotKind.home, l10n);
    }
    if (workAliases.contains(key)) {
      return storageLabel(HomeQuickSlotKind.work, l10n);
    }
    if (raw.startsWith('__texi_slot_')) return '';
    return raw;
  }

  /// Lo que ve el pasajero: nombre de referencia y calle, o coordenadas si no hay calle.
  static String savedPlacePassengerLabel({
    required String reference,
    required String streetOrCoords,
  }) {
    final name = reference.trim();
    final street = streetOrCoords.trim();
    if (street.isEmpty) return name;
    if (name.isEmpty) return street;
    final nameLower = name.toLowerCase();
    final streetLower = street.toLowerCase();
    if (streetLower == nameLower || streetLower.startsWith('$nameLower ')) {
      return street;
    }
    return '$name \u00B7 $street';
  }

  /// Lo que recibe el conductor: la calle, o las coordenadas si no hubo calle.
  static String savedPlaceDriverAddress({
    required String? street,
    required double lat,
    required double lng,
  }) {
    final text = street?.trim() ?? '';
    if (text.length >= 3 &&
        !savedPlaceAddressIsCoordinates(text) &&
        !isPrincipalSavedLabel(text)) {
      if (text.length <= 180) return text;
      return text.substring(0, 180);
    }
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  static PassengerSavedPlace? match(
    List<PassengerSavedPlace> saved,
    HomeQuickSlotKind kind, {
    AppLocalizations? l10n,
  }) {
    if (!isConfigurable(kind)) return null;
    final aliases = <String>{...aliasesFor(kind)};
    if (l10n != null) {
      aliases.add(storageLabel(kind, l10n).trim().toLowerCase());
      aliases.add(displayLabel(kind: kind, l10n: l10n).trim().toLowerCase());
    }
    for (final p in saved) {
      final key = p.label.trim().toLowerCase();
      if (aliases.contains(key)) return p;
    }
    if (kind == HomeQuickSlotKind.favorite) {
      for (final p in saved) {
        if (p.isFavorite) return p;
      }
    }
    return null;
  }

  static HomeQuickSlotKind? parse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'work':
        return HomeQuickSlotKind.work;
      case 'home':
        return HomeQuickSlotKind.home;
      case 'favorite':
        return HomeQuickSlotKind.favorite;
      default:
        return null;
    }
  }
}

final RegExp _savedPlaceCoordPair = RegExp(
  r'^-?\d{1,3}\.\d+\s*,\s*-?\d{1,3}\.\d+$',
);
