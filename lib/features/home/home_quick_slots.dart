import '../../core/network/trips_api.dart';
import '../../gen_l10n/app_localizations.dart';

enum HomeQuickSlotKind { airport, work, home, favorite }

class HomeQuickPlaceResult {
  const HomeQuickPlaceResult({required this.lat, required this.lng});

  final double lat;
  final double lng;
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
