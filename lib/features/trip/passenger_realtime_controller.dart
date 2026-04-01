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
  final String? status; // searching | accepted | arrived | started | completed | cancelled | expired
  final QuoteResponse? quote;
  final double? driverLat;
  final double? driverLng;
  /// Grados (0 = norte), desde `trip:driver_location` / REST `driverLocation.bearing`.
  final double? driverBearing;
  final String? driverName;
  final String? carColor;
  final String? carPlate;
  final String? carModel;
  final String? driverPhotoUrl;
  final DateTime? driverPhotoExpiresAt;

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
    this.driverPhotoUrl,
    this.driverPhotoExpiresAt,
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
    driverPhotoUrl: null,
    driverPhotoExpiresAt: null,
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
    String? driverPhotoUrl,
    DateTime? driverPhotoExpiresAt,
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
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      driverPhotoExpiresAt: driverPhotoExpiresAt ?? this.driverPhotoExpiresAt,
    );
  }
}

/// Fallback cuando el backend envía username (teléfono) en lugar de fullName.
const String driverNameFallbackDefault = 'Conductor TEXI';

/// Devuelve el nombre a mostrar del conductor.
/// Si [raw] es null, vacío o solo dígitos/símbolos de teléfono, devuelve [fallback].
String displayDriverName(String? raw, [String fallback = driverNameFallbackDefault]) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final t = raw.trim();
  if (RegExp(r'^[\d\s+\-()]+$').hasMatch(t)) return fallback;
  return t;
}

String? normalizeDriverPhotoUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final v = raw.trim();
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

class PassengerRealtimeController extends StateNotifier<PassengerRealtimeState> {
  PassengerRealtimeController() : super(PassengerRealtimeState.initial);

  io.Socket? _socket;
  StreamSubscription? _reconnectSub;
  DateTime? _lastTripSyncApiAt;
  static const _tripSyncMinGap = Duration(seconds: 2);
  Timer? _driverLocationDebounceTimer;
  double? _pendingDriverLat;
  double? _pendingDriverLng;
  double? _pendingDriverBearing;
  bool _tearDown = false;

  String _socketConnectErrorToCode (dynamic data) {
    final s = data?.toString() ?? '';
    if (s.contains('RBAC_FORBIDDEN')) return 'RBAC_FORBIDDEN';
    if (s.contains('RBAC_NO_IDENTITY')) return 'RBAC_NO_IDENTITY';
    if (s.contains('RBAC_NO_AUTH')) return 'RBAC_NO_AUTH';
    if (s.contains('UNAUTHORIZED') || s.contains('NO_TOKEN') || s.contains('AUTH')) {
      return 'NO_TOKEN';
    }
    return 'SOCKET';
  }

