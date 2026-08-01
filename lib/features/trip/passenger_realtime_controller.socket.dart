part of 'passenger_realtime_controller.dart';

mixin _PassengerRealtimeSocketMixin on StateNotifier<PassengerRealtimeState> {
  PassengerRealtimeController get _rt => this as PassengerRealtimeController;

  String _socketConnectErrorToCode(dynamic data) {
    final s = data?.toString() ?? '';
    if (s.contains('RBAC_FORBIDDEN')) return 'RBAC_FORBIDDEN';
    if (s.contains('RBAC_NO_IDENTITY')) return 'RBAC_NO_IDENTITY';
    if (s.contains('RBAC_NO_AUTH')) return 'RBAC_NO_AUTH';
    if (s.contains('UNAUTHORIZED') ||
        s.contains('NO_TOKEN') ||
        s.contains('AUTH') ||
        s.contains('SESSION_SUPERSEDED')) {
      return 'NO_TOKEN';
    }
    return 'SOCKET';
  }

  void _bindPassengerRealtimeSocketHandlers(
    io.Socket socket,
    String tripId,
    QuoteResponse? quote,
  ) {
    void onSocketReady(String reason) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] $reason a ${AppConfig.baseUrlSocket}');
      }
      _rt._connectTimeoutTimer?.cancel();
      _rt._connectTimeoutTimer = null;
      _rt._connectStartedAt = null;
      // No forzar 'searching': si status es null estamos recuperando un viaje
      // (reabrir/minimizar). El sync REST fija el estado real.
      state = state.copyWith(
        connecting: false,
        connected: true,
        errorCode: null,
        activeTripId: tripId,
        quote: quote ?? state.quote,
        chatMessages: state.chatMessages,
        tripChatErrorCode: state.tripChatErrorCode,
      );
      // Sync REST en paralelo; no debe ser el único camino de status.
      unawaited(_rt.syncTripStatusFromApi(tripId: tripId, force: true));
    }

    socket.onConnect((_) => onSocketReady('conectado'));
    socket.on('reconnect', (_) => onSocketReady('reconectado'));
    socket.onReconnect((_) => onSocketReady('reconectado'));

    socket.onConnectError((data) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] connect_error: $data');
      }
      _rt._connectTimeoutTimer?.cancel();
      _rt._connectTimeoutTimer = null;
      _rt._connectStartedAt = null;
      state = state.copyWith(
        connecting: false,
        connected: false,
        errorCode: _socketConnectErrorToCode(data),
      );
    });

    socket.onDisconnect((_) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] disconnect');
      }
      state = state.copyWith(connected: false);
    });

    socket.on('passenger:force_logout', (_) {
      markPassengerSessionExpelled();
      unawaited(AuthService.logout());
      AuthService.onSessionExpired?.call();
    });

    socket.on('trip:accepted', (data) {
      try {
        if (data is! Map) return;
        final tripIdData = data['tripId']?.toString();
        if (tripIdData == null || tripIdData != tripId) return;
        final rawName =
            data['fullName']?.toString() ??
            data['displayName']?.toString() ??
            data['display_name']?.toString() ??
            data['name']?.toString() ??
            data['driverName']?.toString() ??
            data['driver_name']?.toString();
        final driverName = displayDriverName(rawName);
        final eventMap = Map<String, dynamic>.from(data);
        final carColor = resolvePassengerTripCarColor(eventMap);
        final carPlate = resolvePassengerTripCarPlate(eventMap);
        final carModel = resolvePassengerTripCarModel(eventMap);
        final driverPhotoUrl = normalizeDriverPhotoUrl(
          data['profilePhotoUrl']?.toString() ??
              data['picture_profile']?.toString() ??
              data['driverPhotoUrl']?.toString() ??
              data['photoUrl']?.toString() ??
              data['avatarUrl']?.toString() ??
              data['profile_photo_url']?.toString() ??
              data['driver_photo_url']?.toString(),
        );
        final driverPhotoExpiresAt = parseDriverPhotoExpiresAt(
          data['profilePhotoExpiresAt'],
        );
        final ratingRaw = data['driverRating'] ?? data['averageRating'];
        final ratingsCountRaw =
            data['driverRatingsCount'] ?? data['ratingsCount'];
        final driverRating = ratingRaw is num
            ? ratingRaw.toDouble()
            : double.tryParse('$ratingRaw');
        final driverRatingsCount = ratingsCountRaw is num
            ? ratingsCountRaw.toInt()
            : int.tryParse('$ratingsCountRaw');
        final currencyCode = (data['currencyCode'] ?? data['currency'])
            ?.toString();
        if (kDebugMode) {
          debugPrint(
            '[PASSENGER_RT] trip:accepted tripId=$tripIdData driver=$driverName',
          );
        }
        state = state.copyWith(
          activeTripId: tripIdData,
          status: 'accepted',
          driverName: driverName,
          carColor: carColor,
          carPlate: carPlate,
          carModel: carModel,
          driverRating: driverRating,
          driverRatingsCount: driverRatingsCount,
          currencyCode: currencyCode ?? state.currencyCode,
          driverPhotoUrl: driverPhotoUrl,
          driverPhotoExpiresAt: driverPhotoExpiresAt,
          tripChatErrorCode: state.tripChatErrorCode,
        );
        unawaited(() async {
          await TripSessionStorage.saveLastKnownStatus(
            tripId: tripIdData,
            status: 'accepted',
          );
          await TripSessionStorage.cacheDriverInfo(
            tripId: tripIdData,
            driverName: driverName,
            carColor: carColor,
            carPlate: carPlate,
            carModel: carModel,
            driverRating: driverRating,
            driverRatingsCount: driverRatingsCount,
            currencyCode: currencyCode,
            driverPhotoUrl: driverPhotoUrl,
            driverPhotoExpiresAt: driverPhotoExpiresAt?.toIso8601String(),
          );
        }());
        // Completar coords/foto vía REST sin bloquear el cambio de UI.
        unawaited(_rt.syncTripStatusFromApi(tripId: tripIdData, force: true));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PASSENGER_RT] Error manejando trip:accepted: $e');
        }
      }
    });

    socket.on('trip:status', (data) {
      try {
        if (data is! Map) return;
        final tripIdData = data['tripId']?.toString();
        final newStatus = data['status']?.toString();
        if (tripIdData == null || newStatus == null) return;
        if (tripIdData != tripId) return;
        if (kDebugMode) {
          debugPrint(
            '[PASSENGER_RT] trip:status tripId=$tripIdData status=$newStatus',
          );
        }
        final nameFromEvent =
            data['fullName']?.toString() ??
            data['displayName']?.toString() ??
            data['display_name']?.toString() ??
            data['name']?.toString() ??
            data['driverName']?.toString() ??
            data['driver_name']?.toString();
        final mergedRaw =
            (nameFromEvent != null && nameFromEvent.trim().isNotEmpty)
            ? nameFromEvent.trim()
            : state.driverName;
        final newDriverName = displayDriverName(mergedRaw);
        final eventMap = Map<String, dynamic>.from(data);
        final carColor = resolvePassengerTripCarColor(eventMap);
        final carPlate = resolvePassengerTripCarPlate(eventMap);
        final carModel = resolvePassengerTripCarModel(eventMap);
        final ratingRaw = data['driverRating'] ?? data['averageRating'];
        final ratingsCountRaw =
            data['driverRatingsCount'] ?? data['ratingsCount'];
        final driverRating = ratingRaw is num
            ? ratingRaw.toDouble()
            : double.tryParse('$ratingRaw');
        final driverRatingsCount = ratingsCountRaw is num
            ? ratingsCountRaw.toInt()
            : int.tryParse('$ratingsCountRaw');
        final currencyCode = (data['currencyCode'] ?? data['currency'])
            ?.toString();
        if (newStatus == 'arrived' && state.status != 'arrived') {
          final fg = PassengerAppVisibility.isInForeground.value;
          if (fg) {
            SystemSound.play(SystemSoundType.alert);
          }
          unawaited(
            PassengerNotificationService.instance.showDriverArrivedIfBackground(
              isAppInForeground: fg,
              tripId: tripIdData,
              driverName: newDriverName == driverNameFallbackDefault
                  ? null
                  : newDriverName,
            ),
          );
        }
        final chatOk = passengerTripChatPhaseActive(newStatus);
        state = state.copyWith(
          activeTripId: tripIdData,
          status: newStatus,
          driverName: newDriverName,
          carColor: carColor ?? state.carColor,
          carPlate: carPlate ?? state.carPlate,
          carModel: carModel ?? state.carModel,
          driverRating: driverRating ?? state.driverRating,
          driverRatingsCount: driverRatingsCount ?? state.driverRatingsCount,
          currencyCode: currencyCode ?? state.currencyCode,
          chatMessages: chatOk ? state.chatMessages : const [],
          tripChatErrorCode: chatOk ? state.tripChatErrorCode : null,
        );
        unawaited(
          TripSessionStorage.saveLastKnownStatus(
            tripId: tripIdData,
            status: newStatus,
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PASSENGER_RT] Error manejando trip:status: $e');
        }
      }
    });

    socket.on('trip:driver_location', (data) {
      if (data is! Map) return;
      _rt._handleTripDriverLocation(Map<String, dynamic>.from(data), tripId);
    });

    socket.on('trip:arrival_reminder', (data) {
      if (data is! Map) return;
      _rt._handleTripArrivalReminder(Map<String, dynamic>.from(data), tripId);
    });

    socket.on('trip:chat:new', (data) {
      if (data is! Map) return;
      _rt._handleTripChatNew(Map<String, dynamic>.from(data), tripId);
    });

    socket.on('trip:chat:error', (data) {
      _rt._handleTripChatError(data);
    });
  }

  bool get _socketLive {
    final s = _rt._socket;
    return s != null && s.connected;
  }

  /// Garantiza socket vivo para chat / eventos. Reconecta si hace falta.
  Future<bool> ensureSocketConnected({
    required String tripId,
    QuoteResponse? quote,
  }) async {
    if (_socketLive && state.activeTripId == tripId) {
      if (!state.connected) {
        state = state.copyWith(connected: true, errorCode: null);
      }
      return true;
    }
    await connect(
      tripId: tripId,
      quote: quote ?? state.quote,
      assumeAwaitingDriver: false,
    );
    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(deadline)) {
      if (_socketLive) {
        if (!state.connected) {
          state = state.copyWith(connected: true, errorCode: null);
        }
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    return _socketLive;
  }

  /// [assumeAwaitingDriver]: solo `true` al crear una solicitud nueva.
  /// En rehidratación/reconexión de viaje activo no debe usarse: evita el overlay
  /// "Buscando conductor" + Cancelar sobre un viaje ya aceptado.
  Future<void> connect({
    required String tripId,
    QuoteResponse? quote,
    bool assumeAwaitingDriver = false,
  }) async {
    if (_socketLive && state.activeTripId == tripId) {
      state = state.copyWith(
        connected: true,
        errorCode: null,
        quote: quote ?? state.quote,
      );
      if (kDebugMode) {
        debugPrint(
          '[PASSENGER_RT] Socket ya activo tripId=$tripId; sync REST',
        );
      }
      unawaited(_rt.syncTripStatusFromApi(tripId: tripId, force: true));
      return;
    }

    if (state.connecting &&
        state.activeTripId == tripId &&
        _rt._socket != null) {
      state = state.copyWith(quote: quote ?? state.quote);
      if (kDebugMode) {
        debugPrint(
          '[PASSENGER_RT] Conexión en curso tripId=$tripId; esperando',
        );
      }
      return;
    }

    // Preservar fase/UI del viaje antes de disconnect() (que resetea a initial).
    final preservedTripId = state.activeTripId;
    final preservedStatus = state.status;
    final preservedQuote = state.quote;
    final preservedDriverName = state.driverName;
    final preservedCarColor = state.carColor;
    final preservedCarPlate = state.carPlate;
    final preservedCarModel = state.carModel;
    final preservedDriverRating = state.driverRating;
    final preservedDriverRatingsCount = state.driverRatingsCount;
    final preservedCurrencyCode = state.currencyCode;
    final preservedDriverPhotoUrl = state.driverPhotoUrl;
    final preservedDriverPhotoExpiresAt = state.driverPhotoExpiresAt;
    final preservedDriverLat = state.driverLat;
    final preservedDriverLng = state.driverLng;
    final preservedDriverBearing = state.driverBearing;
    final preservedChatMessages = List<TripChatMessage>.from(state.chatMessages);
    final preservedTripChatErrorCode = state.tripChatErrorCode;
    final sameTripReconnect =
        preservedTripId == null || preservedTripId == tripId;

    if (_rt._socket != null || state.connecting) {
      if (kDebugMode) {
        debugPrint(
          '[PASSENGER_RT] Reiniciando socket '
          '(trip estado=${state.activeTripId}, nuevo=$tripId)',
        );
      }
      _rt.disconnect();
    }

    if (state.connecting) {
      final start = _rt._connectStartedAt;
      if (start != null &&
          DateTime.now().difference(start) < PassengerRealtimeController._connectStuckAfter) {
        return;
      }
      _rt._connectTimeoutTimer?.cancel();
      _rt._connectTimeoutTimer = null;
      _rt._socket?.dispose();
      _rt._socket = null;
      _rt._connectStartedAt = null;
      state = state.copyWith(connecting: false);
    }
    _rt._tearDown = false;
    _rt._connectStartedAt = DateTime.now();

    final String? nextStatus;
    if (assumeAwaitingDriver) {
      nextStatus = 'searching';
    } else if (sameTripReconnect && preservedStatus != null) {
      nextStatus = preservedStatus;
    } else {
      nextStatus = state.status;
    }

    state = state.copyWith(
      connecting: true,
      errorCode: null,
      activeTripId: tripId,
      status: nextStatus,
      quote: quote ?? preservedQuote ?? state.quote,
      driverName: sameTripReconnect
          ? (preservedDriverName ?? state.driverName)
          : state.driverName,
      carColor: sameTripReconnect
          ? (preservedCarColor ?? state.carColor)
          : state.carColor,
      carPlate: sameTripReconnect
          ? (preservedCarPlate ?? state.carPlate)
          : state.carPlate,
      carModel: sameTripReconnect
          ? (preservedCarModel ?? state.carModel)
          : state.carModel,
      driverRating: sameTripReconnect
          ? (preservedDriverRating ?? state.driverRating)
          : state.driverRating,
      driverRatingsCount: sameTripReconnect
          ? (preservedDriverRatingsCount ?? state.driverRatingsCount)
          : state.driverRatingsCount,
      currencyCode: sameTripReconnect
          ? (preservedCurrencyCode ?? state.currencyCode)
          : state.currencyCode,
      driverPhotoUrl: sameTripReconnect
          ? (preservedDriverPhotoUrl ?? state.driverPhotoUrl)
          : state.driverPhotoUrl,
      driverPhotoExpiresAt: sameTripReconnect
          ? (preservedDriverPhotoExpiresAt ?? state.driverPhotoExpiresAt)
          : state.driverPhotoExpiresAt,
      driverLat: sameTripReconnect
          ? (preservedDriverLat ?? state.driverLat)
          : state.driverLat,
      driverLng: sameTripReconnect
          ? (preservedDriverLng ?? state.driverLng)
          : state.driverLng,
      driverBearing: sameTripReconnect
          ? (preservedDriverBearing ?? state.driverBearing)
          : state.driverBearing,
      chatMessages: sameTripReconnect
          ? preservedChatMessages
          : state.chatMessages,
      tripChatErrorCode:
          sameTripReconnect ? preservedTripChatErrorCode : null,
    );
    if (kDebugMode) {
      debugPrint('[PASSENGER_RT] Conectando Socket.IO para tripId=$tripId');
    }

    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          connecting: false,
          connected: false,
          errorCode: 'NO_TOKEN',
        );
        return;
      }

      final url = AppConfig.baseUrlSocket;
      final opts = io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .enableForceNew()
          .setPath('/socket.io/')
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build();

      final socket = io.io(url, opts);
      _rt._socket = socket;
      // Asegura handshake aunque autoConnect esté off en alguna build.
      if (!socket.connected) {
        socket.connect();
      }

      _rt._connectTimeoutTimer?.cancel();
      _rt._connectTimeoutTimer = Timer(PassengerRealtimeController._connectHardTimeout, () {
        if (_rt._tearDown) return;
        if (!state.connecting) return;
        if (kDebugMode) {
          debugPrint('[PASSENGER_RT] timeout conectando; liberando estado');
        }
        _rt._socket?.dispose();
        _rt._socket = null;
        _rt._connectTimeoutTimer = null;
        _rt._connectStartedAt = null;
        state = state.copyWith(
          connecting: false,
          connected: false,
          errorCode: 'SOCKET_TIMEOUT',
        );
      });

      _bindPassengerRealtimeSocketHandlers(socket, tripId, quote);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] Error general conectando: $e');
      }
      _rt._connectTimeoutTimer?.cancel();
      _rt._connectTimeoutTimer = null;
      _rt._connectStartedAt = null;
      state = state.copyWith(
        connecting: false,
        connected: false,
        errorCode: 'UNKNOWN',
      );
    }
  }
}
