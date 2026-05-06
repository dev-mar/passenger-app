import '../device/passenger_device_telemetry.dart';

/// Metadatos de dispositivo/red alineados con `buildClientMeta` del backend
/// (mismas claves que la app conductor). La IP la resuelve el servidor.
Future<Map<String, dynamic>> passengerAuthClientMeta() =>
    PassengerDeviceTelemetry.toApiPayload();
