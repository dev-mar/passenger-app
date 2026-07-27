part of 'trip_request_screen.dart';

/// Listeners Riverpod del viaje (realtime + tripId) extraídos del build.
mixin _TripRequestScreenListenersMixin on ConsumerState<TripRequestScreen> {
  _TripRequestScreenState get _trip => this as _TripRequestScreenState;

  void registerTripRequestRefListeners() {
    ref.listen<PassengerRealtimeState>(passengerRealtimeProvider, (
      previous,
      next,
    ) {
      if (previous != null) {
        _trip._syncTripUnreadCounter(previous, next);
      }
      final wasEn = passengerTripIsEnRouteToDestination(previous?.status);
      final nowEn = passengerTripIsEnRouteToDestination(next.status);
      if (!wasEn && nowEn) {
        _trip._schedulePassengerEnRouteRouteRefresh(immediate: true);
      } else if (wasEn && !nowEn) {
        _trip._passengerEnRouteRouteDebounce?.cancel();
        if (mounted) {
          setState(() => _trip._passengerEnRouteToDestPoints = null);
        }
      }

      final was = passengerTripChatPhaseActive(previous?.status);
      final now = passengerTripChatPhaseActive(next.status);
      if (was && !now && _trip._tripChatSheetDisplayed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).maybePop();
        });
      }

      final wasAccepted = passengerTripIsTrackingDriver(previous?.status);
      final nowAccepted = passengerTripIsTrackingDriver(next.status);
      if (!wasAccepted && nowAccepted && mounted) {
        unawaited(_trip._ensureTripNotificationDisclosure());
      }
    });

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
          _trip._passengerEnRouteRouteDebounce?.cancel();
          setState(() {
            _trip._tripChatUnreadCount = 0;
            _trip._tripChatReadCursor = 0;
            if (!_trip._tripEndResetInProgress) {
              _trip._ratingDoneTripId = null;
              _trip._ratingDone = false;
              _trip._ratingSheetShownForTripId = null;
            }
            _trip._passengerEnRouteToDestPoints = null;
          });
        });
        return;
      }

      schedule(() {
        setState(() => _trip._ratingSheetShownForTripId = null);
        unawaited(() async {
          final done = await TripSessionStorage.isRatingDone(id);
          if (!mounted) return;
          if (ref.read(tripRequestProvider).tripId != id) return;
          setState(() {
            _trip._ratingDoneTripId = id;
            _trip._ratingDone = done;
          });
        }());
      });
    });
  }
}
