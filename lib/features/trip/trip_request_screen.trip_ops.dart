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
        _d._draftEditTarget = PassengerDraftEditTarget.none;
        if (_d._origin != null) {
          // Para el siguiente viaje, empezamos forzando confirmaci├│n del origen.
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
  void _onSearchingKeepWaitingSoftRetry() {
    final tid = ref.read(tripRequestProvider).tripId;
    if (tid == null || tid.isEmpty) return;
    final quote = ref.read(tripRequestProvider).quote;
    unawaited(() async {
      await ref
          .read(passengerRealtimeProvider.notifier)
          .syncTripStatusFromApi(tripId: tid, force: true);
      if (!mounted) return;
      final rt = ref.read(passengerRealtimeProvider);
      if (!rt.connected || rt.errorCode != null) {
        ref
            .read(passengerRealtimeProvider.notifier)
            .connect(tripId: tid, quote: quote);
      }
    }());
  }

  /// Cancela la b├║squeda: **POST /passengers/trips/:id/cancel** para invalidar ofertas en servidor
  /// y que los conductores no sigan viendo la solicitud. Si falla la red, no limpiamos estado.
  Future<void> _cancelSearchingTrip() async {
    final tripId = ref.read(tripRequestProvider).tripId;
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
    _d._routeRequestToken++;
    ref.read(passengerRealtimeProvider.notifier).disconnect();
    clearTripRecoverySnackTracking(ref);
    ref.read(tripRequestProvider.notifier).reset();
    ref.read(passengerTripMapUiResetTickProvider.notifier).state++;
    unawaited(TripSessionStorage.clearActiveTripId());
    _d._passengerEnRouteRouteDebounce?.cancel();
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
      _d._draftEditTarget = PassengerDraftEditTarget.none;
      if (_d._origin != null) {
        _d._pickingOrigin = true;
        _d._activeStop = ActiveStop.none;
      }
    });
    unawaited(_recenterMapToDeviceGpsAfterTripEnd());
  }

  Future<void> _ensureTripNotificationDisclosure() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    await passengerEnsureNotificationDisclosureForTripUpdates(context, l10n);
  }
}

