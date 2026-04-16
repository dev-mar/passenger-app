import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/app_config.dart';
import '../../core/app_lifecycle/passenger_app_visibility.dart';
import '../../core/auth/auth_service.dart';
import '../../core/notifications/passenger_notification_service.dart';
import '../../core/network/trips_api.dart';
import '../../core/storage/trip_session_storage.dart';
import '../../data/models/quote_response.dart';

final passengerRealtimeProvider =
    StateNotifierProvider<PassengerRealtimeController, PassengerRealtimeState>(
      (ref) => PassengerRealtimeController(),
    );

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
  // Base64 embebido desde backend (Image.network no lo soporta; DriverAvatarPremium usa Image.memory).
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

class PassengerRealtimeController
    extends StateNotifier<PassengerRealtimeState> {
  PassengerRealtimeController() : super(PassengerRealtimeState.initial);

  io.Socket? _socket;
  StreamSubscription? _reconnectSub;
  DateTime? _lastTripSyncApiAt;
  static const _tripSyncMinGap = Duration(seconds: 2);
  Timer? _driverLocationDebounceTimer;
  Timer? _driverMarkerLerpTimer;
  Timer? _connectTimeoutTimer;
  DateTime? _connectStartedAt;
  double? _pendingDriverLat;
  double? _pendingDriverLng;
  double? _pendingDriverBearing;
  bool _tearDown = false;
  static const _connectStuckAfter = Duration(seconds: 12);
  static const _connectHardTimeout = Duration(seconds: 25);
  // Reduce repaints in map when movement is imperceptible.
  static const _minDriverDeltaDegrees = 0.00002; // ~2m lat diff
  static const _minBearingDelta = 4.0; // degrees
  static const _driverLerpTotalSteps = 6;
  static const _driverLerpStepDuration = Duration(milliseconds: 55);

  double _bearingDelta(double? a, double? b) {
    if (a == null || b == null) return double.infinity;
    final raw = (a - b).abs() % 360.0;
    return raw > 180.0 ? 360.0 - raw : raw;
  }

  double _normalizeBearing(double v) {
    final n = v % 360.0;
    return n < 0 ? n + 360.0 : n;
  }

  double _lerpBearing(double from, double to, double t) {
    final a = _normalizeBearing(from);
    final b = _normalizeBearing(to);
    var delta = b - a;
    if (delta > 180.0) delta -= 360.0;
    if (delta < -180.0) delta += 360.0;
    return _normalizeBearing(a + (delta * t));
  }

  void _animateDriverMarkerTo({
    required double targetLat,
    required double targetLng,
    required double? targetBearing,
  }) {
    _driverMarkerLerpTimer?.cancel();
    final startLat = state.driverLat ?? targetLat;
    final startLng = state.driverLng ?? targetLng;
    final startBearing = state.driverBearing;
    var step = 0;
    _driverMarkerLerpTimer = Timer.periodic(_driverLerpStepDuration, (timer) {
      if (_tearDown) {
        timer.cancel();
        _driverMarkerLerpTimer = null;
        return;
      }
      step++;
      final t = (step / _driverLerpTotalSteps).clamp(0.0, 1.0);
      final nextLat = startLat + ((targetLat - startLat) * t);
      final nextLng = startLng + ((targetLng - startLng) * t);
      double? nextBearing;
      if (targetBearing != null && startBearing != null) {
        nextBearing = _lerpBearing(startBearing, targetBearing, t);
      } else {
        nextBearing = targetBearing ?? startBearing;
      }
      state = state.copyWith(
        driverLat: nextLat,
        driverLng: nextLng,
        driverBearing: nextBearing,
      );
      if (step >= _driverLerpTotalSteps) {
        timer.cancel();
        _driverMarkerLerpTimer = null;
      }
    });
  }

  String _socketConnectErrorToCode(dynamic data) {
    final s = data?.toString() ?? '';
    if (s.contains('RBAC_FORBIDDEN')) return 'RBAC_FORBIDDEN';
    if (s.contains('RBAC_NO_IDENTITY')) return 'RBAC_NO_IDENTITY';
    if (s.contains('RBAC_NO_AUTH')) return 'RBAC_NO_AUTH';
    if (s.contains('UNAUTHORIZED') ||
        s.contains('NO_TOKEN') ||
        s.contains('AUTH')) {
      return 'NO_TOKEN';
    }
    return 'SOCKET';
  }

  /// Sincroniza el `status` actual del viaje vía REST.
  /// Se usa cuando el socket podría haber perdido eventos (p. ej. driver
  /// finaliza offline).
  Future<void> syncTripStatusFromApi({
    required String tripId,
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force &&
        _lastTripSyncApiAt != null &&
        now.difference(_lastTripSyncApiAt!) < _tripSyncMinGap) {
      return;
    }
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) return;
      final api = TripsApi(token: token);
      final res = await api.getPassengerTripStatus(tripId: tripId);
      final mergedPhoto =
          normalizeDriverPhotoUrl(res.driverPhotoUrl) ?? state.driverPhotoUrl;
      final mergedPhotoExpiresAt =
          res.driverPhotoExpiresAt ?? state.driverPhotoExpiresAt;
      final mergedNameRaw =
          (res.driverName != null && res.driverName!.trim().isNotEmpty)
          ? res.driverName!.trim()
          : state.driverName;
      final mergedDriverName = displayDriverName(mergedNameRaw);
      final chatOk = passengerTripChatPhaseActive(res.status);
      state = state.copyWith(
        activeTripId: tripId,
        status: res.status,
        errorCode: null,
        driverLat: res.driverLat ?? state.driverLat,
        driverLng: res.driverLng ?? state.driverLng,
        driverBearing: res.driverBearing ?? state.driverBearing,
        driverPhotoUrl: mergedPhoto,
        driverPhotoExpiresAt: mergedPhotoExpiresAt,
        driverName: mergedDriverName,
        carColor: res.carColor ?? state.carColor,
        carPlate: res.carPlate ?? state.carPlate,
        carModel: res.carModel ?? state.carModel,
        driverRating: res.driverRating ?? state.driverRating,
        driverRatingsCount: res.driverRatingsCount ?? state.driverRatingsCount,
        currencyCode: res.currencyCode ?? state.currencyCode,
        chatMessages: chatOk ? state.chatMessages : const [],
        tripChatErrorCode: chatOk ? state.tripChatErrorCode : null,
      );
      _lastTripSyncApiAt = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] syncTripStatusFromApi error: $e');
      }
    }
  }

  /// Hidrata campos de driver/vehículo desde cache local.
  /// Se usa porque WS no re-emite `trip:accepted` al reconectar.
  void hydrateDriverInfoFromLocalCache({
    required String tripId,
    String? driverName,
    String? carColor,
    String? carPlate,
    String? carModel,
    double? driverRating,
    int? driverRatingsCount,
    String? currencyCode,
    String? driverPhotoUrl,
    String? driverPhotoExpiresAt,
  }) {
    state = state.copyWith(
      activeTripId: tripId,
      driverName: displayDriverName(driverName),
      carColor: carColor,
      carPlate: carPlate,
      carModel: carModel,
      driverRating: driverRating,
      driverRatingsCount: driverRatingsCount,
      currencyCode: currencyCode,
      driverPhotoUrl: normalizeDriverPhotoUrl(driverPhotoUrl),
      driverPhotoExpiresAt: parseDriverPhotoExpiresAt(driverPhotoExpiresAt),
    );
  }

  Future<void> connect({required String tripId, QuoteResponse? quote}) async {
    if (state.connected) return;
    if (state.connecting) {
      final start = _connectStartedAt;
      if (start != null &&
          DateTime.now().difference(start) < _connectStuckAfter) {
        return;
      }
      _connectTimeoutTimer?.cancel();
      _connectTimeoutTimer = null;
      _socket?.dispose();
      _socket = null;
      _connectStartedAt = null;
      state = state.copyWith(connecting: false);
    }
    _tearDown = false;
    _connectStartedAt = DateTime.now();
    state = state.copyWith(connecting: true, errorCode: null);
    if (kDebugMode) {
      debugPrint('[PASSENGER_RT] Conectando Socket.IO para tripId=$tripId');
    }

    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          connecting: false,
          connected: false,
          errorCode: 'NO_TOKEN',
        );
        return;
      }

      final url = AppConfig.baseUrlSocket;
      final opts = io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setPath('/socket.io/')
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build();

      final socket = io.io(url, opts);
      _socket = socket;

      _connectTimeoutTimer?.cancel();
      _connectTimeoutTimer = Timer(_connectHardTimeout, () {
        if (_tearDown) return;
        if (!state.connecting) return;
        if (kDebugMode) {
          debugPrint('[PASSENGER_RT] timeout conectando; liberando estado');
        }
        _socket?.dispose();
        _socket = null;
        _connectTimeoutTimer = null;
        _connectStartedAt = null;
        state = state.copyWith(
          connecting: false,
          connected: false,
          errorCode: 'SOCKET_TIMEOUT',
        );
      });

      void onSocketReady(String reason) {
        if (kDebugMode) {
          debugPrint('[PASSENGER_RT] $reason a $url');
        }
        _connectTimeoutTimer?.cancel();
        _connectTimeoutTimer = null;
        _connectStartedAt = null;
        state = state.copyWith(
          connecting: false,
          connected: true,
          errorCode: null,
          activeTripId: tripId,
          status: state.status ?? 'searching',
          quote: quote,
          // Evita limpiar conversación en reconexiones de socket.
          chatMessages: state.chatMessages,
          tripChatErrorCode: state.tripChatErrorCode,
        );
        unawaited(syncTripStatusFromApi(tripId: tripId, force: true));
      }

      socket.onConnect((_) => onSocketReady('conectado'));

      // Tras cortes de red / segundo plano, el cliente puede reconectar sin recrear el widget.
      socket.on('reconnect', (_) => onSocketReady('reconectado'));

      socket.onConnectError((data) {
        if (kDebugMode) {
          debugPrint('[PASSENGER_RT] connect_error: $data');
        }
        _connectTimeoutTimer?.cancel();
        _connectTimeoutTimer = null;
        _connectStartedAt = null;
        state = state.copyWith(
          connecting: false,
          connected: false,
          errorCode: _socketConnectErrorToCode(data),
        );
      });

      socket.onDisconnect((_) {
        if (kDebugMode) {
          debugPrint('[PASSENGER_RT] disconnect');
        }
        state = state.copyWith(connected: false);
      });

      socket.on('trip:accepted', (data) {
        try {
          if (data is! Map) return;
          final tripIdData = data['tripId']?.toString();
          if (tripIdData == null || tripIdData != tripId) return;
          // fullName es el nombre correcto (profile-extended). No usar username (teléfono).
          final rawName =
              data['fullName']?.toString() ??
              data['displayName']?.toString() ??
              data['display_name']?.toString() ??
              data['name']?.toString() ??
              data['driverName']?.toString() ??
              data['driver_name']?.toString();
          final driverName = displayDriverName(rawName);
          final carColor =
              data['carColor']?.toString() ?? data['car_color']?.toString();
          final carPlate =
              data['carPlate']?.toString() ??
              data['plate']?.toString() ??
              data['car_plate']?.toString();
          final carModel =
              data['carModel']?.toString() ?? data['car_model']?.toString();
          final driverPhotoUrl = normalizeDriverPhotoUrl(
            data['profilePhotoUrl']?.toString() ??
                data['picture_profile']?.toString() ??
                data['driverPhotoUrl']?.toString() ??
                data['photoUrl']?.toString() ??
                data['avatarUrl']?.toString() ??
                data['profile_photo_url']?.toString() ??
                data['driver_photo_url']?.toString(),
          );
          final driverPhotoExpiresAt = parseDriverPhotoExpiresAt(
            data['profilePhotoExpiresAt'],
          );
          final ratingRaw = data['driverRating'] ?? data['averageRating'];
          final ratingsCountRaw =
              data['driverRatingsCount'] ?? data['ratingsCount'];
          final driverRating = ratingRaw is num
              ? ratingRaw.toDouble()
              : double.tryParse('$ratingRaw');
          final driverRatingsCount = ratingsCountRaw is num
              ? ratingsCountRaw.toInt()
              : int.tryParse('$ratingsCountRaw');
          final currencyCode = (data['currencyCode'] ?? data['currency'])
              ?.toString();
          if (kDebugMode) {
            debugPrint(
              '[PASSENGER_RT] trip:accepted tripId=$tripIdData driver=$driverName',
            );
          }
          state = state.copyWith(
            activeTripId: tripIdData,
            status: 'accepted',
            driverName: driverName,
            carColor: carColor,
            carPlate: carPlate,
            carModel: carModel,
            driverRating: driverRating,
            driverRatingsCount: driverRatingsCount,
            currencyCode: currencyCode ?? state.currencyCode,
            driverPhotoUrl: driverPhotoUrl,
            driverPhotoExpiresAt: driverPhotoExpiresAt,
          );
          unawaited(() async {
            await TripSessionStorage.cacheDriverInfo(
              tripId: tripIdData,
              driverName: driverName,
              carColor: carColor,
              carPlate: carPlate,
              carModel: carModel,
              driverRating: driverRating,
              driverRatingsCount: driverRatingsCount,
              currencyCode: currencyCode,
              driverPhotoUrl: driverPhotoUrl,
              driverPhotoExpiresAt: driverPhotoExpiresAt?.toIso8601String(),
            );
          }());
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[PASSENGER_RT] Error manejando trip:accepted: $e');
          }
        }
      });

      socket.on('trip:status', (data) {
        try {
          if (data is! Map) return;
          final tripIdData = data['tripId']?.toString();
          final newStatus = data['status']?.toString();
          if (tripIdData == null || newStatus == null) return;
          if (tripIdData != tripId) return;
          if (kDebugMode) {
            debugPrint(
              '[PASSENGER_RT] trip:status tripId=$tripIdData status=$newStatus',
            );
          }
          final nameFromEvent =
              data['fullName']?.toString() ??
              data['displayName']?.toString() ??
              data['display_name']?.toString() ??
              data['name']?.toString() ??
              data['driverName']?.toString() ??
              data['driver_name']?.toString();
          final carColor =
              data['carColor']?.toString() ?? data['car_color']?.toString();
          final carPlate =
              data['carPlate']?.toString() ??
              data['plate']?.toString() ??
              data['car_plate']?.toString();
          final carModel =
              data['carModel']?.toString() ?? data['car_model']?.toString();
          final mergedRaw =
              (nameFromEvent != null && nameFromEvent.trim().isNotEmpty)
              ? nameFromEvent.trim()
              : state.driverName;
          final newDriverName = displayDriverName(mergedRaw);
          final ratingRaw = data['driverRating'] ?? data['averageRating'];
          final ratingsCountRaw =
              data['driverRatingsCount'] ?? data['ratingsCount'];
          final driverRating = ratingRaw is num
              ? ratingRaw.toDouble()
              : double.tryParse('$ratingRaw');
          final driverRatingsCount = ratingsCountRaw is num
              ? ratingsCountRaw.toInt()
              : int.tryParse('$ratingsCountRaw');
          final currencyCode = (data['currencyCode'] ?? data['currency'])
              ?.toString();
          if (newStatus == 'arrived') {
            final fg = PassengerAppVisibility.isInForeground.value;
            if (fg) {
              SystemSound.play(SystemSoundType.alert);
            }
            unawaited(
              PassengerNotificationService.instance
                  .showDriverArrivedIfBackground(
                    isAppInForeground: fg,
                    tripId: tripIdData,
                    driverName: newDriverName == driverNameFallbackDefault
                        ? null
                        : newDriverName,
                  ),
            );
          }
          final chatOk = passengerTripChatPhaseActive(newStatus);
          state = state.copyWith(
            activeTripId: tripIdData,
            status: newStatus,
            driverName: newDriverName,
            carColor: (carColor != null && carColor.trim().isNotEmpty)
                ? carColor.trim()
                : state.carColor,
            carPlate: (carPlate != null && carPlate.trim().isNotEmpty)
                ? carPlate.trim()
                : state.carPlate,
            carModel: (carModel != null && carModel.trim().isNotEmpty)
                ? carModel.trim()
                : state.carModel,
            driverRating: driverRating ?? state.driverRating,
            driverRatingsCount: driverRatingsCount ?? state.driverRatingsCount,
            currencyCode: currencyCode ?? state.currencyCode,
            chatMessages: chatOk ? state.chatMessages : const [],
            tripChatErrorCode: chatOk ? state.tripChatErrorCode : null,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[PASSENGER_RT] Error manejando trip:status: $e');
          }
        }
      });

      socket.on('trip:driver_location', (data) {
        try {
          if (data is! Map) return;
          final tripIdData = data['tripId']?.toString();
          if (tripIdData == null || tripIdData != tripId) return;
          final latRaw = data['lat'];
          final lngRaw = data['lng'];
          if (latRaw is! num || lngRaw is! num) return;
          final lat = latRaw.toDouble();
          final lng = lngRaw.toDouble();
          double? bearingParsed;
          final br = data['bearing'];
          if (br is num) {
            bearingParsed = br.toDouble();
          } else if (br is String) {
            bearingParsed = double.tryParse(br);
          }
          if (kDebugMode) {
            debugPrint(
              '[PASSENGER_RT] trip:driver_location tripId=$tripIdData lat=$lat lng=$lng bearing=$bearingParsed',
            );
          }
          _pendingDriverLat = lat;
          _pendingDriverLng = lng;
          _pendingDriverBearing = bearingParsed;
          _driverLocationDebounceTimer?.cancel();
          _driverLocationDebounceTimer = Timer(
            const Duration(milliseconds: 480),
            () {
              _driverLocationDebounceTimer = null;
              if (_tearDown) return;
              final plat = _pendingDriverLat;
              final plng = _pendingDriverLng;
              if (plat == null || plng == null) return;
              final currentLat = state.driverLat;
              final currentLng = state.driverLng;
              final latDiff = currentLat == null
                  ? double.infinity
                  : (plat - currentLat).abs();
              final lngDiff = currentLng == null
                  ? double.infinity
                  : (plng - currentLng).abs();
              final bearingDiff = _bearingDelta(
                _pendingDriverBearing,
                state.driverBearing,
              );
              final hasMeaningfulMove =
                  latDiff >= _minDriverDeltaDegrees ||
                  lngDiff >= _minDriverDeltaDegrees ||
                  bearingDiff >= _minBearingDelta;
              if (!hasMeaningfulMove) return;
              _animateDriverMarkerTo(
                targetLat: plat,
                targetLng: plng,
                targetBearing: _pendingDriverBearing ?? state.driverBearing,
              );
            },
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[PASSENGER_RT] Error manejando trip:driver_location: $e',
            );
          }
        }
      });

      socket.on('trip:arrival_reminder', (data) {
        try {
          if (data is! Map) return;
          final tripIdData = data['tripId']?.toString();
          if (tripIdData == null || tripIdData != tripId) return;
          final fg = PassengerAppVisibility.isInForeground.value;
          if (fg &&
              PassengerNotificationService.shouldPlayForegroundChatAlert()) {
            SystemSound.play(SystemSoundType.alert);
            HapticFeedback.mediumImpact();
          }
          unawaited(
            PassengerNotificationService.instance
                .showTripChatMessageIfBackground(
                  isAppInForeground: fg,
                  tripId: tripIdData,
                  senderRole: 'driver',
                  messageText:
                      'Tu conductor te está esperando en el punto de recogida.',
                  notifyInForeground: true,
                ),
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[PASSENGER_RT] Error manejando trip:arrival_reminder: $e',
            );
          }
        }
      });

      socket.on('trip:chat:new', (data) {
        try {
          if (data is! Map) return;
          if (!passengerTripChatPhaseActive(state.status)) return;
          final eventTripId = data['tripId']?.toString();
          if (eventTripId == null || eventTripId != tripId) return;
          final id =
              data['id']?.toString() ??
              '${DateTime.now().millisecondsSinceEpoch}-${state.chatMessages.length}';
          final senderRole = data['senderRole']?.toString() ?? 'driver';
          final messageKind = data['messageKind']?.toString() ?? 'text';
          final templateCode = data['templateCode']?.toString();
          final messageText = data['messageText']?.toString().trim() ?? '';
          if (messageText.isEmpty) return;
          final createdAt = DateTime.tryParse(
            data['createdAt']?.toString() ?? '',
          );
          final next = List<TripChatMessage>.from(state.chatMessages)
            ..add(
              TripChatMessage(
                id: id,
                tripId: eventTripId,
                senderRole: senderRole,
                messageKind: messageKind,
                templateCode: templateCode,
                messageText: messageText,
                createdAt: createdAt,
              ),
            );
          state = state.copyWith(chatMessages: next, tripChatErrorCode: null);
          final fromOtherRole = senderRole != 'passenger';
          if (fromOtherRole) {
            final inForeground = PassengerAppVisibility.isInForeground.value;
            if (inForeground &&
                PassengerNotificationService.shouldPlayForegroundChatAlert()) {
              SystemSound.play(SystemSoundType.alert);
              HapticFeedback.lightImpact();
            }
            unawaited(
              PassengerNotificationService.instance
                  .showTripChatMessageIfBackground(
                    isAppInForeground: inForeground,
                    tripId: eventTripId,
                    senderRole: senderRole,
                    messageText: messageText,
                    notifyInForeground: true,
                  ),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[PASSENGER_RT] Error manejando trip:chat:new: $e');
          }
        }
      });

      socket.on('trip:chat:error', (data) {
        final code =
            (data is Map ? data['code'] : null)?.toString() ??
            'TRIP_CHAT_ERROR';
        state = state.copyWith(tripChatErrorCode: code);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] Error general conectando: $e');
      }
      _connectTimeoutTimer?.cancel();
      _connectTimeoutTimer = null;
      _connectStartedAt = null;
      state = state.copyWith(
        connecting: false,
        connected: false,
        errorCode: 'UNKNOWN',
      );
    }
  }

  void sendTripChatTemplate({
    required String tripId,
    required String templateCode,
  }) {
    if (!passengerTripChatPhaseActive(state.status)) {
      state = state.copyWith(tripChatErrorCode: 'TRIP_CHAT_NOT_AVAILABLE');
      return;
    }
    if (_socket == null || !state.connected) {
      state = state.copyWith(tripChatErrorCode: 'SOCKET');
      return;
    }
    _socket!.emit('trip:chat:send', {
      'tripId': tripId,
      'messageKind': 'template',
      'templateCode': templateCode,
    });
  }

  void sendTripChatText({required String tripId, required String text}) {
    final sanitized = text.trim();
    if (sanitized.isEmpty) return;
    if (!passengerTripChatPhaseActive(state.status)) {
      state = state.copyWith(tripChatErrorCode: 'TRIP_CHAT_NOT_AVAILABLE');
      return;
    }
    if (_socket == null || !state.connected) {
      state = state.copyWith(tripChatErrorCode: 'SOCKET');
      return;
    }
    _socket!.emit('trip:chat:send', {
      'tripId': tripId,
      'messageKind': 'text',
      'messageText': sanitized,
    });
  }

  /// Desconecta el socket y resetea el estado (p. ej. cuando el pasajero cancela la búsqueda).
  void disconnect() {
    _tearDown = true;
    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = null;
    _connectStartedAt = null;
    _driverLocationDebounceTimer?.cancel();
    _driverLocationDebounceTimer = null;
    _driverMarkerLerpTimer?.cancel();
    _driverMarkerLerpTimer = null;
    _pendingDriverLat = null;
    _pendingDriverLng = null;
    _pendingDriverBearing = null;
    _lastTripSyncApiAt = null;
    _reconnectSub?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _tearDown = false;
    state = PassengerRealtimeState.initial;
  }

  @override
  void dispose() {
    _tearDown = true;
    _connectTimeoutTimer?.cancel();
    _driverLocationDebounceTimer?.cancel();
    _driverMarkerLerpTimer?.cancel();
    _reconnectSub?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}
