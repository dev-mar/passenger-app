import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/device/passenger_device_identity.dart';
import 'passenger_promotions_repository.dart';

/// Campos aditivos opcionales para quote/create. Fallan en silencio.
Future<({String? deviceId, String? promoCode})> passengerPromoRequestFields(
  WidgetRef ref,
) async {
  String? deviceId;
  try {
    final id = await PassengerDeviceIdentity.stableDeviceId();
    if (id.trim().isNotEmpty) deviceId = id.trim();
  } catch (_) {}
  final raw = ref.read(passengerPromoCodeProvider);
  final code = raw?.trim();
  return (
    deviceId: deviceId,
    promoCode: (code != null && code.isNotEmpty) ? code : null,
  );
}
