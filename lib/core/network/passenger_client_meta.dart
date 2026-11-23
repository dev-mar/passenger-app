import '../device/passenger_device_telemetry.dart';

Future<Map<String, dynamic>> passengerAuthClientMeta() =>
    PassengerDeviceTelemetry.toApiPayload();
