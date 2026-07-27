import '../../core/config/app_config.dart';
import '../../data/models/quote_response.dart';

class PassengerRealtimeState {
  final bool connecting;
  final bool connected;
  final String? errorCode;
  final String? activeTripId;
  final String?
  status; // searching | accepted | arrived | started | completed | cancelled | expired
  final QuoteResponse? quote;
  final double? driverLat;
  final double? driverLng;

  /// Grados (0 = norte), desde `trip:driver_location` / REST `driverLocation.bearing`.
  final double? driverBearing;
  final String? driverName;
  final String? carColor;
  final String? carPlate;
  final String? carModel;
  final double? driverRating;
  final int? driverRatingsCount;
  final String? currencyCode;
  final String? driverPhotoUrl;
  final DateTime? driverPhotoExpiresAt;
  final List<TripChatMessage> chatMessages;
  final String? tripChatErrorCode;

  const PassengerRealtimeState({
    required this.connecting,
    required this.connected,
    this.errorCode,
    this.activeTripId,
    this.status,
    this.quote,
    this.driverLat,
    this.driverLng,
    this.driverBearing,
    this.driverName,
    this.carColor,
    this.carPlate,
    this.carModel,
    this.driverRating,
    this.driverRatingsCount,
    this.currencyCode,
    this.driverPhotoUrl,
    this.driverPhotoExpiresAt,
    this.chatMessages = const [],
    this.tripChatErrorCode,
  });

  static const initial = PassengerRealtimeState(
    connecting: false,
    connected: false,
    errorCode: null,
    activeTripId: null,
    status: null,
    quote: null,
    driverLat: null,
    driverLng: null,
    driverBearing: null,
    driverName: null,
    carColor: null,
    carPlate: null,
    carModel: null,
    driverRating: null,
    driverRatingsCount: null,
    currencyCode: null,
    driverPhotoUrl: null,
    driverPhotoExpiresAt: null,
    chatMessages: [],
    tripChatErrorCode: null,
  );

  PassengerRealtimeState copyWith({
    bool? connecting,
    bool? connected,
    String? errorCode,
    String? activeTripId,
    String? status,
    QuoteResponse? quote,
    double? driverLat,
    double? driverLng,
    double? driverBearing,
    String? driverName,
    String? carColor,
    String? carPlate,
    String? carModel,
    double? driverRating,
    int? driverRatingsCount,
    String? currencyCode,
    String? driverPhotoUrl,
    DateTime? driverPhotoExpiresAt,
    List<TripChatMessage>? chatMessages,
    String? tripChatErrorCode,
  }) {
    return PassengerRealtimeState(
      connecting: connecting ?? this.connecting,
      connected: connected ?? this.connected,
      errorCode: errorCode,
      activeTripId: activeTripId ?? this.activeTripId,
      status: status ?? this.status,
      quote: quote ?? this.quote,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      driverBearing: driverBearing ?? this.driverBearing,
      driverName: driverName ?? this.driverName,
      carColor: carColor ?? this.carColor,
      carPlate: carPlate ?? this.carPlate,
      carModel: carModel ?? this.carModel,
      driverRating: driverRating ?? this.driverRating,
      driverRatingsCount: driverRatingsCount ?? this.driverRatingsCount,
      currencyCode: currencyCode ?? this.currencyCode,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      driverPhotoExpiresAt: driverPhotoExpiresAt ?? this.driverPhotoExpiresAt,
      chatMessages: chatMessages ?? this.chatMessages,
      tripChatErrorCode: tripChatErrorCode,
    );
  }
}

class TripChatMessage {
  final String id;
  final String tripId;
  final String senderRole;
  final String messageKind;
  final String? templateCode;
  final String messageText;
  final DateTime? createdAt;

  const TripChatMessage({
    required this.id,
    required this.tripId,
    required this.senderRole,
    required this.messageKind,
    required this.templateCode,
    required this.messageText,
    required this.createdAt,
  });
}

/// Fallback cuando el backend envía username (teléfono) en lugar de fullName.
const String driverNameFallbackDefault = 'Conductor TEXI';

/// Devuelve el nombre a mostrar del conductor.
/// Si [raw] es null, vacío o solo dígitos/símbolos de teléfono, devuelve [fallback].
String displayDriverName(
  String? raw, [
  String fallback = driverNameFallbackDefault,
]) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final t = raw.trim();
  if (RegExp(r'^[\d\s+\-()]+$').hasMatch(t)) return fallback;
  return t;
}

/// Chat pasajero–conductor: solo entre aceptación y arranque del viaje (pickup).
bool passengerTripChatPhaseActive(String? status) {
  return status == 'accepted' || status == 'arrived';
}

String? normalizeDriverPhotoUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final v = raw.trim();
  if (v.startsWith('data:image')) return v;
  if (v.startsWith('http://') || v.startsWith('https://')) return v;
  final uri = Uri.tryParse(v);
  if (uri == null) return null;
  if (uri.hasScheme) return uri.toString();
  if (v.startsWith('/')) return '${AppConfig.baseUrlTripsRest}$v';
  return '${AppConfig.baseUrlTripsRest}/$v';
}

DateTime? parseDriverPhotoExpiresAt(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}
