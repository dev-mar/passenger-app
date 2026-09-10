part of 'trip_request_screen.dart';

mixin _TripRequestScreenTripOpsMixin on _TripRequestScreenMapMixin {
  _TripRequestScreenState get _d => this as _TripRequestScreenState;

  Future<void> _loadRecentPlaces() async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    try {
      final api = TripsApi(token: token);
      final rows = await api.getPassengerRecentPlaces(limit: 24);
      if (!mounted) return;
      TripRecentPlaceItem fromRow(PassengerRecentPlace e) =>
          TripRecentPlaceItem(
            label: e.label,
            subtitle: e.subtitle,
            lat: e.lat,
            lng: e.lng,
          );
      bool usable(PassengerRecentPlace e) =>
          e.label.trim().isNotEmpty && e.lat.abs() <= 90 && e.lng.abs() <= 180;
      final origins = rows
          .where((e) => usable(e) && e.placeType.toLowerCase() == 'origin')
          .map(fromRow)
          .take(5)
          .toList(growable: false);
      final dests = rows
          .where((e) => usable(e) && e.placeType.toLowerCase() == 'destination')
          .map(fromRow)
          .take(5)
          .toList(growable: false);
      setState(() {
        _d._recentOriginPlaces = origins;
        _d._recentDestinationPlaces = dests;
      });
    } catch (_) {}
  }

  Future<void> _loadSavedPlaces() async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty || !mounted) return;
    try {
      final api = TripsApi(token: token);
      final rows = await api.getPassengerSavedPlaces(limit: 12);
      if (!mounted) return;
      final mapped = rows
          .where((e) => e.label.trim().isNotEmpty)
          .map(
            (e) => TripSavedPlaceItem(
              id: e.id,
              label: e.label,
              address: e.address,
              lat: e.lat,
              lng: e.lng,
              isFavorite: e.isFavorite,
            ),
          )
          .toList(growable: false);
      setState(() {
        _d._savedOriginPlaces = mapped.take(8).toList(growable: false);
        _d._savedDestinationPlaces = mapped.take(8).toList(growable: false);
      });
    } catch (_) {}
  }

  void _applyTripUiSnapshot(Map<String, dynamic> raw) {
    final oLat = raw['originLat'];
    final oLng = raw['originLng'];
    final dLat = raw['destLat'];
    final dLng = raw['destLng'];
    if (oLat == null || oLng == null || dLat == null || dLng == null) return;

    final quoteVal = raw['quote'];
    if (quoteVal is! Map) return;
    final quoteMap = Map<String, dynamic>.from(quoteVal);
    final QuoteResponse quote;
    try {
      quote = QuoteResponse.fromJson(quoteMap);
    } catch (_) {
      return;
    }

    final selRaw = raw['selectedServiceTypeId'];
    int? selId;
    if (selRaw is int) {
      selId = selRaw;
    } else if (selRaw is num) {
      selId = selRaw.toInt();
    } else if (selRaw != null) {
      selId = int.tryParse(selRaw.toString());
    }

    QuoteOption? sel;
    if (selId != null) {
      for (final o in quote.options) {
        if (o.serviceTypeId == selId) {
          sel = o;
          break;
        }
      }
    }
    sel ??= quote.options.isNotEmpty ? quote.options.first : null;
    if (sel == null) return;

    final origin = LatLng((oLat as num).toDouble(), (oLng as num).toDouble());
    final dest = LatLng((dLat as num).toDouble(), (dLng as num).toDouble());

    if (!mounted) return;
    setState(() {
      _d._origin = origin;
      _d._destination = dest;
      final ol = raw['originLabel']?.toString();
      final dl = raw['destLabel']?.toString();
      _d._originDisplayLabel = (ol != null && ol.isNotEmpty) ? ol : null;
      _d._destinationDisplayLabel = (dl != null && dl.isNotEmpty) ? dl : null;
      _d._originConfirmed = true;
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
      _d._activeStop = ActiveStop.none;
      _d._mapCenter = dest;
      _d._routePoints = null;
      _d._loadingOrigin = false;
      _d._originError = null;
      _d._draftEditTarget = PassengerDraftEditTarget.none;
    });

    ref
        .read(tripRequestProvider.notifier)
        .setOrigin(origin.latitude, origin.longitude);
    ref
        .read(tripRequestProvider.notifier)
        .setDestination(dest.latitude, dest.longitude);
    ref.read(tripRequestProvider.notifier).setQuote(quote);
    ref.read(tripRequestProvider.notifier).selectOption(sel);

    unawaited(_loadPinIcons());
    _fetchRoute();
  }
  Future<void> _resetHomeAfterTripEnded(String tripId) async {
    if (!mounted) return;
    final providerTripId = ref.read(tripRequestProvider).tripId;
    if (providerTripId != null && providerTripId != tripId) return;

    _d._tripEndResetInProgress = true;
    _d._routeRequestToken++;
    _d._passengerEnRouteRouteDebounce?.cancel();
    // Como el backend no persiste rating (pending/submitted/skipped),
    // lo guardamos en el almacenamiento local para poder recordar
    // el recordatorio al reabrir la app.
    await TripSessionStorage.setRatingDone(tripId, true);
    await TripSessionStorage.clearActiveTripId();
    PassengerNotificationService.clearArrivedNotificationDedupe(tripId);
    final latestProviderTripId = ref.read(tripRequestProvider).tripId;
    if (!mounted ||
        (latestProviderTripId != null && latestProviderTripId != tripId)) {
      _d._tripEndResetInProgress = false;
      return;
    }

    ref.read(passengerRealtimeProvider.notifier).disconnect();
    clearTripRecoverySnackTracking(ref);
    ref.read(tripRequestProvider.notifier).reset();
    ref.read(passengerTripMapUiResetTickProvider.notifier).state++;
    _d._completedStaleAutoResetTripId = null;
    if (mounted) {
      setState(() {
        _d._ratingDoneTripId = null;
        _d._ratingDone = false;
        _d._ratingSheetShownForTripId = null;
        _d._destination = null;
        _d._destinationDisplayLabel = null;
        _d._routePoints = null;
        _d._passengerEnRouteToDestPoints = null;
        _d._loadingRoute = false;
        _d._originConfirmed = false;
        _d._pickingOrigin = false;
        _d._pickingDestination = false;
        _d._error = null;
        _d._searchingHoldUi = false;
        _d._matchingSubmitUi = false;
        _d._keepDraftAfterMatchingCancel = false;
        _d._searchingStage3CancelInFlight = false;
        _d._submittingTrip = false;
        _d._draftEditTarget = PassengerDraftEditTarget.none;
        _d._matchingRetryQuote = null;
        _d._matchingRetryOption = null;
        _d._matchingRetryOrigin = null;
        _d._matchingRetryDestination = null;
        _d._matchingRetryOriginLabel = null;
        _d._matchingRetryDestinationLabel = null;
        _d._matchingRetryRouteEncoded = null;
        if (_d._origin != null) {
          // Para el siguiente viaje, empezamos forzando confirmación del origen.
          _d._pickingOrigin = true;
          _d._activeStop = ActiveStop.none;
        }
      });
    }
    _d._tripEndResetInProgress = false;
    await _recenterMapToDeviceGpsAfterTripEnd();
    unawaited(_loadRecentPlaces());
    unawaited(_loadSavedPlaces());
  }

  /// Reset tras cancelación/expiración (sin rating): vuelve al borrador limpio.
  Future<void> _resetTripSessionToDraftHome({String? tripIdForGuard}) async {
    if (!mounted) return;
    if (tripIdForGuard != null) {
      final providerTripId = ref.read(tripRequestProvider).tripId;
      if (providerTripId != null && providerTripId != tripIdForGuard) return;
    }

    _d._tripEndResetInProgress = true;
    _d._routeRequestToken++;
    _d._passengerEnRouteRouteDebounce?.cancel();
    await TripSessionStorage.clearActiveTripId();
    if (tripIdForGuard != null) {
      PassengerNotificationService.clearArrivedNotificationDedupe(tripIdForGuard);
    }
    ref.read(passengerRealtimeProvider.notifier).disconnect();
    clearTripRecoverySnackTracking(ref);
    ref.read(tripRequestProvider.notifier).reset();
    ref.read(passengerTripMapUiResetTickProvider.notifier).state++;
    _d._completedStaleAutoResetTripId = null;
    if (mounted) {
      setState(() {
        _d._ratingDoneTripId = null;
        _d._ratingDone = false;
        _d._ratingSheetShownForTripId = null;
        _d._destination = null;
        _d._destinationDisplayLabel = null;
        _d._routePoints = null;
        _d._passengerEnRouteToDestPoints = null;
        _d._loadingRoute = false;
        _d._originConfirmed = false;
        _d._pickingOrigin = false;
        _d._pickingDestination = false;
        _d._error = null;
        _d._searchingHoldUi = false;
        _d._matchingSubmitUi = false;
        _d._keepDraftAfterMatchingCancel = false;
        _d._searchingStage3CancelInFlight = false;
        _d._searchingOriginCameraDone = false;
        _d._submittingTrip = false;
        _d._tripSubmitGeneration++;
        _d._draftEditTarget = PassengerDraftEditTarget.none;
        _d._matchingRetryQuote = null;
        _d._matchingRetryOption = null;
        _d._matchingRetryOrigin = null;
        _d._matchingRetryDestination = null;
        _d._matchingRetryOriginLabel = null;
        _d._matchingRetryDestinationLabel = null;
        _d._matchingRetryRouteEncoded = null;
        if (_d._origin != null) {
          _d._pickingOrigin = true;
          _d._activeStop = ActiveStop.none;
        }
      });
    }
    _d._tripEndResetInProgress = false;
    await _recenterMapToDeviceGpsAfterTripEnd();
    unawaited(_loadRecentPlaces());
    unawaited(_loadSavedPlaces());
  }

  /// Tras [clearPassengerTripSessionFromContainer] (p. ej. tap en notificaci├│n con viaje ya terminal):
  /// los providers ya est├ín limpios; esto alinea pines, polil├¡nea y flags que viven solo en este State.
  void _resetLocalMapAfterExternalTripSessionClear() {
    _d._routeRequestToken++;
    _d._passengerEnRouteRouteDebounce?.cancel();
    _d._completedStaleAutoResetTripId = null;
    if (!mounted) return;
    setState(() {
      _d._ratingDoneTripId = null;
      _d._ratingDone = false;
      _d._ratingSheetShownForTripId = null;
      _d._destination = null;
      _d._destinationDisplayLabel = null;
      _d._routePoints = null;
      _d._passengerEnRouteToDestPoints = null;
      _d._loadingRoute = false;
      _d._originConfirmed = false;
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
      _d._error = null;
      _d._loading = false;
      _d._searchingHoldUi = false;
      _d._matchingSubmitUi = false;
      _d._keepDraftAfterMatchingCancel = false;
      _d._searchingStage3CancelInFlight = false;
      _d._submittingTrip = false;
      _d._tripSubmitGeneration++;
      _d._activeStop = ActiveStop.none;
      _d._draftEditTarget = PassengerDraftEditTarget.none;
      if (_d._origin != null) {
        _d._pickingOrigin = true;
      }
    });
    unawaited(_recenterMapToDeviceGpsAfterTripEnd());
    unawaited(_loadRecentPlaces());
    unawaited(_loadSavedPlaces());
  }
  void _collapseStops() {
    setState(() {
      _d._activeStop = ActiveStop.none;
      _d._pickingOrigin = false;
      _d._pickingDestination = false;
    });
  }

  /// Margen inferior cuando hay barra de borrador fija (~25–30% de la pantalla).
  double _snackBarBottomMarginForOverlay() {
    if (!mounted) return 24;
    final h = MediaQuery.sizeOf(context).height;
    final draftBarLikely = ref.read(tripRequestProvider).tripId == null;
    if (!draftBarLikely) return 24;
    return (h * 0.30).clamp(130.0, 280.0);
  }

  void _showSubtleSnack(String message) {
    TexiUiFeedback.lightTap();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    // Elevar el SnackBar para que no quede tapado por PassengerTripDraftBottomBar.
    final bottomMargin = _snackBarBottomMarginForOverlay();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface.withValues(alpha: 0.96),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.24)),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        duration: const Duration(milliseconds: 2200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
  Future<void> _shareActiveTrip({
    required String tripId,
    String? driverName,
    String? plate,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.tripShareError)),
        );
      }
      return;
    }
    try {
      final link = await TripsApi(token: token).createOrReuseTripShareLink(
        tripId: tripId,
      );
      if (!mounted) return;
      if (link.shareUrl.isEmpty) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.tripShareError)),
        );
        return;
      }
      final who = displayDriverName(driverName, l10n.tripDriverNameFallback);
      final plateLabel = (plate ?? '').trim().isEmpty
          ? l10n.commonEmptyDash
          : plate!.trim();
      final message = l10n.tripShareMessage(link.shareUrl, who, plateLabel);
      await SharePlus.instance.share(ShareParams(text: message));
    } catch (e, st) {
      debugPrint('[ShareTrip] $e\n$st');
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(l10n.tripShareError),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _captureMatchingRetryDraft() {
    final s = ref.read(tripRequestProvider);
    final quote = s.quote ?? _d._matchingRetryQuote;
    final opt = s.selectedOption ?? _d._matchingRetryOption;
    final origin = _d._origin ?? _d._matchingRetryOrigin;
    final dest = _d._destination ?? _d._matchingRetryDestination;
    if (quote == null || opt == null || origin == null || dest == null) return;
    _d._matchingRetryQuote = quote;
    _d._matchingRetryOption = opt;
    _d._matchingRetryOrigin = origin;
    _d._matchingRetryDestination = dest;
    final originLabel = _d._originDisplayLabel?.trim();
    final destLabel = _d._destinationDisplayLabel?.trim();
    if (originLabel != null && originLabel.isNotEmpty) {
      _d._matchingRetryOriginLabel = originLabel;
    }
    if (destLabel != null && destLabel.isNotEmpty) {
      _d._matchingRetryDestinationLabel = destLabel;
    }
    final encoded = _d._routeOverviewEncoded;
    if (encoded != null && encoded.isNotEmpty) {
      _d._matchingRetryRouteEncoded = encoded;
    }
  }

  void _restoreMatchingRetryDraftIfNeeded() {
    final quote = _d._matchingRetryQuote;
    final opt = _d._matchingRetryOption;
    final origin = _d._matchingRetryOrigin;
    final dest = _d._matchingRetryDestination;
    if (quote == null || opt == null || origin == null || dest == null) return;

    final notifier = ref.read(tripRequestProvider.notifier);
    final current = ref.read(tripRequestProvider);
    if (current.quote == null) {
      notifier.setQuote(quote);
      notifier.selectOption(opt);
    } else if (current.selectedOption == null) {
      notifier.selectOption(opt);
    }
    if (current.origin == null) {
      notifier.setOrigin(origin.latitude, origin.longitude);
    }
    if (current.destination == null) {
      notifier.setDestination(dest.latitude, dest.longitude);
    }

    _d._origin ??= origin;
    _d._destination ??= dest;
    _d._originConfirmed = true;
    if ((_d._originDisplayLabel == null ||
            _d._originDisplayLabel!.trim().isEmpty) &&
        _d._matchingRetryOriginLabel != null) {
      _d._originDisplayLabel = _d._matchingRetryOriginLabel;
    }
    if ((_d._destinationDisplayLabel == null ||
            _d._destinationDisplayLabel!.trim().isEmpty) &&
        _d._matchingRetryDestinationLabel != null) {
      _d._destinationDisplayLabel = _d._matchingRetryDestinationLabel;
    }
    if ((_d._routeOverviewEncoded == null ||
            _d._routeOverviewEncoded!.isEmpty) &&
        _d._matchingRetryRouteEncoded != null) {
      _d._routeOverviewEncoded = _d._matchingRetryRouteEncoded;
    }
  }

  /// Stage 3: invalida ofertas en servidor y mantiene el overlay (Continuar / Cancelar).
  /// No cancela si el viaje ya fue aceptado (GET previo + cancelScope=matching).
  Future<void> _onSearchingStage3Reached() async {
    if (_d._searchingStage3CancelInFlight || _d._searchingHoldUi) return;
    _captureMatchingRetryDraft();
    // Hold UI ANTES de limpiar tripId: evita un frame sin overlay (remount → reinicio visual).
    setState(() {
      _d._searchingHoldUi = true;
      _d._keepDraftAfterMatchingCancel = true;
      _d._searchingStage3CancelInFlight = true;
    });
    final tripId = ref.read(tripRequestProvider).tripId;
    final rtStatus = ref.read(passengerRealtimeProvider).status;
    if (passengerTripIsTrackingDriver(rtStatus) || rtStatus == 'completed') {
      if (mounted) {
        setState(() {
          _d._searchingHoldUi = false;
          _d._keepDraftAfterMatchingCancel = false;
          _d._searchingStage3CancelInFlight = false;
        });
      }
      return;
    }
    final token = await AuthService.getValidToken();
    if (tripId != null &&
        tripId.isNotEmpty &&
        token != null &&
        token.isNotEmpty) {
      try {
        final live = await TripsApi(token: token).getPassengerTripStatus(
          tripId: tripId,
        );
        if (passengerTripIsTrackingDriver(live.status) ||
            live.status == 'completed') {
          await _exitSearchingHoldForAssignedTrip(tripId);
          return;
        }
      } catch (e, st) {
        debugPrint('[SearchStage3Status] $e\n$st');
      }
      try {
        await TripsApi(token: token).cancelPassengerTrip(
          tripId: tripId,
          cancelScope: 'matching',
        );
      } on DioException catch (e, st) {
        final code = TexiBackendError.codeFromResponse(e.response?.data);
        debugPrint('[SearchStage3Cancel] code=$code $e\n$st');
        if (code == 'TRIP_MATCHING_ALREADY_ASSIGNED') {
          await _exitSearchingHoldForAssignedTrip(tripId);
          return;
        }
      } catch (e, st) {
        debugPrint('[SearchStage3Cancel] $e\n$st');
      }
    }
    if (!mounted) return;
    ref.read(passengerRealtimeProvider.notifier).disconnect();
    ref.read(tripRequestProvider.notifier).clearTripIdKeepingRoute();
    await TripSessionStorage.clearActiveTripId();
    if (tripId != null) {
      PassengerNotificationService.clearArrivedNotificationDedupe(tripId);
    }
    if (mounted) {
      setState(() => _d._searchingStage3CancelInFlight = false);
    }
  }

  Future<void> _exitSearchingHoldForAssignedTrip(String tripId) async {
    if (mounted) {
      setState(() {
        _d._searchingHoldUi = false;
        _d._keepDraftAfterMatchingCancel = false;
        _d._matchingSubmitUi = false;
        _d._searchingStage3CancelInFlight = false;
      });
    }
    try {
      await ref
          .read(passengerRealtimeProvider.notifier)
          .syncTripStatusFromApi(tripId: tripId, force: true);
    } catch (_) {}
  }

  /// Continuar: nueva petición de matching + overlay reiniciado en etapa 1.
  Future<void> _restartSearchingTripAfterTimeout() async {
    _captureMatchingRetryDraft();
    _restoreMatchingRetryDraftIfNeeded();
    final tripState = ref.read(tripRequestProvider);
    final q = tripState.quote ?? _d._matchingRetryQuote;
    final opt = tripState.selectedOption ?? _d._matchingRetryOption;
    final origin = _d._origin ?? _d._matchingRetryOrigin;
    final dest = _d._destination ?? _d._matchingRetryDestination;
    if (q == null || opt == null || origin == null || dest == null) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        if (loc != null) {
          PassengerTripToast.show(
            context,
            message: loc.tripRequestUnavailable,
            icon: Icons.error_outline_rounded,
            accent: AppColors.error,
          );
        }
      }
      return;
    }

    // Por si aún hubiera tripId (race antes de stage3 cancel).
    final lingeringId = tripState.tripId;
    if (lingeringId != null && lingeringId.isNotEmpty) {
      final token = await AuthService.getValidToken();
      if (token != null && token.isNotEmpty) {
        try {
          await TripsApi(token: token).cancelPassengerTrip(
            tripId: lingeringId,
            cancelScope: 'matching',
          );
        } catch (_) {}
      }
      ref.read(passengerRealtimeProvider.notifier).disconnect();
      ref.read(tripRequestProvider.notifier).clearTripIdKeepingRoute();
      await TripSessionStorage.clearActiveTripId();
    }

    if (!mounted) return;
    final submitGeneration = _d._tripSubmitGeneration;
    setState(() {
      _d._submittingTrip = true;
      _d._matchingSubmitUi = true;
      _d._searchingHoldUi = false;
      _d._keepDraftAfterMatchingCancel = true;
      _d._searchingOriginCameraDone = false;
      _d._searchingOverlayGeneration += 1;
    });
    final l10n = AppLocalizations.of(context)!;
    final originLabel = (_d._originDisplayLabel != null &&
            _d._originDisplayLabel!.trim().isNotEmpty)
        ? _d._originDisplayLabel!.trim()
        : (_d._matchingRetryOriginLabel?.trim().isNotEmpty == true
            ? _d._matchingRetryOriginLabel!.trim()
            : '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}');
    final destinationLabel = (_d._destinationDisplayLabel != null &&
            _d._destinationDisplayLabel!.trim().isNotEmpty)
        ? _d._destinationDisplayLabel!.trim()
        : (_d._matchingRetryDestinationLabel?.trim().isNotEmpty == true
            ? _d._matchingRetryDestinationLabel!.trim()
            : '${dest.latitude.toStringAsFixed(6)},${dest.longitude.toStringAsFixed(6)}');

    final result = await submitPassengerTripFromQuote(
      ref: ref,
      context: context,
      quote: q,
      option: opt,
      originLat: origin.latitude,
      originLng: origin.longitude,
      destinationLat: dest.latitude,
      destinationLng: dest.longitude,
      originAddress: originLabel,
      destinationAddress: destinationLabel,
      routeOverviewEncoded:
          _d._routeOverviewEncoded ?? _d._matchingRetryRouteEncoded,
      ensureDeviceGpsForNewTrip: _ensureDeviceGpsForNewTrip,
      skipPhoneProfileCheck: true,
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
      if (result.kind == PassengerTripSubmitResultKind.success ||
          result.kind == PassengerTripSubmitResultKind.recoveredExisting) {
        _d._searchingHoldUi = false;
        // Sigue true hasta accepted: un `cancelled` tardío del viaje anterior
        // no debe borrar la nueva búsqueda.
        _d._keepDraftAfterMatchingCancel = true;
        _d._searchingOriginCameraDone = false;
      } else {
        _d._searchingHoldUi = true;
        _d._keepDraftAfterMatchingCancel = true;
      }
    });
    if (result.kind == PassengerTripSubmitResultKind.phoneRequired) {
      await handlePassengerTripPhoneRequired(
        context,
        ref,
        result.kind,
        returnTo: 'trip_request',
      );
      return;
    }
    if (result.kind == PassengerTripSubmitResultKind.error) {
      final msg = result.message ?? l10n.tripRequestUnavailable;
      if (msg == l10n.tripNoDriversAvailable) {
        PassengerTripToast.show(
          context,
          message: msg,
          icon: Icons.directions_car_outlined,
        );
        return;
      }
      PassengerTripToast.show(
        context,
        message: msg,
        icon: Icons.error_outline_rounded,
        accent: AppColors.error,
      );
    }
  }

  Future<bool> _discardSubmitIfGenerationChanged({
    required int generation,
    required PassengerTripSubmitResult result,
  }) async {
    if (generation == _d._tripSubmitGeneration) return false;
    final tid = result.tripId ?? ref.read(tripRequestProvider).tripId;
    if (tid != null &&
        tid.isNotEmpty &&
        (result.kind == PassengerTripSubmitResultKind.success ||
            result.kind == PassengerTripSubmitResultKind.recoveredExisting)) {
      try {
        final token = await AuthService.getValidToken();
        if (token != null && token.isNotEmpty) {
          await TripsApi(token: token).cancelPassengerTrip(
            tripId: tid,
            cancelScope: 'matching',
          );
        }
      } catch (_) {}
      if (mounted) {
        ref.read(passengerRealtimeProvider.notifier).disconnect();
        ref.read(tripRequestProvider.notifier).clearTripIdKeepingRoute();
        await TripSessionStorage.clearActiveTripId();
      }
    }
    if (mounted) {
      setState(() {
        _d._submittingTrip = false;
        _d._matchingSubmitUi = false;
      });
    }
    return true;
  }

  void _syncSearchingNearbyPolling(bool isSearching) {
    if (!isSearching) {
      _d._searchingNearbyTimer?.cancel();
      _d._searchingNearbyTimer = null;
      _d._searchingOriginCameraDone = false;
      _d._searchingRadarAnchor.value = null;
      if (_d._searchingMapRadarController.isAnimating) {
        _d._searchingMapRadarController.stop();
        _d._searchingMapRadarController.reset();
      }
      return;
    }
    if (!_d._searchingMapRadarController.isAnimating) {
      _d._searchingMapRadarController.repeat();
    }
    _ensureSearchingCameraOnOrigin();
    if (_d._searchingNearbyTimer != null) return;
    unawaited(_refreshSearchingNearbyDrivers()); // defined on map mixin
    _d._searchingNearbyTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(_refreshSearchingNearbyDrivers()),
    );
  }

  /// Cancela la búsqueda: **POST /passengers/trips/:id/cancel** para invalidar ofertas en servidor
  /// y que los conductores no sigan viendo la solicitud. Si falla la red, no limpiamos estado.
  /// Nunca cancela un viaje ya aceptado/en curso (protección ante overlay erróneo).
  Future<void> _cancelSearchingTrip() async {
    // Cancelar explícito: no conservar overlay/borrador del timeout (Continuar).
    _d._keepDraftAfterMatchingCancel = false;
    final tripId = ref.read(tripRequestProvider).tripId;
    final holdOnly =
        (_d._searchingHoldUi || _d._matchingSubmitUi) &&
        (tripId == null || tripId.isEmpty);
    if (_d._matchingSubmitUi) {
      _d._tripSubmitGeneration++;
    }
    final rtStatus = ref.read(passengerRealtimeProvider).status;
    if (!holdOnly &&
        (passengerTripIsTrackingDriver(rtStatus) || rtStatus == 'completed')) {
      if (kDebugMode) {
        debugPrint(
          '[CancelTrip] bloqueado: viaje activo status=$rtStatus tripId=$tripId',
        );
      }
      if (mounted) {
        final loc = AppLocalizations.of(context);
        if (loc != null) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(loc.tripCancelBlockedActiveBody)),
          );
        }
      }
      return;
    }
    final token = await AuthService.getValidToken();
    if (tripId != null &&
        tripId.isNotEmpty &&
        token != null &&
        token.isNotEmpty) {
      try {
        await TripsApi(token: token).cancelPassengerTrip(tripId: tripId);
      } catch (e, st) {
        debugPrint('[CancelTrip] $e\n$st');
        if (mounted) {
          final loc = AppLocalizations.of(context);
          if (loc != null) {
            ScaffoldMessenger.maybeOf(
              context,
            )?.showSnackBar(SnackBar(content: Text(loc.commonError)));
          }
        }
        return;
      }
    }
    if (!mounted) return;
    if (tripId != null) {
      PassengerNotificationService.clearArrivedNotificationDedupe(tripId);
    }
    await _resetTripSessionToDraftHome(tripIdForGuard: tripId);
  }

  /// Escape de recuperación: cancela solo matching. Si el viaje ya está
  /// asignado, rehidrata. Si no existe, limpia el estado local.
  Future<void> _cancelMatchingFromRecovery(String tripId) async {
    final rtStatus = ref.read(passengerRealtimeProvider).status;
    if (passengerTripIsTrackingDriver(rtStatus) || rtStatus == 'completed') {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        if (loc != null) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(loc.tripCancelBlockedActiveBody)),
          );
        }
      }
      return;
    }
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) return;
    try {
      await TripsApi(token: token).cancelPassengerTrip(
        tripId: tripId,
        cancelScope: 'matching',
      );
    } on DioException catch (e) {
      final code = TexiBackendError.codeFromResponse(e.response?.data);
      if (code == 'TRIP_MATCHING_ALREADY_ASSIGNED') {
        await ref
            .read(passengerRealtimeProvider.notifier)
            .syncTripStatusFromApi(tripId: tripId, force: true);
        return;
      }
      if (code == 'TRIP_NOT_FOUND' || e.response?.statusCode == 404) {
        await _resetTripSessionToDraftHome(tripIdForGuard: tripId);
        return;
      }
      if (mounted) {
        final loc = AppLocalizations.of(context);
        if (loc != null) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(loc.commonError)),
          );
        }
      }
      return;
    } catch (_) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        if (loc != null) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(loc.commonError)),
          );
        }
      }
      return;
    }
    if (!mounted) return;
    PassengerNotificationService.clearArrivedNotificationDedupe(tripId);
    await _resetTripSessionToDraftHome(tripIdForGuard: tripId);
  }

  /// Cancelar viaje ya asignado (`accepted`/`arrived`). No usa overlay ni `cancelScope=matching`.
  Future<void> _cancelAssignedTrip() async {
    final tripId = ref.read(tripRequestProvider).tripId ??
        ref.read(passengerRealtimeProvider).activeTripId;
    final rt = ref.read(passengerRealtimeProvider);
    if (tripId == null || tripId.isEmpty) return;
    if (!passengerTripCanCancelAssigned(rt.status)) return;
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    final localeCode = Localizations.localeOf(context).languageCode;
    final choice = await showTripCancelReasonSheet(
      context: context,
      connected: rt.connected,
      loadReasons: () async {
        final token = await AuthService.getValidToken();
        if (token == null || token.isEmpty) {
          throw StateError('NO_TOKEN');
        }
        return TripsApi(token: token).getPassengerTripCancelReasons(
          tripId: tripId,
          locale: localeCode,
        );
      },
    );
    if (choice == null || !mounted) return;
    final token = await AuthService.getValidToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(loc.tripCancelNeedConnection)),
      );
      return;
    }
    try {
      await TripsApi(token: token).cancelPassengerTrip(
        tripId: tripId,
        reasonCode: choice.code,
        reasonNote: choice.note,
      );
    } catch (e, st) {
      debugPrint('[CancelAssignedTrip] $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(_passengerCancelErrorText(loc, e))),
      );
      return;
    }
    if (!mounted) return;
    PassengerNotificationService.clearArrivedNotificationDedupe(tripId);
    await _resetTripSessionToDraftHome(tripIdForGuard: tripId);
  }

  String _passengerCancelErrorText(AppLocalizations loc, Object e) {
    final code = TexiBackendError.codeFromDio(e);
    if (code == 'TRIP_CANCEL_WAIT_NOT_ELIGIBLE') {
      switch (TexiBackendError.waitBlockReasonFromDio(e)) {
        case 'waiting':
          return loc.tripCancelWaitStillWaiting;
        case 'grace':
          return loc.tripCancelWaitStillGrace;
        case 'geofence':
          return loc.tripCancelWaitNotAtPickup;
        case 'no_location':
          return loc.tripCancelWaitNoLocation;
        default:
          return loc.tripCancelWaitNotEligible;
      }
    }
    if (code == 'TRIP_CANCEL_EN_ROUTE_NOT_ELIGIBLE') {
      return loc.tripCancelEnRouteTooSoon;
    }
    if (code == 'TRIP_ALREADY_FINALIZED') {
      return loc.tripAlreadyFinalized;
    }
    if (code == 'TRIP_CANNOT_CANCEL') {
      return loc.tripCannotCancelRace;
    }
    return loc.tripCancelError;
  }

  Future<void> _ensureTripNotificationDisclosure() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    await passengerEnsureNotificationDisclosureForTripUpdates(context, l10n);
  }
}