  /// Sincroniza el `status` actual del viaje vía REST.
  /// Se usa cuando el socket podría haber perdido eventos (p. ej. driver
  /// finaliza offline).
  Future<void> syncTripStatusFromApi({
    required String tripId,
  }) async {
    final now = DateTime.now();
    if (_lastTripSyncApiAt != null &&
        now.difference(_lastTripSyncApiAt!) < _tripSyncMinGap) {
      return;
    }
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) return;
      final api = TripsApi(token: token);
      final res = await api.getPassengerTripStatus(tripId: tripId);
      final mergedPhoto = normalizeDriverPhotoUrl(res.driverPhotoUrl) ?? state.driverPhotoUrl;
      final mergedPhotoExpiresAt = res.driverPhotoExpiresAt ?? state.driverPhotoExpiresAt;
      state = state.copyWith(
        activeTripId: tripId,
        status: res.status,
        errorCode: null,
        driverLat: res.driverLat ?? state.driverLat,
        driverLng: res.driverLng ?? state.driverLng,
        driverBearing: res.driverBearing ?? state.driverBearing,
        driverPhotoUrl: mergedPhoto,
        driverPhotoExpiresAt: mergedPhotoExpiresAt,
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
    String? driverPhotoUrl,
    String? driverPhotoExpiresAt,
  }) {
    state = state.copyWith(
      activeTripId: tripId,
      driverName: displayDriverName(driverName),
      carColor: carColor,
      carPlate: carPlate,
      carModel: carModel,
      driverPhotoUrl: normalizeDriverPhotoUrl(driverPhotoUrl),
      driverPhotoExpiresAt: parseDriverPhotoExpiresAt(driverPhotoExpiresAt),
    );
  }

  Future<void> connect({required String tripId, QuoteResponse? quote}) async {
    if (state.connected || state.connecting) return;
    _tearDown = false;
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

      void onSocketReady(String reason) {
        if (kDebugMode) {
          debugPrint('[PASSENGER_RT] $reason a $url');
        }
        state = state.copyWith(
          connecting: false,
          connected: true,
          errorCode: null,
          activeTripId: tripId,
          status: state.status ?? 'searching',
          quote: quote,
        );
        unawaited(syncTripStatusFromApi(tripId: tripId));
      }

      socket.onConnect((_) => onSocketReady('conectado'));

      // Tras cortes de red / segundo plano, el cliente puede reconectar sin recrear el widget.
      socket.on('reconnect', (_) => onSocketReady('reconectado'));

      socket.onConnectError((data) {
        if (kDebugMode) {
          debugPrint('[PASSENGER_RT] connect_error: $data');
        }
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
          final rawName = data['fullName']?.toString() ??
              data['driverName']?.toString() ??
              data['driver_name']?.toString();
          final driverName = displayDriverName(rawName);
          final carColor = data['carColor']?.toString() ?? data['car_color']?.toString();
          final carPlate = data['carPlate']?.toString() ?? data['plate']?.toString() ?? data['car_plate']?.toString();
          final carModel = data['carModel']?.toString() ?? data['car_model']?.toString();
          final driverPhotoUrl = normalizeDriverPhotoUrl(
            data['profilePhotoUrl']?.toString() ??
                data['picture_profile']?.toString() ??
                data['driverPhotoUrl']?.toString() ??
                data['photoUrl']?.toString() ??
                data['avatarUrl']?.toString() ??
                data['profile_photo_url']?.toString() ??
                data['driver_photo_url']?.toString(),
          );
          final driverPhotoExpiresAt = parseDriverPhotoExpiresAt(data['profilePhotoExpiresAt']);
          if (kDebugMode) {
            debugPrint('[PASSENGER_RT] trip:accepted tripId=$tripIdData driver=$driverName');
          }
          state = state.copyWith(
            activeTripId: tripIdData,
            status: 'accepted',
            driverName: driverName,
            carColor: carColor,
            carPlate: carPlate,
            carModel: carModel,
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
            debugPrint('[PASSENGER_RT] trip:status tripId=$tripIdData status=$newStatus');
          }
          if (newStatus == 'arrived') {
            final fg = PassengerAppVisibility.isInForeground.value;
            if (fg) {
              SystemSound.play(SystemSoundType.alert);
            }
            unawaited(
              PassengerNotificationService.instance.showDriverArrivedIfBackground(
                isAppInForeground: fg,
                tripId: tripIdData,
                driverName: state.driverName,
              ),
            );
          }
          state = state.copyWith(
            activeTripId: tripIdData,
            status: newStatus,
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
          _driverLocationDebounceTimer =
              Timer(const Duration(milliseconds: 480), () {
            _driverLocationDebounceTimer = null;
            if (_tearDown) return;
            final plat = _pendingDriverLat;
            final plng = _pendingDriverLng;
            if (plat == null || plng == null) return;
            state = state.copyWith(
              driverLat: plat,
              driverLng: plng,
              driverBearing: _pendingDriverBearing ?? state.driverBearing,
            );
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[PASSENGER_RT] Error manejando trip:driver_location: $e');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] Error general conectando: $e');
      }
      state = state.copyWith(
        connecting: false,
        connected: false,
        errorCode: 'UNKNOWN',
      );
    }
  }

  /// Desconecta el socket y resetea el estado (p. ej. cuando el pasajero cancela la búsqueda).
  void disconnect() {
    _tearDown = true;
    _driverLocationDebounceTimer?.cancel();
    _driverLocationDebounceTimer = null;
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
    _driverLocationDebounceTimer?.cancel();
    _reconnectSub?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}

