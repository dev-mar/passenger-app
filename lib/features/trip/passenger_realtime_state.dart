import '../../core/config/app_config.dart';
import '../../data/models/quote_response.dart';

export '../../core/l10n/driver_display_name.dart';

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
  final double? estimatedPrice;
  final String? paymentMethod;
  final List<String> tripExtras;
  final List<String> tripSpecials;
  final DateTime? arrivedAt;
  final int? waitSec;
  final int? waitGraceSec;
  final int? enRouteCooldownUntilMs;
  final String? enRouteErrorCode;
  final String? cancelledBy;
  final String? reasonLabel;
  final bool helpAvailable;

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
    this.estimatedPrice,
    this.paymentMethod,
    this.tripExtras = const [],
    this.tripSpecials = const [],
    this.arrivedAt,
    this.waitSec,
    this.waitGraceSec,
    this.enRouteCooldownUntilMs,
    this.enRouteErrorCode,
    this.cancelledBy,
    this.reasonLabel,
    this.helpAvailable = false,
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
    estimatedPrice: null,
    paymentMethod: null,
    tripExtras: [],
    tripSpecials: [],
    arrivedAt: null,
    waitSec: null,
    waitGraceSec: null,
    enRouteCooldownUntilMs: null,
    enRouteErrorCode: null,
    cancelledBy: null,
    reasonLabel: null,
    helpAvailable: false,
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
    double? estimatedPrice,
    String? paymentMethod,
    List<String>? tripExtras,
    List<String>? tripSpecials,
    DateTime? arrivedAt,
    int? waitSec,
    int? waitGraceSec,
    int? enRouteCooldownUntilMs,
    String? enRouteErrorCode,
    String? cancelledBy,
    String? reasonLabel,
    bool? helpAvailable,
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
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tripExtras: tripExtras ?? this.tripExtras,
      tripSpecials: tripSpecials ?? this.tripSpecials,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      waitSec: waitSec ?? this.waitSec,
      waitGraceSec: waitGraceSec ?? this.waitGraceSec,
      enRouteCooldownUntilMs: enRouteCooldownUntilMs ?? this.enRouteCooldownUntilMs,
      enRouteErrorCode: enRouteErrorCode,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      reasonLabel: reasonLabel ?? this.reasonLabel,
      helpAvailable: helpAvailable ?? this.helpAvailable,
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
