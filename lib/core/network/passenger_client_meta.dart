import 'dart:io' show Platform;

/// Metadatos opcionales que `app_texi_WebSocket` acepta en auth pasajero (telemetría / rate-limit).
Map<String, dynamic> passengerAuthClientMeta({String brand = 'Texi App'}) {
  return <String, dynamic>{
    'brand': brand,
    'ip': '0.0.0.0',
    'model': _safeDeviceModel(),
    'os': Platform.operatingSystem,
    'platform': _apiPlatform(),
  };
}

String _apiPlatform() {
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'unknown';
}

String _safeDeviceModel() {
  try {
    return Platform.localHostname;
  } catch (_) {
    return 'unknown';
  }
}
