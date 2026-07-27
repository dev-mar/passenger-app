part of 'passenger_realtime_controller.dart';

mixin _PassengerRealtimeTrackingMixin on StateNotifier<PassengerRealtimeState> {
  PassengerRealtimeController get _rt => this as PassengerRealtimeController;

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
    _rt._driverMarkerLerpTimer?.cancel();
    final startLat = state.driverLat ?? targetLat;
    final startLng = state.driverLng ?? targetLng;
    final startBearing = state.driverBearing;
    var step = 0;
    _rt._driverMarkerLerpTimer = Timer.periodic(PassengerRealtimeController._driverLerpStepDuration, (timer) {
      if (_rt._tearDown) {
        timer.cancel();
        _rt._driverMarkerLerpTimer = null;
        return;
      }
      step++;
      final t = (step / PassengerRealtimeController._driverLerpTotalSteps).clamp(0.0, 1.0);
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
      if (step >= PassengerRealtimeController._driverLerpTotalSteps) {
        timer.cancel();
        _rt._driverMarkerLerpTimer = null;
      }
    });
  }

  Future<void> syncTripStatusFromApi({
    required String tripId,
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force &&
        _rt._lastTripSyncApiAt != null &&
        now.difference(_rt._lastTripSyncApiAt!) < PassengerRealtimeController._tripSyncMinGap) {
      return;
    }
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) return;
      final previousStatus = state.status;
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
      if (res.status == 'arrived' && previousStatus != 'arrived') {
        final fg = PassengerAppVisibility.isInForeground.value;
        if (fg) {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.mediumImpact();
        }
        unawaited(
          PassengerNotificationService.instance.showDriverArrivedIfBackground(
            isAppInForeground: fg,
            tripId: tripId,
            driverName: mergedDriverName == driverNameFallbackDefault
                ? null
                : mergedDriverName,
          ),
        );
      }
      _rt._lastTripSyncApiAt = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] syncTripStatusFromApi error: $e');
      }
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

  void _handleTripDriverLocation(Map data, String tripId) {
    try {
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
          _animateDriverMarkerTo(
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
