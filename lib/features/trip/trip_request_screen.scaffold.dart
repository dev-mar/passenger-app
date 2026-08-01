part of 'trip_request_screen.dart';

mixin _TripRequestScreenScaffoldMixin on _TripRequestScreenBootstrapMixin {
  @override
  _TripRequestScreenState get _d => this as _TripRequestScreenState;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mapUiResetTick = ref.watch(passengerTripMapUiResetTickProvider);
    if (mapUiResetTick > _d._lastConsumedPassengerTripMapUiTick) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final latest = ref.read(passengerTripMapUiResetTickProvider);
        if (latest <= _d._lastConsumedPassengerTripMapUiTick) return;
        _d._lastConsumedPassengerTripMapUiTick = latest;
        _resetLocalMapAfterExternalTripSessionClear();
      });
    }

    if (_d._loadingOrigin || _d._origin == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                l10n.splashGettingLocation,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (_d._originError != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _d._originError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final origin = _d._origin!;
    final tripState = ref.watch(tripRequestProvider);
    final tripId = tripState.tripId;
    final rtState = ref.watch(passengerRealtimeProvider);
    final effectiveTripId = tripId ?? rtState.activeTripId;
    final driverLat = rtState.driverLat;
    final driverLng = rtState.driverLng;
    final driverBearing = rtState.driverBearing;

    ref.listen<PassengerRealtimeState>(passengerRealtimeProvider, (
      previous,
      next,
    ) {
      if (previous != null) {
        _syncTripUnreadCounter(previous, next);
      }
      final wasEn = passengerTripIsEnRouteToDestination(previous?.status);
      final nowEn = passengerTripIsEnRouteToDestination(next.status);
      if (!wasEn && nowEn) {
        _schedulePassengerEnRouteRouteRefresh(immediate: true);
      } else if (wasEn && !nowEn) {
        _d._passengerEnRouteRouteDebounce?.cancel();
        if (mounted) {
          setState(() => _d._passengerEnRouteToDestPoints = null);
        }
      }

      final was = passengerTripChatPhaseActive(previous?.status);
      final now = passengerTripChatPhaseActive(next.status);
      if (was && !now && _d._tripChatSheetDisplayed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).maybePop();
        });
      }
    });

    // Sincroniza flags de calificaci├│n cuando cambia el trip (p. ej. creado en esta sesi├│n sin pasar por splash).
    ref.listen<TripRequestState>(tripRequestProvider, (previous, next) {
      final id = next.tripId;
      final prevId = previous?.tripId;
      if (id == prevId) return;

      void schedule(VoidCallback fn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          fn();
        });
      }

      if (id == null) {
        schedule(() {
          _d._passengerEnRouteRouteDebounce?.cancel();
          setState(() {
            _d._tripChatUnreadCount = 0;
            _d._tripChatReadCursor = 0;
            if (!_d._tripEndResetInProgress) {
              _d._ratingDoneTripId = null;
              _d._ratingDone = false;
              _d._ratingSheetShownForTripId = null;
            }
            _d._passengerEnRouteToDestPoints = null;
          });
        });
        return;
      }

      schedule(() {
        setState(() => _d._ratingSheetShownForTripId = null);
        unawaited(() async {
          final done = await TripSessionStorage.isRatingDone(id);
          if (!mounted) return;
          if (ref.read(tripRequestProvider).tripId != id) return;
          setState(() {
            _d._ratingDoneTripId = id;
            _d._ratingDone = done;
          });
        }());
      });
    });

    final isSearchingDriver =
        _d._searchingHoldUi ||
        (effectiveTripId != null &&
            passengerTripIsAwaitingDriverMatch(rtState.status));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSearchingNearbyPolling(isSearchingDriver);
    });
    final isRecoveringActiveTrip =
        effectiveTripId != null &&
        rtState.status == null &&
        !isSearchingDriver &&
        rtState.errorCode == null;
    final isTripActive =
        effectiveTripId != null &&
        (passengerTripIsTrackingDriver(rtState.status) ||
            rtState.status == 'completed');
    _syncAnimatedDriverMarker(
      tripId: effectiveTripId,
      status: rtState.status,
      rawDriverLat: driverLat,
      rawDriverLng: driverLng,
    );
    final animatedDriver = _d._animatedDriverLatLng;
    final showDriverMarker = effectiveTripId != null && animatedDriver != null;
    final showDriverPulse =
        showDriverMarker &&
        _d._appInForeground &&
        !_d._driverLikelyIdle &&
        !_lowBatteryModeActive;
    _emitMapOptimizationTelemetryIfNeeded(effectiveTripId);
    final shouldPeriodicSync =
        effectiveTripId != null &&
        rtState.status != null &&
        !passengerTripIsFinalStatus(rtState.status);

    if (shouldPeriodicSync) {
      final resolvedTripId = effectiveTripId;
      final trackingDriver = passengerTripIsTrackingDriver(rtState.status);
      final awaitingMatch = passengerTripIsAwaitingDriverMatch(rtState.status);
      // Matching/tracking: 4s (aceptación, arrived, started, completed).
      final Duration syncInterval = (awaitingMatch || trackingDriver)
          ? const Duration(seconds: 4)
          : const Duration(seconds: 60);
      _startTripStatusPeriodicSync(resolvedTripId, interval: syncInterval);
    } else {
      _stopTripStatusPeriodicSync();
    }
    final hasConnectionError =
        effectiveTripId != null && rtState.errorCode != null && !isSearchingDriver;
    final brightness = Theme.of(context).brightness;
    final activeRouteColor = passengerTripActiveRouteColor(rtState.status);
    final needsOriginConfirm =
        tripId == null &&
        !_d._originConfirmed &&
        _d._destination == null &&
        !_d._pickingOrigin &&
        !_d._pickingDestination;
    final needsDestinationConfirm =
        tripId == null &&
        _d._originConfirmed &&
        _d._destination == null &&
        !_d._pickingOrigin &&
        !_d._pickingDestination;
    final needsAnyMapConfirm = needsOriginConfirm || needsDestinationConfirm;
    final isMapConfirmMode =
        tripId == null &&
        _d._activeStop == ActiveStop.none &&
        (_d._pickingOrigin || _d._pickingDestination || needsAnyMapConfirm);

    /// Borrador de ruta (sin viaje creado): cabecera + barra inferior fija.
    /// El sheet deslizable del viaje activo solo aplica con [isTripActive].
    final showDraftPlanningChrome =
        effectiveTripId == null &&
        !isSearchingDriver &&
        !isRecoveringActiveTrip &&
        !isTripActive &&
        !hasConnectionError;
    final confirmingOrigin =
        _d._pickingOrigin ||
        _d._draftEditTarget == PassengerDraftEditTarget.origin ||
        needsOriginConfirm;
    final draftSearchPriorityMode =
        showDraftPlanningChrome &&
        _draftLocationSearchChromeVisible &&
        _d._draftSearchFocus.hasFocus &&
        MediaQuery.of(context).viewInsets.bottom > 0;
    final draftChromeHiddenWhileDragging =
        showDraftPlanningChrome &&
        isMapConfirmMode &&
        _d._mapConfirmInstructionHiddenWhileDragging &&
        !draftSearchPriorityMode;

    // Al completarse el viaje, mostrar una sola vez el sheet de calificaci├│n
    // ├║nicamente si el pasajero todav├¡a no lo resolvi├│ (localmente).
    if (effectiveTripId != null &&
        rtState.status == 'completed' &&
        effectiveTripId != _d._ratingSheetShownForTripId &&
        !_d._ratingDone) {
      _d._ratingSheetShownForTripId = effectiveTripId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showRatingSheet(context, effectiveTripId, rtState.driverName);
      });
    }

    // Completado pero el rating ya figuraba hecho (p. ej. storage desincronizado): no se abre el sheet
    // y el panel de estado bloqueaba el flujo; volvemos al inicio como con "Omitir".
    if (effectiveTripId != null &&
        rtState.status == 'completed' &&
        _d._ratingDone) {
      if (_d._completedStaleAutoResetTripId != effectiveTripId) {
        _d._completedStaleAutoResetTripId = effectiveTripId;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final providerTripId = ref.read(tripRequestProvider).tripId;
          if (providerTripId != null && providerTripId != effectiveTripId) {
            _d._completedStaleAutoResetTripId = null;
            return;
          }
          if (ref.read(passengerRealtimeProvider).status != 'completed') {
            _d._completedStaleAutoResetTripId = null;
            return;
          }
          await _resetHomeAfterTripEnded(effectiveTripId);
        });
      }
    } else if (effectiveTripId == null || rtState.status != 'completed') {
      _d._completedStaleAutoResetTripId = null;
    }

    // Si el viaje termina en estados finales sin rating (cancelled/expired), resetear autom├íticamente.
    if (effectiveTripId != null &&
        (rtState.status == 'cancelled' || rtState.status == 'expired')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_resetTripSessionToDraftHome(tripIdForGuard: effectiveTripId));
      });
    }

    // Marcadores: al confirmar, deben quedar visibles en el mapa (como antes).
    // Durante confirmaci├│n de ORIGEN, el marcador de origen sigue el centro.
    final originMarkerPos = confirmingOrigin ? (_d._mapCenter ?? origin) : origin;
    // Marcador de destino: solo cuando ya est├í confirmado (no mientras se est├í eligiendo).
    final LatLng? destMarkerPos =
        (_d._destination != null &&
            (!_d._pickingDestination ||
                _d._draftEditTarget == PassengerDraftEditTarget.destination))
        ? _d._destination
        : null;

    final passengerEnRouteToDestination =
        effectiveTripId != null &&
        passengerTripIsEnRouteToDestination(rtState.status);
    final List<LatLng> mapRoutePolylinePoints;
    if (_d._destination != null) {
      if (passengerEnRouteToDestination) {
        if (_d._passengerEnRouteToDestPoints != null &&
            _d._passengerEnRouteToDestPoints!.length >= 2) {
          mapRoutePolylinePoints = _d._passengerEnRouteToDestPoints!;
        } else if (animatedDriver != null) {
          mapRoutePolylinePoints = <LatLng>[animatedDriver, _d._destination!];
        } else if (_d._routePoints != null && _d._routePoints!.length >= 2) {
          mapRoutePolylinePoints = _d._routePoints!;
        } else {
          mapRoutePolylinePoints = <LatLng>[origin, _d._destination!];
        }
      } else {
        mapRoutePolylinePoints =
            (_d._routePoints != null && _d._routePoints!.isNotEmpty)
            ? _d._routePoints!
            : <LatLng>[origin, _d._destination!];
      }
    } else {
      mapRoutePolylinePoints = <LatLng>[origin];
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: origin, zoom: 15),
                onMapCreated: _onMapCreated,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                buildingsEnabled: false,
                indoorViewEnabled: false,
                trafficEnabled: false,
                // Deja el pin/radar visibles sobre el card de matching.
                padding: EdgeInsets.only(
                  bottom: isSearchingDriver ? 168 : 0,
                ),
                style: isTripActive ? _activeTripMapStyleFor(brightness) : null,
                myLocationEnabled: _d._mapMyLocationDotEnabled,
                // Recentrado unificado en barra superior (mismo c├¡rculo que idioma/perfil); evita duplicar el FAB nativo.
                myLocationButtonEnabled: false,
                // Con viaje activo solo bloqueamos colocar destino tocando el mapa (onTap abajo), no zoom ni pan.
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                onTap:
                    (tripId == null &&
                        !_d._pickingOrigin &&
                        !_d._pickingDestination &&
                        !needsAnyMapConfirm)
                    ? (pos) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          _d._destination = pos;
                          _d._destinationDisplayLabel = null;
                          _d._routePoints = null;
                        });
                        ref
                            .read(tripRequestProvider.notifier)
                            .setDestination(pos.latitude, pos.longitude);
                        _fetchRoute();
                      }
                    : null,
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdleForMapConfirm,
                markers: {
                  // Con aguja centrada no mostramos el pin amarillo duplicado (evita desalineaci├│n visual).
                  if (!(confirmingOrigin && isMapConfirmMode))
                    Marker(
                      markerId: const MarkerId('origin'),
                      position: originMarkerPos,
                      icon: _d._originOnTripIcon ?? _d._originFallbackIcon,
                      // Ancla por defecto (0.5, 1.0): la punta inferior del pin marca el punto real.
                    ),
                  if (destMarkerPos != null)
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: destMarkerPos,
                      icon: _d._destinationOnTripIcon ?? _d._destFallbackIcon,
                    ),
                  if (showDriverMarker)
                    Marker(
                      markerId: const MarkerId('driver'),
                      position: animatedDriver,
                      icon: _d._driverOnTripIcon ?? _d._driverFallbackIcon,
                      rotation: driverBearing ?? 0,
                      flat: true,
                      anchor: _d._driverOnTripIcon != null
                          ? const Offset(0.5, 0.5)
                          : const Offset(0.5, 1.0),
                    ),
                  // Matching: solo autos reales a ≤2 km (API nearby). Sin inventar pines.
                  if (isSearchingDriver)
                    ..._d._searchingNearbyDrivers.map(
                      (d) => Marker(
                        markerId: MarkerId('nearby_${d.driverId}'),
                        position: LatLng(d.lat, d.lng),
                        icon: _d._driverOnTripIcon ?? _d._driverFallbackIcon,
                        flat: true,
                        anchor: _d._driverOnTripIcon != null
                            ? const Offset(0.5, 0.5)
                            : const Offset(0.5, 1.0),
                        zIndexInt: 2,
                      ),
                    ),
                },
                circles: {
                  if (showDriverPulse)
                    Circle(
                      circleId: const CircleId('driver_pulse'),
                      center: animatedDriver,
                      radius: 18 + (10 * _d._driverPulseController.value),
                      fillColor: AppColors.primary.withValues(
                        alpha: 0.11 - (_d._driverPulseController.value * 0.05),
                      ),
                      strokeColor: AppColors.primary.withValues(
                        alpha: 0.34 - (_d._driverPulseController.value * 0.14),
                      ),
                      strokeWidth: 2,
                    ),
                  // Radar expansivo en origen durante matching (con o sin nearby).
                  if (isSearchingDriver && _d._origin != null) ...[
                    Circle(
                      circleId: const CircleId('search_radar_outer'),
                      center: _d._origin!,
                      radius: 180 +
                          (420 * _d._searchingMapRadarController.value),
                      fillColor: const Color(0xFF4FC3F7).withValues(
                        alpha: 0.07 *
                            (1 - _d._searchingMapRadarController.value),
                      ),
                      strokeColor: const Color(0xFFFFC107).withValues(
                        alpha: 0.35 *
                            (1 - _d._searchingMapRadarController.value * 0.6),
                      ),
                      strokeWidth: 2,
                    ),
                    Circle(
                      circleId: const CircleId('search_radar_core'),
                      center: _d._origin!,
                      radius: 55,
                      fillColor: const Color(0xFFFFC107).withValues(alpha: 0.12),
                      strokeColor:
                          const Color(0xFFFFC107).withValues(alpha: 0.45),
                      strokeWidth: 1,
                    ),
                  ],
                },
                polylines:
                    _d._destination != null && mapRoutePolylinePoints.length >= 2
                    ? {
                        Polyline(
                          polylineId: const PolylineId('route_casing'),
                          points: mapRoutePolylinePoints,
                          color: brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.12),
                          width: 10,
                          geodesic: true,
                          zIndex: 0,
                        ),
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: mapRoutePolylinePoints,
                          color: activeRouteColor,
                          width: 6,
                          geodesic: true,
                          zIndex: 1,
                        ),
                      }
                    : {},
              ),
            ),
            // Aguja debajo del chrome de borrador/sugerencias para no tapar la lista.
            if (isMapConfirmMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      key: _d._needleRenderKey,
                      width: 56,
                      height: 72,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, 3),
                            child: Container(
                              width: 16,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -27),
                            child: Icon(
                              confirmingOrigin
                                  ? Icons.place_rounded
                                  : Icons.location_on_rounded,
                              size: 52,
                              color: confirmingOrigin
                                  ? const Color(0xFFF9AB00)
                                  : const Color(0xFF111111),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Barra superior: draft header, o chat/seguridad en viaje activo.
            // Menú y GPS del mapa se retiraron; viven en draft chrome / otras pantallas.
            if (!isSearchingDriver)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      10,
                      6,
                      10,
                      6 +
                          (draftSearchPriorityMode
                              ? 0
                              : MediaQuery.of(context).viewInsets.bottom * 0.2),
                    ),
                    child: IgnorePointer(
                    ignoring: draftChromeHiddenWhileDragging,
                    child: AnimatedSlide(
                      duration: AppMotion.draftSearchChromeReveal,
                      curve: AppMotion.standard,
                      offset: draftChromeHiddenWhileDragging
                          ? const Offset(0, -0.04)
                          : Offset.zero,
                      child: AnimatedOpacity(
                        duration: AppMotion.draftSearchChromeReveal,
                        curve: AppMotion.standard,
                        opacity: draftChromeHiddenWhileDragging ? 0 : 1,
                        child: showDraftPlanningChrome
                            ? PassengerTripDraftHeader(
                                originConfirmed: _d._originConfirmed,
                                // Mientras el pin se est├í moviendo (modo aguja), inyectamos la
                                // previsualizaci├│n en vivo en la fila correspondiente para que el
                                // usuario vea la direcci├│n que apunta sin texto sobre el pin.
                                originDisplayLine:
                                    _resolveDraftOriginDisplayLine(l10n),
                                destinationDisplayLine:
                                    _resolveDraftDestinationDisplayLine(l10n),
                                hasDestinationSet: _d._destination != null,
                                searchController: _d._draftSearchController,
                                searchFocusNode: _d._draftSearchFocus,
                                onSearchChanged: _onDraftSearchChanged,
                                searchFieldHint: !_d._originConfirmed
                                    ? l10n.tripYourLocation
                                    : l10n.tripDraftSearchHint,
                                showSuggestionsPanel:
                                    _draftLocationSearchChromeVisible &&
                                    _d._draftSearchFocus.hasFocus &&
                                    (_d._draftSearchController.text.trim().length <
                                            2 ||
                                        _d._loadingDraftSuggestions ||
                                        _d._draftSuggestions.isNotEmpty),
                                loadingSuggestions: _d._loadingDraftSuggestions,
                                suggestions: _d._draftSuggestions,
                                onPickSuggestion: (s) {
                                  unawaited(_pickDraftSuggestion(s));
                                },
                                recentPlaces:
                                    _draftSearchPhase ==
                                        PassengerDraftSearchRole.origin
                                    ? _d._recentOriginPlaces
                                    : _d._recentDestinationPlaces,
                                onPickRecent: _pickDraftRecent,
                                recentSectionTitle: l10n.profileRecentPlaces,
                                onMyLocationIconTap: _onDraftMyLocationIconTap,
                                onSavedIconTap: _onDraftSavedIconTap,
                                myLocationTooltip: l10n.tripUseMyLocation,
                                savedPlacesTooltip: l10n.profileSavedPlaces,
                                showLocationSearchChrome:
                                    _draftLocationSearchChromeVisible,
                                highlightOrigin:
                                    isMapConfirmMode && confirmingOrigin,
                                highlightDestination:
                                    isMapConfirmMode && !confirmingOrigin,
                                searchPriorityMode: draftSearchPriorityMode,
                                searchRole: _draftSearchPhase,
                                searchCollapseToken:
                                    _d._draftSearchCollapseToken,
                                onEditOrigin: _d._originConfirmed
                                    ? _onDraftEditOriginPressed
                                    : null,
                                onEditDestination: _d._originConfirmed
                                    ? _onDraftEditDestinationPressed
                                    : null,
                                editStopLabel: l10n.tripDraftEditStop,
                                onSaveOriginToFavorites: _d._origin != null
                                    ? () => unawaited(_saveCurrentOriginPlace())
                                    : null,
                                saveOriginFavoritesTooltip:
                                    l10n.tripDraftSaveOriginShortcut,
                                onSaveDestinationToFavorites:
                                    _d._destination != null
                                    ? () => unawaited(
                                        _saveCurrentDestinationPlace(),
                                      )
                                    : null,
                                saveDestinationFavoritesTooltip:
                                    l10n.tripDraftSaveDestinationShortcut,
                              )
                            : (isTripActive && !isMapConfirmMode)
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Spacer(),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (passengerTripChatPhaseActive(
                                            rtState.status,
                                          ))
                                            AnimatedBuilder(
                                              animation: _d
                                                  ._chatAttentionController,
                                              builder: (context, _) {
                                                return _MapChatActionButton(
                                                  unread:
                                                      _d._tripChatUnreadCount,
                                                  pulse: _d
                                                      ._chatAttentionController
                                                      .value,
                                                  tooltip:
                                                      l10n.passengerTripChatTitle,
                                                  onPressed: () => unawaited(
                                                    _openTripChatSheet(
                                                      tripId: effectiveTripId,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          if (passengerTripChatPhaseActive(
                                                rtState.status,
                                              ) &&
                                              passengerTripIsEnRouteToDestination(
                                                rtState.status,
                                              ))
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                          if (passengerTripIsEnRouteToDestination(
                                            rtState.status,
                                          ))
                                            Tooltip(
                                              message: l10n.menuSupportHelp,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  customBorder:
                                                      const CircleBorder(),
                                                  onTap: () => context
                                                      .pushNamed(
                                                    AppRouter.safetyHub,
                                                  ),
                                                  child: Image.asset(
                                                    AppAssets.safetyButton,
                                                    width: 52,
                                                    height: 52,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (isTripActive &&
                !isSearchingDriver &&
                rtState.status != null &&
                !isMapConfirmMode)
              Positioned(
                top: 0,
                left: 10,
                right: 72,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Material(
                      color: AppColors.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(12),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car_rounded,
                              size: 18,
                              color: passengerTripActiveRouteColor(rtState.status),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                passengerTripStatusLabel(l10n, rtState.status!),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Overlay "Buscando conductor" en el mismo mapa (sin cambiar de pantalla)
            if (isSearchingDriver)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TripSearchingDriverOverlay(
                  key: ValueKey(
                    'searching_${_d._searchingOverlayGeneration}_'
                    '${_d._searchingHoldUi ? 'hold' : 'live'}',
                  ),
                  l10n: l10n,
                  initialStage: _d._searchingHoldUi ? 3 : 1,
                  onCancel: () => unawaited(_cancelSearchingTrip()),
                  onContinue: () =>
                      unawaited(_restartSearchingTripAfterTimeout()),
                  onStage3Reached: _d._searchingHoldUi
                      ? null
                      : () => unawaited(_onSearchingStage3Reached()),
                ),
              ),
            if (isRecoveringActiveTrip && !isSearchingDriver)
              PassengerTripRecoveryPanel(
                onRetry: () {
                  final quote = tripState.quote;
                  unawaited(() async {
                    await ref
                        .read(passengerRealtimeProvider.notifier)
                        .syncTripStatusFromApi(
                          tripId: effectiveTripId,
                          force: true,
                        );
                    if (!mounted) return;
                    final rt = ref.read(passengerRealtimeProvider);
                    if (!rt.connected && !rt.connecting) {
                      ref.read(passengerRealtimeProvider.notifier).connect(
                            tripId: effectiveTripId,
                            quote: quote,
                          );
                    }
                  }());
                },
              ),
            // Panel retr├íctil de estado del viaje + datos del conductor y del viaje
            if (isTripActive && !isSearchingDriver && rtState.status != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.34,
                  minChildSize: 0.14,
                  maxChildSize: 0.72,
                  builder: (context, scrollController) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        TripStatusCard(
                          status: rtState.status!,
                          statusLabel: passengerTripStatusLabel(l10n, rtState.status!),
                          driverName: displayDriverName(
                            rtState.driverName,
                            l10n.tripDriverNameFallback,
                          ),
                          driverPhotoUrl: rtState.driverPhotoUrl,
                          driverRating: rtState.driverRating,
                          showAvatarRefreshingRing: (() {
                            final expiresAt = rtState.driverPhotoExpiresAt;
                            if (expiresAt == null) return false;
                            final now = DateTime.now();
                            return !now.isBefore(
                              expiresAt.subtract(const Duration(seconds: 45)),
                            );
                          })(),
                          carColor: rtState.carColor,
                          carPlate: rtState.carPlate,
                          carModel: rtState.carModel,
                          originLabel:
                              _d._originDisplayLabel ?? l10n.tripYourLocation,
                          destinationLabel:
                              _d._destinationDisplayLabel ?? l10n.tripDestination,
                          durationMinutes:
                              tripState.quote?.durationMinutes ??
                              rtState.quote?.durationMinutes ??
                              0,
                          distanceKm:
                              tripState.quote?.distanceKm ??
                              rtState.quote?.distanceKm ??
                              0.0,
                          estimatedPrice:
                              tripState.selectedOption?.estimatedPrice ??
                              tripState
                                  .quote
                                  ?.options
                                  .firstOrNull
                                  ?.estimatedPrice ??
                              rtState
                                  .quote
                                  ?.options
                                  .firstOrNull
                                  ?.estimatedPrice ??
                              0.0,
                          currencyCode:
                              tripState.selectedOption?.currencyCode ??
                              tripState.quote?.currencyCode ??
                              rtState.quote?.currencyCode ??
                              rtState.currencyCode,
                          statusFromLabel: l10n.tripStatusFrom,
                          statusToLabel: l10n.tripStatusTo,
                          driverAssignedLabel: l10n.tripStatusDriverAssigned,
                          statusMinutesLabel: (int c) =>
                              l10n.tripStatusMinutes(c),
                          statusKmLabel: (String v) => l10n.tripStatusKm(v),
                          onFinishedClose: rtState.status == 'completed'
                              ? () => unawaited(
                                    _resetHomeAfterTripEnded(effectiveTripId),
                                  )
                              : null,
                          finishedCloseLabel: rtState.status == 'completed'
                              ? l10n.tripFinishedBackToHome
                              : null,
                          onShareTrip: null,
                          shareTripLabel: null,
                          onOpenChat:
                              passengerTripChatPhaseActive(rtState.status)
                              ? () => unawaited(
                                    _openTripChatSheet(tripId: effectiveTripId),
                                  )
                              : null,
                          chatLabel: l10n.tripSecureChat,
                          unreadChatCount: _d._tripChatUnreadCount,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Error de conexi├│n Socket: tripId existe pero fall├│ connect (NO_TOKEN, SOCKET, etc.)
            if (hasConnectionError)
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSafeScrolling.systemNavBottom(context),
                child: TripConnectionErrorOverlay(
                  message: localizedPassengerRealtimeError(
                    l10n,
                    rtState.errorCode,
                  ),
                  onRetry: () {
                    final quote = tripState.quote;
                    ref
                        .read(passengerRealtimeProvider.notifier)
                        .connect(tripId: effectiveTripId, quote: quote);
                  },
                  onCancel: isSearchingDriver
                      ? () => unawaited(_cancelSearchingTrip())
                      : null,
                  retryLabel: l10n.homeRetry,
                  cancelLabel: isSearchingDriver ? l10n.commonCancel : null,
                ),
              ),
            // Borrador: barra inferior (confirmar en mapa / cotizaci├│n / solicitar). GPS y guardados van en la cabecera.
            if (showDraftPlanningChrome)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: draftChromeHiddenWhileDragging,
                  child: AnimatedSlide(
                    duration: AppMotion.draftSearchChromeReveal,
                    curve: AppMotion.standard,
                    offset: draftChromeHiddenWhileDragging
                        ? const Offset(0, 0.08)
                        : Offset.zero,
                    child: AnimatedOpacity(
                      duration: AppMotion.draftSearchChromeReveal,
                      curve: AppMotion.standard,
                      opacity: draftChromeHiddenWhileDragging ? 0 : 1,
                      child: PassengerTripDraftBottomBar(
                        isMapConfirmMode: isMapConfirmMode,
                        confirmingOrigin: confirmingOrigin,
                        onConfirmMapPick: () async {
                          TexiUiFeedback.lightTap();
                          if (confirmingOrigin) {
                            await _setOriginFromNeedle();
                          } else {
                            await _setDestinationFromNeedle();
                          }
                        },
                        quote: tripState.quote,
                        selectedQuoteOption: tripState.selectedOption,
                        onSelectQuoteOption: (o) {
                          ref
                              .read(tripRequestProvider.notifier)
                              .selectOption(o);
                          setState(() {});
                        },
                        quotePerTripLabel: l10n.quotePerTrip,
                        quoteSummaryText: null,
                        onRequestRide: _submitInlineTripRequest,
                        requestRideEnabled:
                            tripState.quote != null &&
                            tripState.selectedOption != null &&
                            !_d._submittingTrip &&
                            !_d._loading &&
                            !_d._loadingRoute,
                        requestRideLoading: _d._submittingTrip,
                        quotingInProgress: _d._loading && tripState.quote == null,
                        loadingRoute: _d._loadingRoute,
                        routeLoadingLabel: l10n.tripDraftCalculatingRoute,
                        errorMessage: _d._error,
                        showCancelDraft:
                            tripId == null &&
                            _d._origin != null &&
                            _d._destination != null &&
                            !isMapConfirmMode,
                        onCancelDraft: _cancelQuoteDraft,
                        cancelDraftLabel: l10n.tripCancelQuoteDraft,
                        onMenuPressed: (anchor) =>
                            _showProfileMenu(context, anchor: anchor),
                        menuTooltip: l10n.menuOpenTooltip,
                      ),
                    ),
                  ),
                ),
              ),
            if (_d._loading ||
                _d._searchingOriginAddress ||
                _d._searchingDestinationAddress)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chat en mapa: icono moderno tipo “mensaje” con badge de no leídos.
class _MapChatActionButton extends StatelessWidget {
  const _MapChatActionButton({
    required this.unread,
    required this.pulse,
    required this.tooltip,
    required this.onPressed,
  });

  final int unread;
  final double pulse;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;
    final scale = hasUnread ? 1 + (pulse * 0.06) : 1.0;

    return Tooltip(
      message: tooltip,
      child: Transform.scale(
        scale: scale,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Ink(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(
                  color: AppColors.primary.withValues(
                    alpha: hasUnread ? 0.45 : 0.18,
                  ),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.16 + (hasUnread ? pulse * 0.18 : 0),
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    hasUnread
                        ? Icons.mark_unread_chat_alt_rounded
                        : Icons.forum_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: unread > 9
                            ? const EdgeInsets.symmetric(horizontal: 4)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

