part of 'trip_request_screen.dart';

enum _PassengerLeaveSheetHeader { close, back }

mixin _TripRequestScreenDraftMixin on _TripRequestScreenOverlaysMixin {
  @override
  _TripRequestScreenState get _d => this as _TripRequestScreenState;

  static const _kMaxSavedPlaces = 5;

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

  /// Oculta buscador + acciones cuando ya hay origen y destino (salvo modo edici├│n).
  bool get _draftLocationSearchChromeVisible {
    if (!_d._originConfirmed) return true;
    if (_d._destination == null) return true;
    if (_d._draftEditTarget != PassengerDraftEditTarget.none) return true;
    return false;
  }

  /// Texto del slot de origen en la cabecera. Si estamos moviendo el pin para
  /// confirmar (`_d._pickingOrigin`), inyectamos la previsualizaci├│n en vivo
  /// (`_d._mapNeedleAddressPreview`) para que la direcci├│n apuntada se vea ah├¡
  /// mismo y, al confirmar, quede directamente persistida sin saltos visuales.
  String _resolveDraftOriginDisplayLine(AppLocalizations l10n) {
    if (_d._pickingOrigin || _d._draftEditTarget == PassengerDraftEditTarget.origin) {
      final preview = _d._mapNeedleAddressPreview?.trim();
      if (preview != null && preview.isNotEmpty) return preview;
    }
    return _d._originDisplayLabel ?? l10n.tripYourLocation;
  }

  /// Texto del slot de destino. Mientras se est├í apuntando con el pin, tambi├®n
  /// usamos `_d._mapNeedleAddressPreview` para mostrar la direcci├│n en tiempo real.
  String _resolveDraftDestinationDisplayLine(AppLocalizations l10n) {
    final isPickingDest =
        _d._pickingDestination ||
        (_d._originConfirmed &&
            _d._destination == null &&
            _d._activeStop == ActiveStop.none) ||
        _d._draftEditTarget == PassengerDraftEditTarget.destination;
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

  /// Backend exige label 2ÔÇô60 y address 3ÔÇô180 caracteres.
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
      _d._routePoints = null;
      _d._originConfirmed = true;
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
      _d._activeStop = ActiveStop.none;
      _d._draftEditTarget = PassengerDraftEditTarget.none;
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

  void _pickOriginSavedPlace(TripSavedPlaceItem place) {
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _d._origin = p;
      _d._originDisplayLabel = place.address.isNotEmpty
          ? place.address
          : place.label;
      _d._routePoints = null;
      _d._originConfirmed = true;
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
      _d._activeStop = ActiveStop.none;
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

  void _pickDestinationSavedPlace(TripSavedPlaceItem place) {
    final p = LatLng(place.lat, place.lng);
    setState(() {
      _d._destination = p;
      _d._destinationDisplayLabel = place.address.isNotEmpty
          ? place.address
          : place.label;
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
      await _loadSavedPlaces();
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
      await _loadSavedPlaces();
      if (!mounted) return;
      _showSubtleSnack(l10n.tripSavedPlaceSaved);
    } catch (_) {
      if (!mounted) return;
      _showSubtleSnack(l10n.commonError);
    }
  }

  Future<void> _openSavedPlacesManager({required bool forOrigin}) async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await _loadSavedPlaces();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final places = forOrigin
                ? _d._savedOriginPlaces
                : _d._savedDestinationPlaces;
            final atLimit = places.length >= _kMaxSavedPlaces;
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.profileSavedPlaces,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.tripSavedPlacesMax(_kMaxSavedPlaces),
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: atLimit
                            ? null
                            : () async {
                                final labelCtrl = TextEditingController(
                                  text: forOrigin
                                      ? (_d._originDisplayLabel ?? '').trim()
                                      : (_d._destinationDisplayLabel ?? '').trim(),
                                );
                                final ok = await showDialog<bool>(
                                  context: ctx,
                                  builder: (dCtx) => AlertDialog(
                                    title: Text(l10n.tripSavedPlaceDialogTitle),
                                    content: TextField(
                                      controller: labelCtrl,
                                      decoration: InputDecoration(
                                        labelText: l10n.tripSavedPlaceNameLabel,
                                        hintText: l10n.tripSavedPlaceNameHint,
                                      ),
                                      autofocus: true,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dCtx, false),
                                        child: Text(l10n.commonCancel),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dCtx, true),
                                        child: Text(l10n.tripSavedPlaceSaveCta),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true || !mounted) return;
                                final label = _ensureSavedPlaceLabel(
                                  labelCtrl.text,
                                  forOrigin
                                      ? l10n.tripOrigin
                                      : l10n.tripDestination,
                                  l10n,
                                );
                                final latLng = forOrigin
                                    ? _d._origin
                                    : _d._destination;
                                if (latLng == null) {
                                  _showSubtleSnack(l10n.commonError);
                                  return;
                                }
                                final addr = _ensureSavedPlaceAddress(
                                  forOrigin
                                      ? (_d._originDisplayLabel ?? '')
                                      : (_d._destinationDisplayLabel ?? ''),
                                  latLng.latitude,
                                  latLng.longitude,
                                );
                                try {
                                  await TripsApi(
                                    token: token,
                                  ).savePassengerPlace(
                                    label: label,
                                    address: addr,
                                    lat: latLng.latitude,
                                    lng: latLng.longitude,
                                  );
                                  await _loadSavedPlaces();
                                  if (!mounted) return;
                                  setSheet(() {});
                                  _showSubtleSnack(l10n.tripSavedPlaceSaved);
                                } catch (e) {
                                  if (!mounted) return;
                                  final code = e is DioException
                                      ? TexiBackendError.codeFromResponse(
                                          e.response?.data,
                                        )
                                      : null;
                                  _showSubtleSnack(
                                    code == 'SAVED_PLACES_LIMIT_REACHED'
                                        ? l10n.tripSavedPlacesLimitReached(
                                            _kMaxSavedPlaces,
                                          )
                                        : l10n.commonError,
                                  );
                                }
                              },
                        icon: const Icon(Icons.add_location_alt_rounded),
                        label: Text(l10n.tripSavedPlaceSaveMapCta),
                      ),
                      const SizedBox(height: 10),
                      if (places.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(l10n.profileStateEmpty),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: places.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = places[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  p.isFavorite
                                      ? Icons.star_rounded
                                      : Icons.place_rounded,
                                  color: p.isFavorite
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                title: Text(
                                  p.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  p.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  if (forOrigin) {
                                    _pickOriginSavedPlace(p);
                                  } else {
                                    _pickDestinationSavedPlace(p);
                                  }
                                  Navigator.of(ctx).pop();
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    final api = TripsApi(token: token);
                                    if (action == 'favorite') {
                                      await api.updatePassengerSavedPlace(
                                        placeId: p.id,
                                        isFavorite: !p.isFavorite,
                                      );
                                      await _loadSavedPlaces();
                                      if (!mounted) return;
                                      setSheet(() {});
                                    }
                                    if (action == 'delete') {
                                      await api.deletePassengerSavedPlace(p.id);
                                      await _loadSavedPlaces();
                                      if (!mounted) return;
                                      setSheet(() {});
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'favorite',
                                      child: Text(l10n.placeFavorite),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(l10n.tripSavedPlaceDeleteCta),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    _d._draftSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
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
    });
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
    if (q == null || opt == null || _d._origin == null || _d._destination == null) {
      return;
    }

    setState(() => _d._submittingTrip = true);
    final l10n = AppLocalizations.of(context)!;
    final originAddress =
        (_d._originDisplayLabel != null && _d._originDisplayLabel!.trim().isNotEmpty)
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
    setState(() => _d._submittingTrip = false);
    if (result.kind == PassengerTripSubmitResultKind.success ||
        result.kind == PassengerTripSubmitResultKind.recoveredExisting) {
      return;
    }
    final msg = result.message ?? l10n.commonError;
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
    return '$main ┬À $addr';
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
    // Si el label compuesto incluye nombre de POI (formato "Nombre ┬À Direcci├│n"),
    // ya tenemos el dato m├ís rico desde Places y NO disparamos reverse-geocode
    // (que sobrescribir├¡a el nombre del POI con la calle).
    final hasPoiName = composedLabel.contains(' ┬À ');
    setState(() {
      _d._origin = LatLng(details.lat, details.lng);
      _d._originDisplayLabel = composedLabel;
      _d._mapCenter = _d._origin;
      _d._routePoints = null;
      _d._searchingOriginAddress = false;
      _d._originConfirmed = true;
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
      _d._activeStop = ActiveStop.none;
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
        _d._mapCenter = _d._origin;
        _d._searchingOriginAddress = false;
        _d._routePoints = null;
        _d._originConfirmed = true;
        _d._pickingOrigin = false;
        _d._pickingDestination = false;
        _d._activeStop = ActiveStop.none;
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
    // Estrategia de fix: 1) lectura precisa con timeout corto; 2) fallback a la
    // ├║ltima posici├│n conocida del SO. Esto evita el banner rojo cuando el GPS
    // del sistema s├¡ tiene fix (pin azul visible) pero `getCurrentPosition` con
    // `LocationAccuracy.high` no logra cerrar una nueva muestra a tiempo.
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
      _d._mapCenter = _d._origin;
      _d._loadingOrigin = false;
      _d._routePoints = null;
      _d._deviceGpsFixOk = true;
      _d._originConfirmed = true;
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
      _d._activeStop = ActiveStop.none;
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

  Future<void> _showProfileMenu(
    BuildContext context, {
    Offset? anchor,
  }) async {
    final size = MediaQuery.sizeOf(context);
    final resolvedAnchor = anchor ??
        Offset(size.width - 40, size.height - 120);
    final action = await showPassengerFanMenu(
      context: context,
      anchorGlobal: resolvedAnchor,
    );
    if (!context.mounted || action == null) return;

    switch (action) {
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

  /// Prioriza salir de la app (sesión permanece vía refresh token).
  /// Cerrar sesión abre una segunda confirmación; Volver regresa al paso anterior.
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
      // X cierra el sheet (antes: cancelar abajo).
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
      // Flecha atrás reemplaza el TextButton "Volver".
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
                        if (headerControl ==
                            _PassengerLeaveSheetHeader.back)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: MaterialLocalizations.of(ctx)
                                  .backButtonTooltip,
                              onPressed: () =>
                                  Navigator.pop(ctx, headerBackValue),
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: AppColors.textPrimary,
                            ),
                          ),
                        if (headerControl ==
                            _PassengerLeaveSheetHeader.close)
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: MaterialLocalizations.of(ctx)
                                  .closeButtonTooltip,
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
                            color: (primaryDanger
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
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(ctx, primaryValue),
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
                            onPressed: () =>
                                Navigator.pop(ctx, secondaryValue),
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
    // Misma estrategia que `_setOriginFromCurrentLocation`: si `getCurrentPosition`
    // con alta precisi├│n falla (timeout/ruido), usar `getLastKnownPosition` antes
    // de renderizar el banner rojo.
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
        _d._mapCenter ?? _d._destination ?? _d._origin ?? const LatLng(-16.5, -68.1);
    setState(() {
      _d._destination = center;
      _d._destinationDisplayLabel =
          '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}';
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
        _d._error = AppLocalizations.of(context)!.commonError;
      });
      return;
    }

    try {
      ref
          .read(tripRequestProvider.notifier)
          .setOrigin(_d._origin!.latitude, _d._origin!.longitude);
      ref
          .read(tripRequestProvider.notifier)
          .setDestination(_d._destination!.latitude, _d._destination!.longitude);
      final api = TripsApi(token: token);
      final quote = await api.quoteTrip(
        originLat: _d._origin!.latitude,
        originLng: _d._origin!.longitude,
        destinationLat: _d._destination!.latitude,
        destinationLng: _d._destination!.longitude,
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
      String message = l10nQ.commonError;
      if (e is DioException) {
        final data = e.response?.data;
        final code = TexiBackendError.codeFromResponse(data);
        final rawMsg = TexiBackendError.messageFromResponse(data);
        message = localizedTripApiError(l10nQ, code, fallbackMessage: rawMsg);
        if (message == l10nQ.commonError && e.response?.statusCode != null) {
          message = '${e.response?.statusCode}: ${e.message ?? message}';
        }
      }
      setState(() => _d._error = message);
    } finally {
      if (mounted) setState(() => _d._loading = false);
    }
  }

  void _showQuoteSheet(QuoteResponse quote) {
    final originAddress =
        (_d._originDisplayLabel != null && _d._originDisplayLabel!.trim().isNotEmpty)
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
          // Solo cerrar el sheet: volver a montar `trip_request` con goNamed
          // recrea TripRequestScreen, pierde estado local del mapa y dispara initState
          // como "viaje persistido" (snack "Solicitud recuperada" + UI rota).
          Navigator.of(ctx).pop();
        },
      ),
    ).whenComplete(() {
      if (!mounted) return;
      // Si el sheet se cerr├│ sin llegar a solicitar conductor (tripId sigue null),
      // limpiamos cotizaci├│n, ruta y destino para poder rearmar el viaje.
      final s = ref.read(tripRequestProvider);
      if (s.tripId == null && s.quote != null) {
        _cancelQuoteDraft();
      }
    });
  }

  /// Solo antes de solicitar conductor: quita cotizaci├│n, ruta y destino del mapa.
  /// No aplica a viaje ya creado / en curso (tripId != null).
  void _cancelQuoteDraft() {
    if (!mounted) return;
    if (ref.read(tripRequestProvider).tripId != null) return;

    clearTripRecoverySnackTracking(ref);
    ref.read(tripRequestProvider.notifier).reset();
    _d._routeRequestToken++;
    setState(() {
      _d._destination = null;
      _d._destinationDisplayLabel = null;
      _d._routePoints = null;
      _d._loadingRoute = false;
      _d._originDisplayLabel = null;
      _d._originConfirmed = false;
      _d._pickingOrigin = true;
      _d._pickingDestination = false;
      _d._activeStop = ActiveStop.none;
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
