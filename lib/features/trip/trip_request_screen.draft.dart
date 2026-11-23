part of 'trip_request_screen.dart';

enum _PassengerLeaveSheetHeader { close, back }

mixin _TripRequestScreenDraftMixin on _TripRequestScreenOverlaysMixin {
  @override
  _TripRequestScreenState get _d => this as _TripRequestScreenState;

  void registerDraftSearchFocusListener() {
    _d._draftSearchFocus.addListener(() {
      if (!mounted) return;
      final hasFocus = _d._draftSearchFocus.hasFocus;
      if (_d._lastDraftSearchFocusState == hasFocus) return;
      _d._lastDraftSearchFocusState = hasFocus;
      setState(() {});
    });
  }

  PassengerDraftSearchRole get _draftSearchPhase {
    if (_d._draftEditTarget == PassengerDraftEditTarget.origin) {
      return PassengerDraftSearchRole.origin;
    }
    if (_d._draftEditTarget == PassengerDraftEditTarget.destination) {
      return PassengerDraftSearchRole.destination;
    }
    return _d._originConfirmed
        ? PassengerDraftSearchRole.destination
        : PassengerDraftSearchRole.origin;
  }

  bool get _draftLocationSearchChromeVisible {
    if (!_d._originConfirmed) return true;
    if (_d._destination == null) return true;
    if (_d._draftEditTarget != PassengerDraftEditTarget.none) return true;
    return false;
  }

  void _assignOriginFollowState() {
    _d._originEditAnchor = null;
    _d._originPinAdjusted = true;
    _d._originResolveGeneration++;
    _d._draftEditTarget = PassengerDraftEditTarget.none;
    _d._pickingDestination = false;
    _d._activeStop = ActiveStop.none;
    if (_d._destination == null) {
      _d._originConfirmed = false;
      _d._pickingOrigin = true;
    } else {
      _d._originConfirmed = true;
      _d._pickingOrigin = false;
    }
  }

  String _resolveDraftOriginDisplayLine(AppLocalizations l10n) {
    final followPin =
        _d._pickingOrigin || (!_d._originConfirmed && _d._destination == null);
    if (followPin) {
      final locked = _d._originDisplayLabel?.trim();
      final origin = _d._origin;
      final center = _d._mapCenter;
      if (origin != null &&
          center != null &&
          locked != null &&
          locked.isNotEmpty) {
        final movedM = Geolocator.distanceBetween(
          origin.latitude,
          origin.longitude,
          center.latitude,
          center.longitude,
        );
        if (movedM < _kLiveOriginHoldMeters) return locked;
      }
      final preview = _d._mapNeedleAddressPreview?.trim();
      if (preview != null && preview.isNotEmpty) return preview;
    }
    return _d._originDisplayLabel ?? l10n.tripYourLocation;
  }

  String _resolveDraftDestinationDisplayLine(AppLocalizations l10n) {
    final isPickingDest =
        _d._pickingDestination ||
        (_d._destinationMapPickArmed &&
            _d._originConfirmed &&
            _d._destination == null &&
            _d._activeStop == ActiveStop.none);
    if (isPickingDest) {
      final preview = _d._mapNeedleAddressPreview?.trim();
      if (preview != null && preview.isNotEmpty) return preview;
    }
    if (_d._destination != null) {
      return _d._destinationDisplayLabel ??
          '${_d._destination!.latitude.toStringAsFixed(4)}, ${_d._destination!.longitude.toStringAsFixed(4)}';
    }
    return l10n.tripTapMapDestination;
  }

  void _onDraftOpenSearchForOrigin() {
    TexiUiFeedback.lightTap();
    if (!mounted) return;
    _d._mapConfirmIdleTimer?.cancel();
    setState(() {
      _d._draftEditTarget = PassengerDraftEditTarget.origin;
      _holdSettledMapConfirm(PassengerDraftEditTarget.origin);
      _d._mapConfirmInstructionHiddenWhileDragging = false;
      _d._draftSearchExpandToken++;
    });
  }

  void _holdSettledMapConfirm(PassengerDraftEditTarget target) {
    final bothReady = _d._originConfirmed && _d._destination != null;
    if (!bothReady) {
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
      return;
    }
    _d._pickingOrigin = target == PassengerDraftEditTarget.origin;
    _d._pickingDestination = target == PassengerDraftEditTarget.destination;
    _d._destinationMapPickArmed = false;
    _d._activeStop = ActiveStop.none;
  }

  void _onDraftDestinationSectionPressed() {
    if (!mounted) return;
    if (_d._originConfirmed && _d._destination != null) {
      _onDraftOpenSearchForDestination();
      return;
    }
    final editingLiveOrigin = _d._pickingOrigin && _d._originConfirmed;
    final mustLock = !_d._originConfirmed || editingLiveOrigin;
    if (mustLock) {
      if (_d._mapCenter == null && _d._origin == null) return;
      TexiUiFeedback.lightTap();
      _lockOriginAtPin(openDestinationSearch: true);
      return;
    }
    _onDraftOpenSearchForDestination();
  }

  void _onDraftChooseDestinationOnMap() {
    TexiUiFeedback.lightTap();
    if (!mounted || !_d._originConfirmed) return;
    _d._mapConfirmIdleTimer?.cancel();
    _d._draftSearchFocus.unfocus();
    final focus = _d._mapCenter ?? _d._origin;
    setState(() {
      _d._draftSearchCollapseToken++;
      _d._draftSuggestions = const <PlaceSuggestion>[];
      _d._loadingDraftSuggestions = false;
      _d._draftEditTarget = PassengerDraftEditTarget.none;
      _d._destinationMapPickArmed = true;
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
      _d._activeStop = ActiveStop.none;
      _d._mapConfirmInstructionHiddenWhileDragging = false;
      if (focus != null) _d._mapCenter = focus;
    });
    if (_d._draftSearchController.text.isNotEmpty) {
      _d._draftSearchController.clear();
    }
  }

  void _onDraftOpenSearchForDestination() {
    TexiUiFeedback.lightTap();
    if (!mounted || !_d._originConfirmed) return;
    _d._mapConfirmIdleTimer?.cancel();
    setState(() {
      _d._draftEditTarget = PassengerDraftEditTarget.destination;
      _holdSettledMapConfirm(PassengerDraftEditTarget.destination);
      _d._mapConfirmInstructionHiddenWhileDragging = false;
      _d._draftSearchExpandToken++;
    });
  }

  void _notifyDraftSearchCollapsedAfterBothStops() {
    if (!_d._originConfirmed || _d._destination == null) return;
    final hadExpandedChrome = _draftLocationSearchChromeVisible;
    if (hadExpandedChrome) {
      TexiUiFeedback.softImpact();
    }
    _d._draftSearchFocus.unfocus();
    _d._draftSearchController.clear();
    _afterDraftLocationPicked();
    if (!mounted) return;
    setState(() {
      _d._draftEditTarget = PassengerDraftEditTarget.none;
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
    });
  }

  void _onDraftEditOriginPressed() {
    TexiUiFeedback.lightTap();
    if (!mounted) return;
    final o = _d._origin;
    if (o == null) return;
    _d._mapConfirmIdleTimer?.cancel();
    _d._draftSearchFocus.unfocus();
    setState(() {
      _d._draftSearchCollapseToken++;
      _d._draftEditTarget = PassengerDraftEditTarget.origin;
      _d._pickingOrigin = true;
      _d._pickingDestination = false;
      _d._activeStop = ActiveStop.none;
      _d._originEditAnchor = o;
      _d._mapCenter = o;
      _d._mapConfirmInstructionHiddenWhileDragging = false;
      _d._mapNeedleAddressPreview = _d._originDisplayLabel;
    });
    _d._controller?.animateCamera(CameraUpdate.newLatLngZoom(o, 16));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshNeedlePreviewFromMapCenter());
    });
  }

  void _onDraftEditDestinationPressed() {
    TexiUiFeedback.lightTap();
    if (!mounted) return;
    final d = _d._destination;
    if (d == null) return;
    _d._mapConfirmIdleTimer?.cancel();
    _d._draftSearchFocus.unfocus();
    setState(() {
      _d._draftSearchCollapseToken++;
      _d._draftEditTarget = PassengerDraftEditTarget.destination;
      _d._pickingDestination = true;
      _d._pickingOrigin = false;
      _d._activeStop = ActiveStop.none;
      _d._mapCenter = d;
      _d._mapConfirmInstructionHiddenWhileDragging = false;
      _d._mapNeedleAddressPreview = _d._destinationDisplayLabel;
    });
    _d._controller?.animateCamera(CameraUpdate.newLatLngZoom(d, 16));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshNeedlePreviewFromMapCenter());
    });
  }

  String _ensureSavedPlaceLabel(
    String primary,
    String backupMin2,
    AppLocalizations l10n,
  ) {
    var a = primary.trim();
    if (a.length > 60) a = a.substring(0, 60);
    if (a.length >= 2) return a;
    var b = backupMin2.trim();
    if (b.length > 60) b = b.substring(0, 60);
    if (b.length >= 2) return b;
    return l10n.tripSavedPlaceFallbackLabel;
  }

  String _ensureSavedPlaceAddress(String primary, double lat, double lng) {
    final a = primary.trim();
    if (a.length > 180) return a.substring(0, 180);
    if (a.length >= 3) return a;
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  void _pickOriginRecentPlace(TripRecentPlaceItem place) {
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _d._origin = p;
      _d._originDisplayLabel = place.label;
      _d._originDriverAddress = null;
      _d._routePoints = null;
      _d._mapNeedleAddressPreview = place.label;
      _assignOriginFollowState();
    });
    ref.read(tripRequestProvider.notifier).setOrigin(p.latitude, p.longitude);
    _d._controller?.animateCamera(CameraUpdate.newLatLng(p));
    if (_d._destination != null) {
      unawaited(_fetchRoute());
      _notifyDraftSearchCollapsedAfterBothStops();
    } else {
      unawaited(_updateOriginStreetLabel(p));
    }
  }

  void _pickDestinationRecentPlace(TripRecentPlaceItem place) {
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _d._destination = p;
      _d._destinationDisplayLabel = place.label;
      _d._destinationDriverAddress = null;
      _d._destinationPoiLabelLocked = true;
      _d._routePoints = null;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(p.latitude, p.longitude);
    _d._controller?.animateCamera(CameraUpdate.newLatLng(p));
    _fetchRoute();
    _fitCameraToOriginDestination();
    _collapseStops();
    _notifyDraftSearchCollapsedAfterBothStops();
  }

  Future<void> _pickOriginSavedPlace(TripSavedPlaceItem place) async {
    final resolved = await _resolveSavedPlaceCopy(place);
    if (!mounted) return;
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _d._origin = p;
      _d._originDisplayLabel = resolved.display;
      _d._originDriverAddress = resolved.driver;
      _d._routePoints = null;
      _d._mapNeedleAddressPreview = resolved.display;
      _assignOriginFollowState();
    });
    ref.read(tripRequestProvider.notifier).setOrigin(p.latitude, p.longitude);
    _d._controller?.animateCamera(CameraUpdate.newLatLng(p));
    if (_d._destination != null) {
      unawaited(_fetchRoute());
      _notifyDraftSearchCollapsedAfterBothStops();
    } else {
      unawaited(_updateOriginStreetLabel(p));
    }
  }

  Future<void> _pickDestinationSavedPlace(TripSavedPlaceItem place) async {
    final resolved = await _resolveSavedPlaceCopy(place);
    if (!mounted) return;
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _d._destination = p;
      _d._destinationDisplayLabel = resolved.display;
      _d._destinationDriverAddress = resolved.driver;
      _d._destinationPoiLabelLocked = true;
      _d._routePoints = null;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(p.latitude, p.longitude);
    _d._controller?.animateCamera(CameraUpdate.newLatLng(p));
    _fetchRoute();
    _fitCameraToOriginDestination();
    _collapseStops();
    _notifyDraftSearchCollapsedAfterBothStops();
  }

  Future<({String display, String driver})> _resolveSavedPlaceCopy(
    TripSavedPlaceItem place,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reference = HomeQuickSlots.savedPlaceReferenceName(place.label, l10n);
    var street = HomeQuickSlots.savedPlaceStreet(
      place.address,
      reference: reference,
    );
    street ??= HomeQuickSlots.savedPlaceStreet(
      await _d._geocoding.reverseGeocodeStreet(lat: place.lat, lng: place.lng),
      reference: reference,
    );
    final driver = HomeQuickSlots.savedPlaceDriverAddress(
      street: street,
      lat: place.lat,
      lng: place.lng,
    );
    final display = HomeQuickSlots.savedPlacePassengerLabel(
      reference: reference,
      streetOrCoords: driver,
    );
    return (display: display, driver: driver);
  }

  Future<void> _saveCurrentOriginPlace() async {
    if (_d._origin == null) return;
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final rawLabel = (_d._originDisplayLabel ?? l10n.tripOrigin)
        .split(',')
        .first
        .trim();
    final rawAddress =
        (_d._originDisplayLabel ??
                '${_d._origin!.latitude.toStringAsFixed(6)},${_d._origin!.longitude.toStringAsFixed(6)}')
            .trim();
    final label = _ensureSavedPlaceLabel(rawLabel, l10n.tripOrigin, l10n);
    final address = _ensureSavedPlaceAddress(
      rawAddress,
      _d._origin!.latitude,
      _d._origin!.longitude,
    );
    try {
      await TripsApi(token: token).savePassengerPlace(
        label: label.isNotEmpty ? label : l10n.tripOrigin,
        address: address,
        lat: _d._origin!.latitude,
        lng: _d._origin!.longitude,
      );
      if (!mounted) return;
      _showSubtleSnack(l10n.tripSavedPlaceSaved);
    } catch (_) {
      if (!mounted) return;
      _showSubtleSnack(l10n.commonError);
    }
  }

  Future<void> _saveCurrentDestinationPlace() async {
    if (_d._destination == null) return;
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final rawLabel = (_d._destinationDisplayLabel ?? l10n.tripDestination)
        .split(',')
        .first
        .trim();
    final rawAddress =
        (_d._destinationDisplayLabel ??
                '${_d._destination!.latitude.toStringAsFixed(6)},${_d._destination!.longitude.toStringAsFixed(6)}')
            .trim();
    final label = _ensureSavedPlaceLabel(rawLabel, l10n.tripDestination, l10n);
    final address = _ensureSavedPlaceAddress(
      rawAddress,
      _d._destination!.latitude,
      _d._destination!.longitude,
    );
    try {
      await TripsApi(token: token).savePassengerPlace(
        label: label.isNotEmpty ? label : l10n.tripDestination,
        address: address,
        lat: _d._destination!.latitude,
        lng: _d._destination!.longitude,
      );
      if (!mounted) return;
      _showSubtleSnack(l10n.tripSavedPlaceSaved);
    } catch (_) {
      if (!mounted) return;
      _showSubtleSnack(l10n.commonError);
    }
  }

  Future<void> _openSavedPlacesManager({required bool forOrigin}) async {
    final result = await context.pushNamed(
      AppRouter.savedPlaces,
      queryParameters: {'purpose': forOrigin ? 'origin' : 'destination'},
    );
    if (!mounted || result is! PassengerSavedPlace) return;
    final item = TripSavedPlaceItem(
      id: result.id,
      label: result.label,
      address: result.address,
      lat: result.lat,
      lng: result.lng,
      isFavorite: result.isFavorite,
    );
    if (forOrigin) {
      await _pickOriginSavedPlace(item);
    } else {
      await _pickDestinationSavedPlace(item);
    }
    _afterDraftLocationPicked();
  }

  String _newPlacesSessionToken() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now ^ (now >> 7) ^ (now << 11);
    return '$now$random';
  }

  void _afterDraftLocationPicked() {
    _d._draftSearchFocus.unfocus();
    _d._draftSearchController.clear();
    if (!mounted) return;
    setState(() {
      _d._draftSearchCollapseToken++;

      _d._draftEditTarget = PassengerDraftEditTarget.none;
      _d._draftSuggestions = const <PlaceSuggestion>[];
      _d._loadingDraftSuggestions = false;
    });
    _d._draftPlacesSessionToken = _newPlacesSessionToken();
  }

  void _onDraftSearchChanged(String query) {
    if (mounted) setState(() {});
    _d._draftSearchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < PlacesAutocompleteService.minQueryLength) {
      if (!mounted) return;
      setState(() {
        _d._draftSuggestions = const <PlaceSuggestion>[];
        _d._loadingDraftSuggestions = false;
      });
      return;
    }
    _d._draftSearchDebounce = Timer(
      const Duration(milliseconds: 350),
      () async {
        if (!mounted) return;
        setState(() => _d._loadingDraftSuggestions = true);
        final center = _draftSearchPhase == PassengerDraftSearchRole.origin
            ? (_d._mapCenter ?? _d._origin)
            : (_d._mapCenter ?? _d._destination ?? _d._origin);
        final result = await _d._places.fetchSuggestions(
          query: trimmed,
          sessionToken: _d._draftPlacesSessionToken,
          nearLat: center?.latitude,
          nearLng: center?.longitude,
        );
        if (!mounted) return;
        setState(() {
          _d._draftSuggestions = result;
          _d._loadingDraftSuggestions = false;
        });
      },
    );
  }

  Future<void> _pickDraftSuggestion(PlaceSuggestion s) async {
    if (_draftSearchPhase == PassengerDraftSearchRole.origin) {
      await _selectOriginSuggestion(s, null);
    } else {
      await _selectDestinationSuggestion(s, null);
    }
    _afterDraftLocationPicked();
  }

  void _pickDraftRecent(TripRecentPlaceItem place) {
    if (_draftSearchPhase == PassengerDraftSearchRole.origin) {
      _pickOriginRecentPlace(place);
    } else {
      _pickDestinationRecentPlace(place);
    }
    _afterDraftLocationPicked();
  }

  void _onDraftMyLocationIconTap() {
    if (_draftSearchPhase == PassengerDraftSearchRole.origin) {
      unawaited(_setOriginFromCurrentLocation());
    } else {
      unawaited(_setDestinationFromCurrentLocation());
    }
  }

  void _onDraftSavedIconTap() {
    unawaited(
      _openSavedPlacesManager(
        forOrigin: _draftSearchPhase == PassengerDraftSearchRole.origin,
      ),
    );
  }

  Future<void> _submitInlineTripRequest() async {
    final tripState = ref.read(tripRequestProvider);
    final q = tripState.quote;
    final opt = tripState.selectedOption;
    if (q == null ||
        opt == null ||
        _d._origin == null ||
        _d._destination == null) {
      return;
    }

    setState(() {
      _d._submittingTrip = true;
      _d._matchingSubmitUi = true;
    });
    final submitGeneration = _d._tripSubmitGeneration;
    final l10n = AppLocalizations.of(context)!;
    final originAddress =
        (_d._originDisplayLabel != null &&
            _d._originDisplayLabel!.trim().isNotEmpty)
        ? _d._originDisplayLabel!.trim()
        : '${_d._origin!.latitude.toStringAsFixed(6)},${_d._origin!.longitude.toStringAsFixed(6)}';
    final destinationAddress =
        (_d._destinationDisplayLabel != null &&
            _d._destinationDisplayLabel!.trim().isNotEmpty)
        ? _d._destinationDisplayLabel!.trim()
        : '${_d._destination!.latitude.toStringAsFixed(6)},${_d._destination!.longitude.toStringAsFixed(6)}';

    final result = await submitPassengerTripFromQuote(
      ref: ref,
      context: context,
      quote: q,
      option: opt,
      originLat: _d._origin!.latitude,
      originLng: _d._origin!.longitude,
      destinationLat: _d._destination!.latitude,
      destinationLng: _d._destination!.longitude,
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      routeOverviewEncoded: _d._routeOverviewEncoded,
      ensureDeviceGpsForNewTrip: _ensureDeviceGpsForNewTrip,
    );
    if (!mounted) return;
    if (await _discardSubmitIfGenerationChanged(
      generation: submitGeneration,
      result: result,
    )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _d._submittingTrip = false;
      _d._matchingSubmitUi = false;
    });
    if (result.kind == PassengerTripSubmitResultKind.success ||
        result.kind == PassengerTripSubmitResultKind.recoveredExisting) {
      return;
    }
    if (result.kind == PassengerTripSubmitResultKind.phoneRequired) {
      setState(() => _d._error = null);
      await handlePassengerTripPhoneRequired(
        context,
        ref,
        result.kind,
        returnTo: 'trip_request',
      );
      return;
    }
    final msg = result.message ?? l10n.tripRequestUnavailable;
    if (msg == l10n.tripNoDriversAvailable) {
      PassengerTripToast.show(
        context,
        message: msg,
        icon: Icons.directions_car_outlined,
        accent: AppColors.primary,
      );
      setState(() => _d._error = null);
      return;
    }
    setState(() {
      _d._error = msg;
    });
  }

  String _composePlaceLabel(PlaceSuggestion suggestion, String formatted) {
    final main = suggestion.mainText.trim();
    final addr = formatted.trim();
    if (main.isEmpty) return addr;
    if (addr.isEmpty) return main;
    final mainLower = main.toLowerCase();
    final addrLower = addr.toLowerCase();
    if (addrLower.startsWith(mainLower)) return addr;
    return '$main \u00B7 $addr';
  }

  Future<void> _selectOriginSuggestion(
    PlaceSuggestion suggestion,
    BuildContext? sheetContext,
  ) async {
    setState(() => _d._searchingOriginAddress = true);
    final details = await _d._places.fetchPlaceDetails(
      placeId: suggestion.placeId,
      sessionToken: _d._originPlacesSessionToken,
    );
    _d._originPlacesSessionToken = _newPlacesSessionToken();
    if (!mounted) return;
    if (sheetContext != null && !sheetContext.mounted) return;
    if (details == null) {
      setState(() => _d._searchingOriginAddress = false);
      await _searchAndSetOrigin(suggestion.fullText, sheetContext);
      return;
    }
    final composedLabel = details.formattedAddress.isNotEmpty
        ? _composePlaceLabel(suggestion, details.formattedAddress)
        : suggestion.fullText;

    final hasPoiName = composedLabel.contains(' \u00B7 ');
    setState(() {
      _d._origin = LatLng(details.lat, details.lng);
      _d._originDisplayLabel = composedLabel;
      _d._originDriverAddress = null;
      _d._mapCenter = _d._origin;
      _d._routePoints = null;
      _d._searchingOriginAddress = false;
      _d._mapNeedleAddressPreview = composedLabel;
      _assignOriginFollowState();
    });
    ref.read(tripRequestProvider.notifier).setOrigin(details.lat, details.lng);
    _d._controller?.animateCamera(
      CameraUpdate.newLatLng(LatLng(details.lat, details.lng)),
    );
    if (_d._destination != null) _fetchRoute();
    if (sheetContext != null && sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }
    if (!hasPoiName) {
      unawaited(_updateOriginStreetLabel(LatLng(details.lat, details.lng)));
    }
    if (_d._destination != null) {
      _notifyDraftSearchCollapsedAfterBothStops();
    }
  }

  Future<void> _selectDestinationSuggestion(
    PlaceSuggestion suggestion,
    BuildContext? sheetContext,
  ) async {
    setState(() => _d._searchingDestinationAddress = true);
    final details = await _d._places.fetchPlaceDetails(
      placeId: suggestion.placeId,
      sessionToken: _d._destinationPlacesSessionToken,
    );
    _d._destinationPlacesSessionToken = _newPlacesSessionToken();
    if (!mounted) return;
    if (sheetContext != null && !sheetContext.mounted) return;
    if (details == null) {
      setState(() => _d._searchingDestinationAddress = false);
      await _searchAndSetDestination(suggestion.fullText, sheetContext);
      return;
    }
    setState(() {
      _d._destination = LatLng(details.lat, details.lng);
      _d._destinationDisplayLabel = details.formattedAddress.isNotEmpty
          ? _composePlaceLabel(suggestion, details.formattedAddress)
          : suggestion.fullText;
      _d._destinationDriverAddress = null;
      _d._destinationPoiLabelLocked = true;
      _d._routePoints = null;
      _d._searchingDestinationAddress = false;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(details.lat, details.lng);
    _d._controller?.animateCamera(
      CameraUpdate.newLatLng(LatLng(details.lat, details.lng)),
    );
    _fetchRoute();
    if (sheetContext != null && sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }
    _fitCameraToOriginDestination();
    _collapseStops();
    _notifyDraftSearchCollapsedAfterBothStops();
  }

  Future<void> _searchAndSetOrigin(
    String query,
    BuildContext? sheetContext,
  ) async {
    if (query.isEmpty) return;
    setState(() => _d._searchingOriginAddress = true);
    try {
      final result = await _d._geocoding.searchAddress(query);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _d._searchingOriginAddress = false;
          _d._error = AppLocalizations.of(context)!.tripSearchError;
        });
        if (sheetContext != null && sheetContext.mounted) {
          Navigator.pop(sheetContext);
        }
        return;
      }
      setState(() {
        _d._origin = LatLng(result.lat, result.lng);
        _d._originDisplayLabel = result.formattedAddress ?? query;
        _d._originDriverAddress = null;
        _d._mapCenter = _d._origin;
        _d._searchingOriginAddress = false;
        _d._routePoints = null;
        _d._mapNeedleAddressPreview = _d._originDisplayLabel;
        _assignOriginFollowState();
      });
      ref.read(tripRequestProvider.notifier).setOrigin(result.lat, result.lng);
      _d._controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(result.lat, result.lng)),
      );
      if (_d._destination != null) _fetchRoute();
      if (sheetContext != null && sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
      unawaited(_updateOriginStreetLabel(LatLng(result.lat, result.lng)));
      if (_d._destination != null) {
        _notifyDraftSearchCollapsedAfterBothStops();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _d._searchingOriginAddress = false;
          _d._error = AppLocalizations.of(context)!.tripSearchError;
        });
        if (sheetContext != null && sheetContext.mounted) {
          Navigator.pop(sheetContext);
        }
      }
    }
  }

  Future<void> _setOriginFromCurrentLocation() async {
    setState(() => _d._loadingOrigin = true);

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {
        position = null;
      }
    }
    if (!mounted) return;
    if (position == null) {
      setState(() {
        _d._loadingOrigin = false;
        _d._error = AppLocalizations.of(context)!.homeLocationErrorGps;
      });
      return;
    }
    setState(() {
      _d._error = null;
      _d._origin = LatLng(position!.latitude, position.longitude);
      _d._originDisplayLabel = null;
      _d._originDriverAddress = null;
      _d._mapCenter = _d._origin;
      _d._loadingOrigin = false;
      _d._routePoints = null;
      _d._deviceGpsFixOk = true;
      _d._mapNeedleAddressPreview = null;
      _assignOriginFollowState();
    });
    ref
        .read(tripRequestProvider.notifier)
        .setOrigin(position.latitude, position.longitude);
    _d._controller?.animateCamera(CameraUpdate.newLatLng(_d._origin!));
    if (_d._destination != null) _fetchRoute();
    unawaited(_updateOriginStreetLabel(_d._origin!));
    if (_d._destination != null) {
      _notifyDraftSearchCollapsedAfterBothStops();
    }
  }

  Future<void> _showProfileMenu(BuildContext context, {Offset? anchor}) async {
    final size = MediaQuery.sizeOf(context);
    final resolvedAnchor = anchor ?? Offset(size.width - 40, size.height - 120);
    final action = await showPassengerFanMenu(
      context: context,
      anchorGlobal: resolvedAnchor,
      showHome: ref.read(tripRequestProvider).tripId == null,
    );
    if (!context.mounted || action == null) return;

    switch (action) {
      case PassengerFanMenuAction.home:
        context.goNamed(AppRouter.home);
      case PassengerFanMenuAction.safety:
        context.pushNamed(AppRouter.safetyHub);
      case PassengerFanMenuAction.operator:
        context.pushNamed(AppRouter.operatorTexi);
      case PassengerFanMenuAction.profile:
        context.pushNamed(AppRouter.passengerProfile);
      case PassengerFanMenuAction.history:
        context.pushNamed(AppRouter.tripHistory);
      case PassengerFanMenuAction.logout:
        await _confirmLeaveOrLogout(context);
    }
  }

  Future<void> _confirmLeaveOrLogout(BuildContext context) async {
    while (context.mounted) {
      final choice = await _showLeaveAppSheet(context);
      if (!context.mounted || choice == null) return;
      if (choice == 'exit') {
        await SystemNavigator.pop();
        if (Platform.isAndroid || Platform.isIOS) {
          exit(0);
        }
        return;
      }
      if (choice != 'logout') return;

      final logoutChoice = await _showLogoutConfirmSheet(context);
      if (!context.mounted) return;
      if (logoutChoice == 'logout') {
        await AuthService.logout();
        if (!context.mounted) return;
        context.goNamed(AppRouter.login);
        return;
      }
      if (logoutChoice == 'back') {
        continue;
      }
      return;
    }
  }

  Future<String?> _showLeaveAppSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _showPassengerLeaveSheet(
      context: context,
      icon: Icons.waving_hand_rounded,
      title: l10n.menuLeaveAppTitle,
      message: l10n.menuLeaveAppMessage,
      primaryLabel: l10n.menuLeaveAppConfirm,
      primaryValue: 'exit',

      headerControl: _PassengerLeaveSheetHeader.close,
      secondaryLabel: l10n.menuLeaveAppLogout,
      secondaryValue: 'logout',
    );
  }

  Future<String?> _showLogoutConfirmSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _showPassengerLeaveSheet(
      context: context,
      icon: Icons.logout_rounded,
      title: l10n.menuLogoutConfirmTitle,
      message: l10n.menuLogoutConfirmMessage,
      primaryLabel: l10n.menuLogoutConfirmAction,
      primaryValue: 'logout',
      primaryDanger: true,

      headerControl: _PassengerLeaveSheetHeader.back,
      headerBackValue: 'back',
    );
  }

  Future<String?> _showPassengerLeaveSheet({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    required String primaryValue,
    required _PassengerLeaveSheetHeader headerControl,
    String? secondaryLabel,
    String? secondaryValue,
    String headerBackValue = 'back',
    bool primaryDanger = false,
  }) {
    assert(
      (secondaryLabel == null) == (secondaryValue == null),
      'secondaryLabel y secondaryValue van juntos',
    );
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        if (headerControl == _PassengerLeaveSheetHeader.back)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: MaterialLocalizations.of(
                                ctx,
                              ).backButtonTooltip,
                              onPressed: () =>
                                  Navigator.pop(ctx, headerBackValue),
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: AppColors.textPrimary,
                            ),
                          ),
                        if (headerControl == _PassengerLeaveSheetHeader.close)
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: MaterialLocalizations.of(
                                ctx,
                              ).closeButtonTooltip,
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded),
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                (primaryDanger
                                        ? const Color(0xFFE05140)
                                        : AppColors.primary)
                                    .withValues(alpha: 0.14),
                          ),
                          child: Icon(
                            icon,
                            color: primaryDanger
                                ? const Color(0xFFE05140)
                                : AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.95,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, primaryValue),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryDanger
                                ? const Color(0xFFE05140)
                                : AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            primaryLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (secondaryLabel != null &&
                            secondaryValue != null) ...[
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, secondaryValue),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary
                                  .withValues(alpha: 0.72),
                            ),
                            child: Text(
                              secondaryLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _searchAndSetDestination(
    String query,
    BuildContext? sheetContext,
  ) async {
    if (query.isEmpty) return;
    setState(() => _d._searchingDestinationAddress = true);
    try {
      final result = await _d._geocoding.searchAddress(query);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _d._searchingDestinationAddress = false;
          _d._error = AppLocalizations.of(context)!.tripSearchError;
        });
        if (sheetContext != null && sheetContext.mounted) {
          Navigator.pop(sheetContext);
        }
        return;
      }
      setState(() {
        _d._destination = LatLng(result.lat, result.lng);
        _d._destinationDisplayLabel = result.formattedAddress ?? query;
        _d._destinationDriverAddress = null;
        _d._destinationPoiLabelLocked = true;
        _d._routePoints = null;
      });
      ref
          .read(tripRequestProvider.notifier)
          .setDestination(result.lat, result.lng);
      _d._controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(result.lat, result.lng)),
      );
      _fetchRoute();
      if (sheetContext != null && sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
      _fitCameraToOriginDestination();
      _collapseStops();
      _notifyDraftSearchCollapsedAfterBothStops();
    } catch (_) {
      if (mounted) {
        setState(() {
          _d._searchingDestinationAddress = false;
          _d._error = AppLocalizations.of(context)!.tripSearchError;
        });
        if (sheetContext != null && sheetContext.mounted) {
          Navigator.pop(sheetContext);
        }
      }
    } finally {
      if (mounted) setState(() => _d._searchingDestinationAddress = false);
    }
  }

  Future<void> _setDestinationFromCurrentLocation() async {

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: _passengerPickupLocationSettings(),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {
        position = null;
      }
    }
    if (!mounted) return;
    if (position == null) {
      setState(
        () => _d._error = AppLocalizations.of(context)!.homeLocationErrorGps,
      );
      return;
    }
    setState(() {
      _d._error = null;
      _d._destination = LatLng(position!.latitude, position.longitude);
      _d._destinationDisplayLabel = null;
      _d._destinationDriverAddress = null;
      _d._destinationPoiLabelLocked = false;
      _d._routePoints = null;
      _d._deviceGpsFixOk = true;
      _d._draftEditTarget = PassengerDraftEditTarget.none;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(position.latitude, position.longitude);
    _d._controller?.animateCamera(CameraUpdate.newLatLng(_d._destination!));
    _fetchRoute();
    _fitCameraToOriginDestination();
    _collapseStops();
    unawaited(_updateDestinationStreetLabel(_d._destination!));
    _notifyDraftSearchCollapsedAfterBothStops();
  }

  // ignore: unused_element
  void _setDestinationFromMapCenter() {
    final center =
        _d._mapCenter ??
        _d._destination ??
        _d._origin ??
        const LatLng(-16.5, -68.1);
    setState(() {
      _d._destination = center;
      _d._destinationDisplayLabel =
          '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}';
      _d._destinationPoiLabelLocked = false;
      _d._pickingDestination = false;
      _d._routePoints = null;
    });
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(center.latitude, center.longitude);
    _fetchRoute();
    _fitCameraToOriginDestination();
    _collapseStops();
  }

  Future<void> _fetchQuote({bool openQuoteSheet = true}) async {
    if (_d._destination == null) return;
    if (ref.read(tripRequestProvider).tripId != null) return;

    final gpsOk = await _ensureDeviceGpsForNewTrip();
    if (!gpsOk) {
      if (mounted) {
        setState(() {
          _d._error = AppLocalizations.of(context)!.tripRequireGpsForRequest;
        });
      }
      return;
    }

    setState(() {
      _d._loading = true;
      _d._error = null;
    });

    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _d._loading = false;
        _d._error = AppLocalizations.of(context)!.tripRbacSession;
      });
      return;
    }

    try {
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(_d._origin!.latitude, _d._origin!.longitude);
      ref
          .read(tripRequestProvider.notifier)
          .setDestination(
            _d._destination!.latitude,
            _d._destination!.longitude,
          );
      final api = TripsApi(token: token);
      final promo = await passengerPromoRequestFields(ref);
      final quote = await api.quoteTrip(
        originLat: _d._origin!.latitude,
        originLng: _d._origin!.longitude,
        destinationLat: _d._destination!.latitude,
        destinationLng: _d._destination!.longitude,
        deviceId: promo.deviceId,
        promoCode: promo.promoCode,
      );
      ref.read(tripRequestProvider.notifier).setQuote(quote);
      if (!mounted) return;
      if (quote.options.isNotEmpty) {
        ref
            .read(tripRequestProvider.notifier)
            .selectOption(quote.options.first);
      }
      if (openQuoteSheet) {
        _showQuoteSheet(quote);
      } else {
        setState(() {});
      }
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[Quote] Error: $e');
      if (e is DioException) {
        debugPrint(
          '[Quote] statusCode=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      debugPrint('[Quote] stack: $st');

      final l10nQ = AppLocalizations.of(context)!;
      setState(() {
        _d._error = localizedPassengerTripFailure(
          l10nQ,
          failureContext: PassengerTripFailureContext.quote,
          error: e,
        );
      });
    } finally {
      if (mounted) setState(() => _d._loading = false);
    }
  }

  void _showQuoteSheet(QuoteResponse quote) {
    final originAddress =
        (_d._originDisplayLabel != null &&
            _d._originDisplayLabel!.trim().isNotEmpty)
        ? _d._originDisplayLabel!.trim()
        : (_d._origin != null
              ? '${_d._origin!.latitude.toStringAsFixed(6)},${_d._origin!.longitude.toStringAsFixed(6)}'
              : null);
    final destinationAddress =
        (_d._destinationDisplayLabel != null &&
            _d._destinationDisplayLabel!.trim().isNotEmpty)
        ? _d._destinationDisplayLabel!.trim()
        : (_d._destination != null
              ? '${_d._destination!.latitude.toStringAsFixed(6)},${_d._destination!.longitude.toStringAsFixed(6)}'
              : null);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PassengerTripQuoteBottomSheet(
        quote: quote,
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        routeOverviewEncoded: _d._routeOverviewEncoded,
        ensureDeviceGpsForNewTrip: _ensureDeviceGpsForNewTrip,
        onClose: () => Navigator.of(ctx).pop(),
        onSuccess: () {

          Navigator.of(ctx).pop();
        },
      ),
    ).whenComplete(() {
      if (!mounted) return;

      final s = ref.read(tripRequestProvider);
      if (s.tripId == null && s.quote != null) {
        _cancelQuoteDraft();
      }
    });
  }

  void _cancelQuoteDraft() {
    if (!mounted) return;
    if (ref.read(tripRequestProvider).tripId != null) return;

    clearTripRecoverySnackTracking(ref);
    ref.read(tripRequestProvider.notifier).reset();
    _d._routeRequestToken++;
    setState(() {
      _d._destination = null;
      _d._destinationDisplayLabel = null;
      _d._destinationDriverAddress = null;
      _d._destinationPoiLabelLocked = false;
      _d._routePoints = null;
      _d._loadingRoute = false;
      _d._originDisplayLabel = null;
      _d._originDriverAddress = null;
      _d._originConfirmed = false;
      _d._pickingOrigin = true;
      _d._pickingDestination = false;
      _d._activeStop = ActiveStop.none;
      _d._originEditAnchor = null;
      _d._originPinAdjusted = false;
      _d._destinationMapPickArmed = false;
      _d._error = null;
      _d._draftEditTarget = PassengerDraftEditTarget.none;
    });
    if (_d._origin != null) {
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(_d._origin!.latitude, _d._origin!.longitude);
    }
    _d._controller?.animateCamera(
      CameraUpdate.newLatLng(_d._origin ?? const LatLng(-16.5, -68.1)),
    );
  }
}
