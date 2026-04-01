import 'package:geolocator/geolocator.dart';

/// Evita `checkPermission` repetido al navegar entre pantallas o reconectar.
class PassengerGeolocationPermissionCache {
  static DateTime? _cachedAt;
  static LocationPermission? _cachedGranted;

  /// Misma semántica que antes: resuelve permiso y opcionalmente solicita.
  /// No lanza; el caller valida `denied` / `deniedForever`.
  static Future<LocationPermission> ensureLocationPermission () async {
    final now = DateTime.now();
    final g = _cachedGranted;
    final at = _cachedAt;
    if (g != null &&
        at != null &&
        (g == LocationPermission.whileInUse || g == LocationPermission.always) &&
        now.difference(at) < const Duration(minutes: 3)) {
      return g;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _cachedGranted = null;
      _cachedAt = null;
      return permission;
    }

    _cachedGranted = permission;
    _cachedAt = DateTime.now();
    return permission;
  }

  static void clear () {
    _cachedAt = null;
    _cachedGranted = null;
  }
}
