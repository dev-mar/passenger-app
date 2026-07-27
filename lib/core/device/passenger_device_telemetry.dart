import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'passenger_device_identity.dart';

/// Misma forma que el conductor (`app_instance_id`, `platform`, etc.) para
/// `buildClientMeta` en `POST /api/v2/auth/login` y rutas de auth pasajero.
class PassengerDeviceTelemetry {
  PassengerDeviceTelemetry._();

  static Future<Map<String, dynamic>> toApiPayload() async {
    final payload = <String, dynamic>{};
    final info = await _readDeviceInfo();
    final appVersion = await _readAppVersion();
    final networkType = await _readNetworkType();
    final deviceId = await PassengerDeviceIdentity.stableDeviceId();

    payload['device_id'] = deviceId;
    if (info['app_instance_id'] != null) {
      payload['app_instance_id'] = info['app_instance_id'];
    }
    if (info['platform'] != null) payload['platform'] = info['platform'];
    if (appVersion != null) payload['app_version'] = appVersion;
    if (info['os_version'] != null) payload['os_version'] = info['os_version'];
    if (info['brand'] != null) payload['brand'] = info['brand'];
    if (info['model'] != null) payload['model'] = info['model'];
    if (networkType != null) payload['network_type'] = networkType;

    return payload;
  }

  static Future<Map<String, String?>> _readDeviceInfo() async {
    final info = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final d = await info.androidInfo;
        return {
          'app_instance_id': d.id,
          'platform': 'android',
          'os_version': d.version.release,
          'brand': d.brand,
          'model': d.model,
        };
      }
      if (Platform.isIOS) {
        final d = await info.iosInfo;
        return {
          'app_instance_id': d.identifierForVendor,
          'platform': 'ios',
          'os_version': d.systemVersion,
          'brand': 'Apple',
          'model': d.utsname.machine,
        };
      }
    } catch (_) {}

    return {
      'app_instance_id': null,
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'brand': null,
      'model': null,
    };
  }

  static Future<String?> _readAppVersion() async {
    try {
      final p = await PackageInfo.fromPlatform();
      final version = p.version.trim();
      final build = p.buildNumber.trim();
      if (version.isEmpty) return null;
      return build.isEmpty ? version : '$version+$build';
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _readNetworkType() async {
    try {
      final list = await Connectivity().checkConnectivity();
      if (list.isEmpty) return null;
      if (list.length == 1 && list.first == ConnectivityResult.none) {
        return 'none';
      }
      if (list.contains(ConnectivityResult.mobile)) return 'cellular';
      if (list.contains(ConnectivityResult.wifi)) return 'wifi';
      if (list.contains(ConnectivityResult.ethernet)) return 'ethernet';
      return 'unknown';
    } catch (_) {
      return null;
    }
  }
}
