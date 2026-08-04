part of 'trip_request_screen.dart';

mixin _TripRequestScreenBootstrapMixin on _TripRequestScreenSyncMixin {
  @override
  _TripRequestScreenState get _d => this as _TripRequestScreenState;

  void initTripRequestScreen() {
    _d._appInForeground = true;
    _d._driverPulseController =
        AnimationController(
          vsync: _d,
          duration: const Duration(milliseconds: 1150),
        )..addListener(() {
          if (!mounted) return;
          if (_d._animatedDriverLatLng == null) return;
          setState(() {});
        });
    _d._searchingMapRadarController =
        AnimationController(
          vsync: _d,
          duration: const Duration(milliseconds: 2600),
        )..addListener(() {
          if (!mounted) return;
          // Solo rebuild cuando hay matching (evita trabajo en idle).
          final tid = ref.read(tripRequestProvider).tripId;
          final st = ref.read(passengerRealtimeProvider).status;
          if (tid == null || !passengerTripIsAwaitingDriverMatch(st)) return;
          setState(() {});
        });
    _d._chatAttentionController = AnimationController(
      vsync: _d,
      duration: const Duration(milliseconds: 1350),
    )..addListener(() {
      if (!mounted) return;
      if (_d._tripChatUnreadCount <= 0) return;
      setState(() {});
    });
    _d._originPlacesSessionToken = _newPlacesSessionToken();
    _d._destinationPlacesSessionToken = _newPlacesSessionToken();
    _d._draftPlacesSessionToken = _newPlacesSessionToken();
    registerDraftSearchFocusListener();
    WidgetsBinding.instance.addObserver(_d);
    passengerTripChatOpenBump.addListener(_onPassengerTripChatOpenBump);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadDriverTripIcon());
      unawaited(_probeGoogleMapsRestHealth());
      _onPassengerTripChatOpenBump();
      unawaited(_loadRecentPlaces());
      unawaited(_loadSavedPlaces());
      unawaited(_refreshBatteryLevel());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        final disclosuresOk = await passengerEnsurePlayDisclosuresBeforeTripFlow(
          context,
          l10n,
        );
        if (!disclosuresOk || !mounted) {
          setState(() {
            _d._loadingOrigin = false;
            _d._originError = l10n.homeLocationError;
          });
          return;
        }
      }

      final tripState = ref.read(tripRequestProvider);
      final rtState = ref.read(passengerRealtimeProvider);
      if (tripState.tripId != null && _d._ratingDoneTripId != tripState.tripId) {
        final activeTrip = tripState.tripId!;
        unawaited(() async {
          _d._ratingDoneTripId = activeTrip;
          _d._ratingDone = await TripSessionStorage.isRatingDone(activeTrip);
          if (!mounted) return;
          setState(() {});
        }());
      }

      if (tripState.tripId != null) {
        final activeTrip = tripState.tripId!;
        unawaited(() async {
          final cached = await TripSessionStorage.getCachedDriverInfo(
            activeTrip,
          );
          if (!mounted) return;
          if (cached == null) return;
          ref
              .read(passengerRealtimeProvider.notifier)
              .hydrateDriverInfoFromLocalCache(
                tripId: activeTrip,
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
        }());
      }

      final storedTripId = await TripSessionStorage.getActiveTripId();
      if (!mounted) return;

      if (storedTripId != null && storedTripId.isNotEmpty) {
        final currentTripId = ref.read(tripRequestProvider).tripId;
        if (currentTripId == null) {
          ref.read(tripRequestProvider.notifier).setTripId(storedTripId);
        } else if (currentTripId != storedTripId) {
          ref.read(tripRequestProvider.notifier).setTripId(storedTripId);
        }

        _d._ratingDoneTripId = storedTripId;
        _d._ratingDone = await TripSessionStorage.isRatingDone(storedTripId);
        if (!mounted) return;
        setState(() {});

        final lastStatus =
            await TripSessionStorage.getLastKnownStatus(storedTripId);
        if (!mounted) return;
        if (lastStatus != null &&
            (passengerTripIsTrackingDriver(lastStatus) ||
                lastStatus == 'completed' ||
                passengerTripIsAwaitingDriverMatch(lastStatus))) {
          ref
              .read(passengerRealtimeProvider.notifier)
              .hydrateStatusHintFromLocalCache(
                tripId: storedTripId,
                status: lastStatus,
              );
        }

        final uiSnap = await TripSessionStorage.getActiveTripUiSnapshot();
        if (!mounted) return;
        if (uiSnap != null && uiSnap['tripId']?.toString() == storedTripId) {
          _applyTripUiSnapshot(uiSnap);
          unawaited(_refreshPassengerGpsDot(preserveTripGeometry: true));
        } else {
          _resolveOrigin();
        }

        await ref
            .read(passengerRealtimeProvider.notifier)
            .syncTripStatusFromApi(tripId: storedTripId, force: true);

        if (mounted &&
            _d._destination != null &&
            passengerTripIsEnRouteToDestination(
              ref.read(passengerRealtimeProvider).status,
            )) {
          _schedulePassengerEnRouteRouteRefresh(immediate: true);
        }

        final cached = await TripSessionStorage.getCachedDriverInfo(
          storedTripId,
        );
        if (cached != null && mounted) {
          ref
              .read(passengerRealtimeProvider.notifier)
              .hydrateDriverInfoFromLocalCache(
                tripId: storedTripId,
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

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final tid = ref.read(tripRequestProvider).tripId;
            if (tid == null || tid.isEmpty) return;
            final rtStatus = ref.read(passengerRealtimeProvider).status;
            if (!passengerTripIsAwaitingDriverMatch(rtStatus)) {
              showTripRecoveredSnackBarOncePerTrip(ref, context, tid);
            }
            unawaited(_d._ensureTripNotificationDisclosure());
          });
        }

        final latestTrip = ref.read(tripRequestProvider);
        final rt = ref.read(passengerRealtimeProvider);
        if (!rt.connected && !rt.connecting) {
          ref
              .read(passengerRealtimeProvider.notifier)
              .connect(tripId: storedTripId, quote: latestTrip.quote);
        }
        return;
      }

      if (tripState.tripId != null &&
          !rtState.connected &&
          !rtState.connecting &&
          rtState.errorCode == null) {
        final tripId = tripState.tripId!;
        unawaited(() async {
          await ref
              .read(passengerRealtimeProvider.notifier)
              .syncTripStatusFromApi(tripId: tripId, force: true);
          if (!mounted) return;
          ref
              .read(passengerRealtimeProvider.notifier)
              .connect(tripId: tripId, quote: tripState.quote);
        }());
      }
      if (tripState.origin != null) {
        _d._origin = LatLng(tripState.origin!.lat, tripState.origin!.lng);
        _d._mapCenter = _d._origin;
        _d._loadingOrigin = false;
        _d._originError = null;
        if (tripState.destination != null) {
          _d._originConfirmed = true;
          _d._pickingOrigin = false;
          _d._pickingDestination = false;
          _d._activeStop = ActiveStop.none;
          _d._destination = LatLng(
            tripState.destination!.lat,
            tripState.destination!.lng,
          );
          _d._mapCenter = _d._destination;
          _fetchRoute();
        } else {
          _d._originConfirmed = false;
          _d._pickingOrigin = true;
          _d._pickingDestination = false;
          _d._activeStop = ActiveStop.none;
        }
        _loadPinIcons();
        setState(() {});
        return;
      }
      if (widget.originLat != null && widget.originLng != null) {
        _d._origin = LatLng(widget.originLat!, widget.originLng!);
        _d._mapCenter = _d._origin;
        _d._loadingOrigin = false;
        ref
            .read(tripRequestProvider.notifier)
            .setOrigin(_d._origin!.latitude, _d._origin!.longitude);
        _d._originConfirmed = false;
        _d._pickingOrigin = true;
        _d._pickingDestination = false;
        _d._activeStop = ActiveStop.none;
        _loadPinIcons();
        setState(() {});
        return;
      }
      _resolveOrigin();
    });
    _d._loadingOrigin = true;
  }

  Future<void> _probeGoogleMapsRestHealth() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final probe = await PassengerGoogleMapsHealth.probe();
    if (!mounted || probe.ok) return;
    setState(() {
      _d._error = probe.missingApiKey
          ? l10n.tripMapsRestKeyMissing
          : (probe.status == 'REQUEST_DENIED'
              ? l10n.tripMapsRestKeyDenied
              : l10n.tripMapsRestUnavailable);
    });
  }

  void disposeTripRequestScreen() {
    _d._passengerEnRouteRouteDebounce?.cancel();
    _d._driverMotionTimer?.cancel();
    _d._searchingNearbyTimer?.cancel();
    _d._driverPulseController.dispose();
    _d._searchingMapRadarController.dispose();
    _d._chatAttentionController.dispose();
    _d._draftSearchDebounce?.cancel();
    _d._mapConfirmIdleTimer?.cancel();
    _d._draftSearchController.dispose();
    _d._draftSearchFocus.dispose();
    _d._tripStatusSyncTimer?.cancel();
    _d._tripStatusSyncTimer = null;
    _d._tripStatusSyncTimerTripId = null;
    _d._tripStatusSyncInterval = const Duration(seconds: 60);
    WidgetsBinding.instance.removeObserver(_d);
    passengerTripChatOpenBump.removeListener(_onPassengerTripChatOpenBump);
    _d._controller?.dispose();
  }
}
