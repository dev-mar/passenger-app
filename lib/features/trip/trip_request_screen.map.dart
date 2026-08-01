part of 'trip_request_screen.dart';

/// Ajustes GPS para recogida: alta precisión y sin filtro de distancia.
LocationSettings _passengerPickupLocationSettings() {
  if (kIsWeb) {
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: const Duration(seconds: 12),
    );
  }
  return const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
    timeLimit: Duration(seconds: 12),
  );
}

mixin _TripRequestScreenMapMixin on ConsumerState<TripRequestScreen> {
  _TripRequestScreenState get _m => this as _TripRequestScreenState;

  bool _computeIsDraftMapConfirmMode() {
    final tripId = ref.read(tripRequestProvider).tripId;
    if (tripId != null) return false;
    final needsOriginConfirm =
        !_m._originConfirmed &&
        _m._destination == null &&
        !_m._pickingOrigin &&
        !_m._pickingDestination;
    final needsDestinationConfirm =
        _m._originConfirmed &&
        _m._destination == null &&
        !_m._pickingOrigin &&
        !_m._pickingDestination;
    final needsAnyMapConfirm = needsOriginConfirm || needsDestinationConfirm;
    return _m._activeStop == ActiveStop.none &&
        (_m._pickingOrigin || _m._pickingDestination || needsAnyMapConfirm);
  }

  void _onCameraIdleForMapConfirm() {
    if (!_computeIsDraftMapConfirmMode()) return;
    _m._mapConfirmIdleTimer?.cancel();
    _m._mapConfirmIdleTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted || !_computeIsDraftMapConfirmMode()) return;
      setState(() {
        _m._mapConfirmInstructionHiddenWhileDragging = false;
      });
      unawaited(_refreshNeedlePreviewFromMapCenter());
    });
  }

  Future<void> _refreshNeedlePreviewFromMapCenter() async {
    final center = _m._mapCenter;
    if (center == null || !_computeIsDraftMapConfirmMode()) return;
    final label = await _m._geocoding.reverseGeocodeStreet(
      lat: center.latitude,
      lng: center.longitude,
    );
    if (!mounted || !_computeIsDraftMapConfirmMode()) return;
    setState(() {
      final t = label?.trim();
      _m._mapNeedleAddressPreview = (t != null && t.isNotEmpty) ? t : null;
    });
  }
  /// Obtiene un arreglo GPS sin modificar origen/destino del viaje (reapertura con snapshot).
  Future<void> _refreshPassengerGpsDot({
    required bool preserveTripGeometry,
  }) async {
    if (!mounted) return;

    final permission =
        await PassengerGeolocationPermissionCache.ensureLocationPermission(
      requestIfDenied: false,
    );
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        if (!preserveTripGeometry || !_m._deviceGpsFixOk) {
          _m._deviceGpsFixOk = false;
        }
      });
      return;
    }

    try {
      await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _m._deviceGpsFixOk = true;
        _m._mapMyLocationDotEnabled = false;
      });
      // Dos tiempos para que la capa de Maps (puntito azul) se reinicie bien tras cold start.
      await Future<void>.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;
      setState(() => _m._mapMyLocationDotEnabled = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!preserveTripGeometry || !_m._deviceGpsFixOk) {
          _m._deviceGpsFixOk = false;
        }
      });
    }
  }

  Future<bool> _ensureDeviceGpsForNewTrip() async {
    if (_m._deviceGpsFixOk) return true;
    final hasTrip = ref.read(tripRequestProvider).tripId != null;
    await _refreshPassengerGpsDot(preserveTripGeometry: hasTrip);
    return _m._deviceGpsFixOk;
  }

  Future<void> _recenterMapForPassenger({
    double? driverLat,
    double? driverLng,
  }) async {
    if (_m._recenterInProgress) return;
    setState(() => _m._recenterInProgress = true);
    final c = _m._controller;
    if (c == null) {
      if (mounted) setState(() => _m._recenterInProgress = false);
      return;
    }
    try {
      // Viaje activo: prioridad el pin del vehículo (no forzar GPS si falla).
      final animated = _m._animatedDriverLatLng;
      if (animated != null || (driverLat != null && driverLng != null)) {
        final driver = animated ?? LatLng(driverLat!, driverLng!);
        await c.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: driver, zoom: 15.8),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      final passenger = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _m._deviceGpsFixOk = true);
      }

      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: passenger, zoom: 16),
        ),
      );
    } catch (_) {
      // Silencioso: es una acción de conveniencia (no forzar mapa en reconnect).
    } finally {
      if (mounted) setState(() => _m._recenterInProgress = false);
    }
  }

  void _fitCameraToOriginDestination() {
    if (_m._controller == null || _m._origin == null || _m._destination == null) return;
    final o = _m._origin!;
    final d = _m._destination!;
    final mid = LatLng(
      (o.latitude + d.latitude) / 2.0,
      (o.longitude + d.longitude) / 2.0,
    );
    final distKm = tripRequestDistanceKm(o, d);
    final zoom = tripRequestEstimateZoomForDistanceKm(distKm);
    _m._controller!.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: mid, zoom: zoom)),
    );
  }

  /// Tras un viaje terminado, alinear origen y pin del mapa con el GPS actual (no dejar el centro en el destino).
  Future<void> _recenterMapToDeviceGpsAfterTripEnd() async {
    if (!mounted) return;

    Future<void> apply(LatLng latLng) async {
      if (!mounted) return;
      setState(() {
        _m._origin = latLng;
        _m._mapCenter = latLng;
        _m._originDisplayLabel = null;
        _m._deviceGpsFixOk = true;
      });
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(latLng.latitude, latLng.longitude);
      final c = _m._controller;
      if (c != null) {
        await c.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 16),
          ),
        );
      }
      if (!mounted) return;
      unawaited(_refreshPassengerGpsDot(preserveTripGeometry: false));
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      await apply(LatLng(position.latitude, position.longitude));
    } catch (_) {
      if (!mounted) return;
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          await apply(LatLng(last.latitude, last.longitude));
          return;
        }
      } catch (_) {
        // seguir al fallback
      }
      if (!mounted) return;
      final fallback = _m._origin;
      if (fallback != null) {
        setState(() => _m._mapCenter = fallback);
        final c = _m._controller;
        if (c != null) {
          await c.animateCamera(CameraUpdate.newLatLngZoom(fallback, 16));
        }
      }
    }
  }
  Future<void> _refinePassengerOriginOnce(int generation) async {
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted || generation != _m._originResolveGeneration) return;
    if (_m._originConfirmed || !_m._pickingOrigin || _m._destination != null) return;
    final prev = _m._origin;
    if (prev == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 12));
      if (!mounted || generation != _m._originResolveGeneration) return;
      if (_m._originConfirmed || !_m._pickingOrigin) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      final movedM = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        latLng.latitude,
        latLng.longitude,
      );
      if (movedM < 12) return;
      setState(() {
        _m._origin = latLng;
        _m._mapCenter = latLng;
        _m._deviceGpsFixOk = true;
        _m._originError = null;
      });
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(latLng.latitude, latLng.longitude);
      final c = _m._controller;
      if (c != null) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      }
    } catch (_) {
      // Silencioso: el usuario ya tiene un origen usable.
    }
  }

  Future<void> _resolveOrigin() async {
    if (!mounted) return;
    _m._originResolveGeneration++;
    final refineGen = _m._originResolveGeneration;
    final permission =
        await PassengerGeolocationPermissionCache.ensureLocationPermission(
      requestIfDenied: false,
    );
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      LatLng? lastKnownLatLng;
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          lastKnownLatLng = LatLng(last.latitude, last.longitude);
        }
      } catch (_) {
        // seguimos sin lastKnown
      }
      if (mounted) {
        setState(() {
          _m._loadingOrigin = false;
          _m._deviceGpsFixOk = lastKnownLatLng != null;
          _m._originError = lastKnownLatLng == null
              ? AppLocalizations.of(context)!.homeLocationError
              : null;
          _m._origin = lastKnownLatLng;
          _m._mapCenter = lastKnownLatLng;
          if (_m._destination == null) {
            _m._originConfirmed = false;
            _m._pickingOrigin = true;
            _m._pickingDestination = false;
            _m._activeStop = ActiveStop.none;
          }
        });
      }
      if (lastKnownLatLng != null) {
        ref
            .read(tripRequestProvider.notifier)
            .setOrigin(lastKnownLatLng.latitude, lastKnownLatLng.longitude);
        await _loadPinIcons();
        unawaited(_refinePassengerOriginOnce(refineGen));
      }
      return;
    }

    // Ãšltima posiciÃ³n conocida primero: desbloquea el mapa (loader global) sin esperar
    // solo al primer `getCurrentPosition`, que en algunos Android se retrasa o falla
    // si no hay `timeLimit` nativo en los settings (vÃ©ase conductor / AndroidSettings).
    LatLng? bootstrapLatLng;
    if (_m._destination == null) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          bootstrapLatLng = LatLng(last.latitude, last.longitude);
        }
      } catch (_) {}
      final bootstrap = bootstrapLatLng;
      if (mounted && bootstrap != null) {
        setState(() {
          _m._origin = bootstrap;
          _m._mapCenter = bootstrap;
          _m._loadingOrigin = false;
          _m._originError = null;
          _m._deviceGpsFixOk = true;
          _m._originConfirmed = false;
          _m._pickingOrigin = true;
          _m._pickingDestination = false;
          _m._activeStop = ActiveStop.none;
        });
        ref.read(tripRequestProvider.notifier).setOrigin(
              bootstrap.latitude,
              bootstrap.longitude,
            );
        unawaited(_loadPinIcons());
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _m._origin = LatLng(position.latitude, position.longitude);
        _m._mapCenter = _m._origin;
        _m._loadingOrigin = false;
        _m._originError = null;
        _m._deviceGpsFixOk = true;
        if (_m._destination == null) {
          _m._originConfirmed = false;
          _m._pickingOrigin = true;
          _m._pickingDestination = false;
          _m._activeStop = ActiveStop.none;
        }
      });
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(_m._origin!.latitude, _m._origin!.longitude);
      await _loadPinIcons();
      unawaited(_refinePassengerOriginOnce(refineGen));
    } catch (e) {
      if (!mounted) return;
      // Ya habÃ­amos mostrado mapa con bootstrap: no pisar `_m._origin` con null.
      if (_m._origin != null) {
        setState(() {
          _m._loadingOrigin = false;
          _m._originError = null;
        });
        unawaited(_refinePassengerOriginOnce(refineGen));
        return;
      }
      LatLng? lastKnownLatLng;
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          lastKnownLatLng = LatLng(last.latitude, last.longitude);
        }
      } catch (_) {
        // seguimos sin lastKnown
      }
      setState(() {
        _m._loadingOrigin = false;
        _m._deviceGpsFixOk = lastKnownLatLng != null;
        _m._originError = lastKnownLatLng == null
            ? AppLocalizations.of(context)!.homeLocationErrorGps
            : null;
        _m._origin = lastKnownLatLng;
        _m._mapCenter = lastKnownLatLng;
        if (_m._destination == null) {
          _m._originConfirmed = false;
          _m._pickingOrigin = true;
          _m._pickingDestination = false;
          _m._activeStop = ActiveStop.none;
        }
      });
      if (lastKnownLatLng != null) {
        ref
            .read(tripRequestProvider.notifier)
            .setOrigin(lastKnownLatLng.latitude, lastKnownLatLng.longitude);
        unawaited(_refinePassengerOriginOnce(refineGen));
      }
      await _loadPinIcons();
    }
  }

  Future<void> _loadPinIcons() async {
    if (!mounted) return;
    try {
      final originIcon = await buildPassengerWaypointMapPinIcon(
        fill: const Color(0xFFF9AB00),
      );
      final destinationIcon = await buildPassengerWaypointMapPinIcon(
        fill: const Color(0xFF111111),
      );
      if (!mounted) return;
      setState(() {
        _m._originOnTripIcon = originIcon;
        _m._destinationOnTripIcon = destinationIcon;
      });
    } catch (_) {
      // Ignoramos fallos de precarga; los markers siguen funcionando con fallback.
    }
  }

  Future<void> _loadDriverTripIcon() async {
    if (!mounted) return;
    try {
      final icon = await buildPassengerDriverOnTripMapIcon();
      if (!mounted) return;
      setState(() => _m._driverOnTripIcon = icon);
    } catch (_) {
      // Fallback: pin verde por defecto.
    }
  }

  /// Enciende/apaga el pulse del marcador del conductor segÃºn haya o no
  /// `_m._animatedDriverLatLng`. Mantiene la animaciÃ³n dormida en borrador.
  void _syncDriverPulseAnimation() {
    if (_m._animatedDriverLatLng != null) {
      if (!_m._driverPulseController.isAnimating) {
        _m._driverPulseController.repeat(reverse: true);
      }
    } else {
      if (_m._driverPulseController.isAnimating) {
        _m._driverPulseController.stop();
      }
    }
  }

  void _syncAnimatedDriverMarker({
    required String? tripId,
    required String? status,
    required double? rawDriverLat,
    required double? rawDriverLng,
  }) {
    final shouldTrackDriver =
        tripId != null &&
        passengerTripIsTrackingDriver(status) &&
        rawDriverLat != null &&
        rawDriverLng != null;
    if (!shouldTrackDriver) {
      if (_m._animatedDriverLatLng != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _m._animatedDriverLatLng = null);
          _syncDriverPulseAnimation();
        });
      }
      _m._driverMotionTimer?.cancel();
      _m._driverMotionTimer = null;
      _m._lastDriverRawLat = null;
      _m._lastDriverRawLng = null;
      _m._driverLikelyIdle = false;
      return;
    }
    if (_m._lastDriverRawLat != null && _m._lastDriverRawLng != null) {
      final movedMeters = Geolocator.distanceBetween(
        _m._lastDriverRawLat!,
        _m._lastDriverRawLng!,
        rawDriverLat,
        rawDriverLng,
      );
      _m._driverLikelyIdle = movedMeters < 3.5;
    } else {
      _m._driverLikelyIdle = false;
    }
    if (!_m._appInForeground) {
      _m._driverMotionTimer?.cancel();
      _m._driverMotionTimer = null;
      if (_m._animatedDriverLatLng == null ||
          (_m._animatedDriverLatLng!.latitude - rawDriverLat).abs() > 0.000001 ||
          (_m._animatedDriverLatLng!.longitude - rawDriverLng).abs() > 0.000001) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(
            () => _m._animatedDriverLatLng = LatLng(rawDriverLat, rawDriverLng),
          );
          _syncDriverPulseAnimation();
        });
      }
      _m._lastDriverRawLat = rawDriverLat;
      _m._lastDriverRawLng = rawDriverLng;
      return;
    }
    if (_m._lastDriverRawLat == rawDriverLat &&
        _m._lastDriverRawLng == rawDriverLng) {
      return;
    }
    _m._lastDriverRawLat = rawDriverLat;
    _m._lastDriverRawLng = rawDriverLng;
    final target = LatLng(rawDriverLat, rawDriverLng);
    if (passengerTripIsEnRouteToDestination(status)) {
      _m._schedulePassengerEnRouteRouteRefresh();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animateDriverMarkerTo(target);
      if (passengerTripIsTrackingDriver(status)) {
        _centerCameraOnDriverPin(target);
      }
    });
  }

  /// Viaje activo: el pin del vehículo es el ancla visual del mapa.
  void _centerCameraOnDriverPin(LatLng driver) {
    final c = _m._controller;
    if (c == null || !_m._appInForeground) return;
    final now = DateTime.now();
    if (_m._lastPassengerEnRouteCameraFitAt != null &&
        now.difference(_m._lastPassengerEnRouteCameraFitAt!) <
            TripRouteTrackingPolicy.navigationCameraMinGap) {
      return;
    }
    _m._lastPassengerEnRouteCameraFitAt = now;
    unawaited(
      c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: driver, zoom: 15.8),
        ),
      ),
    );
  }

  void _animateDriverMarkerTo(LatLng target) {
    _m._driverMotionTimer?.cancel();
    if (!_m._appInForeground) {
      setState(() => _m._animatedDriverLatLng = target);
      _syncDriverPulseAnimation();
      return;
    }
    final from = _m._animatedDriverLatLng ?? target;
    if ((from.latitude - target.latitude).abs() < 0.000001 &&
        (from.longitude - target.longitude).abs() < 0.000001) {
      setState(() => _m._animatedDriverLatLng = target);
      _syncDriverPulseAnimation();
      return;
    }
    final lowPowerVisual = _m._lowBatteryModeActive || _m._driverLikelyIdle;
    final totalSteps = lowPowerVisual ? 5 : 9;
    final stepDuration = lowPowerVisual
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 85);
    var step = 0;
    _m._driverMotionTimer = Timer.periodic(stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      step++;
      final t = step / totalSteps;
      final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
      final lat = from.latitude + (target.latitude - from.latitude) * eased;
      final lng = from.longitude + (target.longitude - from.longitude) * eased;
      setState(() => _m._animatedDriverLatLng = LatLng(lat, lng));
      if (step == 1) {
        _syncDriverPulseAnimation();
      }
      if (step >= totalSteps) {
        timer.cancel();
      }
    });
  }

  String _activeTripMapStyleFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? _TripRequestScreenState._tripCleanMapStyleNight
        : _TripRequestScreenState._tripCleanMapStyleDay;
  }

  void _onMapCreated(GoogleMapController c) {
    _m._controller = c;
  }

  void _onCameraMove(CameraPosition position) {
    _m._mapCenter = position.target;
    if (_computeIsDraftMapConfirmMode()) {
      _m._mapConfirmIdleTimer?.cancel();
      final shouldHideChrome = !_m._mapConfirmInstructionHiddenWhileDragging;
      final shouldCollapseSearch = _m._draftSearchFocus.hasFocus ||
          _m._draftSearchController.text.isNotEmpty;
      if (shouldHideChrome || shouldCollapseSearch) {
        setState(() {
          if (shouldHideChrome) {
            _m._mapConfirmInstructionHiddenWhileDragging = true;
          }
          if (shouldCollapseSearch) {
            _m._draftSearchCollapseToken++;
            _m._draftSearchFocus.unfocus();
            if (_m._draftSearchController.text.isNotEmpty) {
              _m._draftSearchController.clear();
              _m._draftSuggestions = const <PlaceSuggestion>[];
              _m._loadingDraftSuggestions = false;
            }
          }
        });
      }
    }
    // Si solo falta confirmar destino (origen listo, destino nulo) y el usuario
    // estÃ¡ moviendo el mapa, ocultamos opciones expandidas para mantener
    // una experiencia tipo Uber/Lyft.
    if (_m._destination == null &&
        !_m._pickingOrigin &&
        !_m._pickingDestination &&
        _m._activeStop != ActiveStop.none) {
      setState(() {
        _m._activeStop = ActiveStop.none;
      });
    }
  }

  /// Obtiene el `LatLng` a confirmar desde el centro de cÃ¡mara.
  ///
  /// Volvimos el pin al centro de la pantalla, asÃ­ que el punto confirmado debe ser
  /// el centro real del mapa (como el flujo original).
  Future<LatLng> _getLatLngFromNeedle() async {
    final fallback = _m._mapCenter ?? _m._origin ?? const LatLng(-16.5, -68.1);
    return fallback;
  }

  Future<void> _updateOriginStreetLabel(LatLng p) async {
    final label = await _m._geocoding.reverseGeocodeStreet(
      lat: p.latitude,
      lng: p.longitude,
    );
    if (!mounted) return;
    if (_m._origin == null) return;
    final samePoint =
        (_m._origin!.latitude - p.latitude).abs() < 0.00001 &&
        (_m._origin!.longitude - p.longitude).abs() < 0.00001;
    if (!samePoint) return;
    if (label == null || label.isEmpty) return;
    setState(() => _m._originDisplayLabel = label);
  }

  Future<void> _updateDestinationStreetLabel(LatLng p) async {
    final label = await _m._geocoding.reverseGeocodeStreet(
      lat: p.latitude,
      lng: p.longitude,
    );
    if (!mounted) return;
    if (_m._destination == null) return;
    final samePoint =
        (_m._destination!.latitude - p.latitude).abs() < 0.00001 &&
        (_m._destination!.longitude - p.longitude).abs() < 0.00001;
    if (!samePoint) return;
    if (label == null || label.isEmpty) return;
    setState(() => _m._destinationDisplayLabel = label);
  }

  Future<void> _setOriginFromNeedle() async {
    final p = await _getLatLngFromNeedle();
    final preview = _m._mapNeedleAddressPreview?.trim();
    _m._mapConfirmIdleTimer?.cancel();
    setState(() {
      _m._origin = p;
      _m._originDisplayLabel = preview != null && preview.isNotEmpty
          ? preview
          : '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
      _m._originConfirmed = true;
      _m._pickingOrigin = false;
      _m._pickingDestination = false;
      _m._activeStop = ActiveStop.none;
      _m._routePoints = null;
      _m._mapNeedleAddressPreview = null;
      _m._mapConfirmInstructionHiddenWhileDragging = false;
      _m._draftEditTarget = PassengerDraftEditTarget.none;
    });
    ref.read(tripRequestProvider.notifier).setOrigin(p.latitude, p.longitude);
    if (_m._destination != null) _m._fetchRoute();
    _updateOriginStreetLabel(p);
    if (_m._destination != null) {
      _m._notifyDraftSearchCollapsedAfterBothStops();
    }
  }

  Future<void> _setDestinationFromNeedle() async {
    final p = await _getLatLngFromNeedle();
    final preview = _m._mapNeedleAddressPreview?.trim();
    _m._mapConfirmIdleTimer?.cancel();
    setState(() {
      _m._destination = p;
      _m._destinationDisplayLabel = preview != null && preview.isNotEmpty
          ? preview
          : '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
      _m._pickingDestination = false;
      _m._routePoints = null;
      _m._mapNeedleAddressPreview = null;
      _m._mapConfirmInstructionHiddenWhileDragging = false;
      _m._draftEditTarget = PassengerDraftEditTarget.none;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(p.latitude, p.longitude);
    await _m._fetchRoute();
    _fitCameraToOriginDestination();
    _m._collapseStops();
    _updateDestinationStreetLabel(p);
    _m._notifyDraftSearchCollapsedAfterBothStops();
  }

  Future<void> _fetchRoute() async {
    if (_m._destination == null || _m._origin == null) return;
    final token = ++_m._routeRequestToken;
    if (ref.read(tripRequestProvider).tripId == null) {
      ref.read(tripRequestProvider.notifier).clearQuote();
    }
    _m._autoQuoteRouteGeneration++;
    setState(() {
      _m._loadingRoute = true;
      _m._routePoints = null;
      _m._routeOverviewEncoded = null;
    });
    final plan = await _m._routeService.planDraftRoute(
      origin: _m._origin!,
      destination: _m._destination!,
    );
    if (!mounted) return;
    if (token != _m._routeRequestToken) return;
    if (plan == null) {
      setState(() {
        _m._routePoints = null;
        _m._routeOverviewEncoded = null;
        _m._loadingRoute = false;
      });
      return;
    }
    setState(() {
      _m._origin = plan.snappedOrigin;
      _m._destination = plan.snappedDestination;
      _m._routePoints = plan.points;
      _m._routeOverviewEncoded = plan.overviewEncoded;
      _m._loadingRoute = false;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setOrigin(plan.snappedOrigin.latitude, plan.snappedOrigin.longitude);
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(
          plan.snappedDestination.latitude,
          plan.snappedDestination.longitude,
        );
    unawaited(() async {
      if (plan.shouldUpdateOriginLabel) {
        await _updateOriginStreetLabel(plan.snappedOrigin);
      }
      if (plan.shouldUpdateDestinationLabel) {
        await _updateDestinationStreetLabel(plan.snappedDestination);
      }
    }());
    final routeGen = _m._autoQuoteRouteGeneration;
    Future<void>.delayed(const Duration(milliseconds: 420), () async {
      if (!mounted) return;
      if (routeGen != _m._autoQuoteRouteGeneration) return;
      if (ref.read(tripRequestProvider).tripId != null) return;
      if (_m._pickingOrigin || _m._pickingDestination) return;
      await _m._fetchQuote(openQuoteSheet: false);
    });
  }
}
