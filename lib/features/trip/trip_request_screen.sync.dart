part of 'trip_request_screen.dart';

mixin _TripRequestScreenSyncMixin on _TripRequestScreenDraftMixin {
  @override
  _TripRequestScreenState get _d => this as _TripRequestScreenState;

  void _schedulePassengerEnRouteRouteRefresh({bool immediate = false}) {
    _d._passengerEnRouteRouteDebounce?.cancel();
    if (immediate) {
      unawaited(_fetchPassengerEnRouteRouteToDestination());
      return;
    }
    _d._passengerEnRouteRouteDebounce = Timer(
      TripRouteTrackingPolicy.mapRouteRefreshDebounce,
      () {
        if (!mounted) return;
        unawaited(_fetchPassengerEnRouteRouteToDestination());
      },
    );
  }

  Future<void> _fetchPassengerEnRouteRouteToDestination() async {
    if (!mounted) return;
    final rt = ref.read(passengerRealtimeProvider);
    if (!passengerTripIsEnRouteToDestination(rt.status)) return;
    final dest = _d._destination;
    if (dest == null) return;
    final driver =
        _d._animatedDriverLatLng ??
        (rt.driverLat != null && rt.driverLng != null
            ? LatLng(rt.driverLat!, rt.driverLng!)
            : null);
    if (driver == null) return;

    final token = ++_d._passengerEnRouteRouteRequestToken;
    try {
      final next = await _d._routeService.planEnRouteToDestination(
        driver: driver,
        destination: dest,
      );
      if (!mounted || token != _d._passengerEnRouteRouteRequestToken) return;
      setState(() => _d._passengerEnRouteToDestPoints = next);
      _maybeFitPassengerEnRouteCamera(driver, dest);
    } catch (_) {
      if (!mounted || token != _d._passengerEnRouteRouteRequestToken) return;
      setState(() => _d._passengerEnRouteToDestPoints = <LatLng>[driver, dest]);
    }
  }

  void _maybeFitPassengerEnRouteCamera(LatLng from, LatLng to) {
    final c = _d._controller;
    if (c == null || !_d._appInForeground) return;
    final now = DateTime.now();
    if (_d._lastPassengerEnRouteCameraFitAt != null &&
        now.difference(_d._lastPassengerEnRouteCameraFitAt!) <
            TripRouteTrackingPolicy.navigationCameraMinGap) {
      return;
    }
    _d._lastPassengerEnRouteCameraFitAt = now;

    final minLat = from.latitude < to.latitude ? from.latitude : to.latitude;
    final maxLat = from.latitude > to.latitude ? from.latitude : to.latitude;
    final minLng = from.longitude < to.longitude
        ? from.longitude
        : to.longitude;
    final maxLng = from.longitude > to.longitude
        ? from.longitude
        : to.longitude;
    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    if (latSpan < 0.00035 && lngSpan < 0.00035) {
      unawaited(
        c.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: from, zoom: 16.2),
          ),
        ),
      );
      return;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    unawaited(c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 88)));
  }

  bool get _lowBatteryModeActive =>
      _d._batteryLevel != null &&
      _d._batteryLevel! <= _TripRequestScreenState._lowBatteryThresholdPercent;

  Future<void> _refreshBatteryLevel() async {
    try {
      final level = await _d._battery.batteryLevel;
      if (!mounted) return;
      if (_d._batteryLevel == level) return;
      setState(() => _d._batteryLevel = level);
    } catch (_) {
      // Fallo silencioso: no bloquea flujo del mapa.
    }
  }

  String _currentOptimizationMode() {
    if (!_d._appInForeground) return 'background';
    if (_lowBatteryModeActive) return 'low_battery';
    if (_d._driverLikelyIdle) return 'idle_driver';
    return 'normal';
  }

  void _emitMapOptimizationTelemetryIfNeeded(String? tripId) {
    if (tripId == null || tripId.isEmpty) return;
    final mode = _currentOptimizationMode();
    final modeKey = '$tripId:$mode';
    if (_d._lastOptimizationModeTelemetry == modeKey) return;
    _d._lastOptimizationModeTelemetry = modeKey;
    unawaited(
      PassengerMapTelemetryService.sendMapOptimizationMode(
        mode: mode,
        appState: _d._appInForeground ? 'foreground' : 'background',
        isLowBattery: _lowBatteryModeActive,
        isDriverIdle: _d._driverLikelyIdle,
        tripId: tripId,
        batteryLevel: _d._batteryLevel,
        platform: defaultTargetPlatform.toString(),
        appVersion: _d._appVersion,
      ),
    );
  }

  Future<void> _syncTripStatusOnceThrottled(String tripId) async {
    if (_d._tripStatusSyncInFlight) return;
    final now = DateTime.now();
    final rt = ref.read(passengerRealtimeProvider);
    final trackingDriver = passengerTripIsTrackingDriver(rt.status);
    // Si la URL firmada de la foto est├í por expirar o ya expir├│, refrescamos
    // el GET de inmediato para evitar avatar roto al cargar de red.
    final expiresAt = rt.driverPhotoExpiresAt;
    final photoExpiryBuffer = const Duration(seconds: 45);
    final mustRefreshPhotoNow =
        trackingDriver &&
        expiresAt != null &&
        !now.isBefore(expiresAt.subtract(photoExpiryBuffer));
    // En seguimiento al conductor: polling m├ís frecuente (coordenadas v├¡a GET + socket).
    final minGap = trackingDriver
        ? const Duration(seconds: 10)
        : const Duration(seconds: 55);
    if (!mustRefreshPhotoNow &&
        now.difference(_d._lastTripStatusSyncAt) < minGap) {
      return;
    }
    _d._tripStatusSyncInFlight = true;
    _d._lastTripStatusSyncAt = now;
    try {
      await ref
          .read(passengerRealtimeProvider.notifier)
          .syncTripStatusFromApi(tripId: tripId);
    } finally {
      _d._tripStatusSyncInFlight = false;
    }
  }

  void _startTripStatusPeriodicSync(
    String tripId, {
    Duration interval = const Duration(seconds: 60),
  }) {
    if (_d._tripStatusSyncTimer != null &&
        _d._tripStatusSyncTimerTripId == tripId &&
        _d._tripStatusSyncInterval == interval) {
      return;
    }
    _d._tripStatusSyncTimer?.cancel();
    _d._tripStatusSyncTimer = null;
    _d._tripStatusSyncTimerTripId = tripId;
    _d._tripStatusSyncInterval = interval;

    unawaited(_syncTripStatusOnceThrottled(tripId));

    _d._tripStatusSyncTimer = Timer.periodic(interval, (_) {
      unawaited(_syncTripStatusOnceThrottled(tripId));
    });
  }

  void _stopTripStatusPeriodicSync() {
    _d._tripStatusSyncTimer?.cancel();
    _d._tripStatusSyncTimer = null;
    _d._tripStatusSyncTimerTripId = null;
    _d._tripStatusSyncInterval = const Duration(seconds: 60);
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    _d._appInForeground = state == AppLifecycleState.resumed;
    if (!_d._appInForeground) {
      _d._driverMotionTimer?.cancel();
      _d._driverMotionTimer = null;
      if (mounted) setState(() {});
      return;
    }
    unawaited(_refreshBatteryLevel());
    final tripId = ref.read(tripRequestProvider).tripId;
    if (tripId == null || tripId.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    unawaited(() async {
      // Recargamos el status por REST para compensar la falta de replay por WS.
      await ref
          .read(passengerRealtimeProvider.notifier)
          .syncTripStatusFromApi(tripId: tripId, force: true);

      if (mounted &&
          _d._destination != null &&
          passengerTripIsEnRouteToDestination(
            ref.read(passengerRealtimeProvider).status,
          )) {
        _schedulePassengerEnRouteRouteRefresh(immediate: true);
      }

      final cached = await TripSessionStorage.getCachedDriverInfo(tripId);
      if (cached != null && mounted) {
        ref
            .read(passengerRealtimeProvider.notifier)
            .hydrateDriverInfoFromLocalCache(
              tripId: tripId,
              driverName: cached['driverName'],
              carColor: cached['carColor'],
              carPlate: cached['carPlate'],
              carModel: cached['carModel'],
              driverRating: double.tryParse(cached['driverRating'] ?? ''),
              driverRatingsCount: int.tryParse(
                cached['driverRatingsCount'] ?? '',
              ),
              currencyCode: cached['currencyCode'],
              driverPhotoUrl: cached['driverPhotoUrl'],
              driverPhotoExpiresAt: cached['driverPhotoExpiresAt'],
            );
      }

      unawaited(_refreshPassengerGpsDot(preserveTripGeometry: true));

      // Cargamos flag local de rating para que la sheet decida bien.
      if (_d._ratingDoneTripId != tripId) {
        final done = await TripSessionStorage.isRatingDone(tripId);
        if (!mounted) return;
        setState(() {
          _d._ratingDoneTripId = tripId;
          _d._ratingDone = done;
        });
      }

      final rt = ref.read(passengerRealtimeProvider);
      if (!rt.connected && !rt.connecting && rt.errorCode == null) {
        ref
            .read(passengerRealtimeProvider.notifier)
            .connect(
              tripId: tripId,
              quote: ref.read(tripRequestProvider).quote,
            );
      }
    }());
    if (mounted) setState(() {});
  }

  // ignore: unused_element
  void _startPickOriginOnMap() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _d._error = null;
      _d._activeStop = ActiveStop.none;
      _d._originConfirmed = false;
      _d._pickingOrigin = true;
      _d._pickingDestination = false;
      _d._mapCenter = _d._origin;
    });
    _d._controller?.animateCamera(
      CameraUpdate.newLatLng(_d._origin ?? const LatLng(-16.5, -68.1)),
    );
    _showSubtleSnack(l10n.tripMoveMapSetPickup);
  }

  // ignore: unused_element
  void _startPickDestinationOnMap() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _d._error = null;
      _d._activeStop = ActiveStop.none;
      _d._pickingDestination = true;
      _d._pickingOrigin = false;
      _d._mapCenter = _d._destination ?? _d._origin;
    });
    final center = _d._destination ?? _d._origin ?? const LatLng(-16.5, -68.1);
    _d._controller?.animateCamera(CameraUpdate.newLatLng(center));
    _showSubtleSnack(l10n.tripMoveMapSetDestination);
  }
}

