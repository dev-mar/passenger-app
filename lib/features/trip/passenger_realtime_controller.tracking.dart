part of 'passenger_realtime_controller.dart';

mixin _PassengerRealtimeTrackingMixin on StateNotifier<PassengerRealtimeState> {
  PassengerRealtimeController get _rt => this as PassengerRealtimeController;

  double _bearingDelta(double? a, double? b) {
    if (a == null || b == null) return double.infinity;
    final raw = (a - b).abs() % 360.0;
    return raw > 180.0 ? 360.0 - raw : raw;
  }

  /// Un solo write de GPS: el mapa interpola el pin. Un lerp aquí
  /// reconstruía todo el GoogleMap ~6 veces por tick y colgaba Android.
  void _commitDriverMarkerTarget({
    required double targetLat,
    required double targetLng,
    required double? targetBearing,
  }) {
    state = state.copyWith(
      driverLat: targetLat,
      driverLng: targetLng,
      driverBearing: targetBearing ?? state.driverBearing,
    );
  }

  /// Aplica status desde push FCM de inmediato (sin esperar REST lento).
  void applyStatusHintFromPush({
    required String tripId,
    required String status,
  }) {
    final s = status.trim().toLowerCase();
    if (s.isEmpty) return;
    if (state.activeTripId != null && state.activeTripId != tripId) return;
    state = state.copyWith(activeTripId: tripId, status: s, errorCode: null);
    unawaited(
      TripSessionStorage.saveLastKnownStatus(tripId: tripId, status: s),
    );
  }

  /// Sincroniza estado REST. `null` = OK o throttle; código si falló (`TRIP_NOT_FOUND`, etc.).
  Future<String?> syncTripStatusFromApi({
    required String tripId,
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force &&
        _rt._lastTripSyncApiAt != null &&
        now.difference(_rt._lastTripSyncApiAt!) < PassengerRealtimeController._tripSyncMinGap) {
      return null;
    }
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) return 'NO_TOKEN';
      final previousStatus = state.status;
      final api = TripsApi(token: token);
      // Timeout: el GET puede tardar por firma de foto; no bloquear el flujo.
      final res = await api
          .getPassengerTripStatus(tripId: tripId)
          .timeout(const Duration(seconds: 8));
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
        estimatedPrice: res.estimatedPrice ?? state.estimatedPrice,
        paymentMethod: res.paymentMethod ?? state.paymentMethod,
        tripExtras: res.tripExtras.isNotEmpty ? res.tripExtras : state.tripExtras,
        tripSpecials:
            res.tripSpecials.isNotEmpty ? res.tripSpecials : state.tripSpecials,
        arrivedAt: res.arrivedAt ?? state.arrivedAt,
        waitSec: res.waitSec ?? state.waitSec,
        waitGraceSec: res.waitGraceSec ?? state.waitGraceSec,
        cashDuePassenger: res.cashDuePassenger ?? state.cashDuePassenger,
        companyGuaranteeToDriver:
            res.companyGuaranteeToDriver ?? state.companyGuaranteeToDriver,
        chatMessages: chatOk ? state.chatMessages : const [],
        tripChatErrorCode: chatOk ? state.tripChatErrorCode : null,
      );
      unawaited(
        TripSessionStorage.saveLastKnownStatus(
          tripId: tripId,
          status: res.status,
        ),
      );
      if (res.status == 'arrived' &&
          previousStatus != 'arrived' &&
          previousStatus != null) {
        final fg = PassengerAppVisibility.isInForeground.value;
        if (fg) {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.mediumImpact();
        }
        unawaited(
          PassengerNotificationService.instance.showDriverArrivedIfBackground(
            isAppInForeground: fg,
            tripId: tripId,
            driverName: driverNameForPassengerAlert(mergedDriverName),
          ),
        );
      }
      _rt._lastTripSyncApiAt = DateTime.now();
      return null;
    } on DioException catch (e) {
      final code = TexiBackendError.codeFromResponse(e.response?.data);
      final status = e.response?.statusCode ?? 0;
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] syncTripStatusFromApi error: $e');
      }
      if (status == 404 || code == 'TRIP_NOT_FOUND') {
        return 'TRIP_NOT_FOUND';
      }
      return code ?? 'TRIP_SYNC_FAILED';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] syncTripStatusFromApi error: $e');
      }
      return 'TRIP_SYNC_FAILED';
    }
  }

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

  /// Hint local de fase (p. ej. tras cold start) sin inventar "searching".
  void hydrateStatusHintFromLocalCache({
    required String tripId,
    required String status,
  }) {
    final s = status.trim().toLowerCase();
    if (s.isEmpty) return;
    if (state.activeTripId != null && state.activeTripId != tripId) return;
    // No pisar un status realtime más fresco.
    if (state.status != null &&
        state.status!.toLowerCase() != s &&
        !passengerTripIsAwaitingDriverMatch(state.status)) {
      return;
    }
    state = state.copyWith(activeTripId: tripId, status: s);
  }

  void _handleTripDriverLocation(Map data, String tripId) {
    try {
      final tripIdData = data['tripId']?.toString();
      if (tripIdData == null || tripIdData != tripId) return;
      // Ubicación del conductor implica viaje aceptado+: salir del overlay matching
      // aunque trip:accepted se haya perdido (sin replay WS).
      if (passengerTripIsAwaitingDriverMatch(state.status) ||
          state.status == null) {
        state = state.copyWith(status: 'accepted', activeTripId: tripIdData);
        unawaited(
          TripSessionStorage.saveLastKnownStatus(
            tripId: tripIdData,
            status: 'accepted',
          ),
        );
        unawaited(_rt.syncTripStatusFromApi(tripId: tripIdData, force: true));
      }
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
      _rt._pendingDriverLat = lat;
      _rt._pendingDriverLng = lng;
      _rt._pendingDriverBearing = bearingParsed;
      _rt._driverLocationDebounceTimer?.cancel();
      _rt._driverLocationDebounceTimer = Timer(
        const Duration(milliseconds: 480),
        () {
          _rt._driverLocationDebounceTimer = null;
          if (_rt._tearDown) return;
          final plat = _rt._pendingDriverLat;
          final plng = _rt._pendingDriverLng;
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
            _rt._pendingDriverBearing,
            state.driverBearing,
          );
          final hasMeaningfulMove =
              latDiff >= PassengerRealtimeController._minDriverDeltaDegrees ||
              lngDiff >= PassengerRealtimeController._minDriverDeltaDegrees ||
              bearingDiff >= PassengerRealtimeController._minBearingDelta;
          if (!hasMeaningfulMove) return;
          _commitDriverMarkerTarget(
            targetLat: plat,
            targetLng: plng,
            targetBearing: _rt._pendingDriverBearing ?? state.driverBearing,
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] Error manejando trip:driver_location: $e');
      }
    }
  }
}
