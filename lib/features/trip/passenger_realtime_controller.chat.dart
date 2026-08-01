part of 'passenger_realtime_controller.dart';

mixin _PassengerRealtimeChatMixin on StateNotifier<PassengerRealtimeState> {
  PassengerRealtimeController get _rt => this as PassengerRealtimeController;

  Future<void> sendTripChatTemplate({
    required String tripId,
    required String templateCode,
  }) async {
    if (!passengerTripChatPhaseActive(state.status)) {
      state = state.copyWith(tripChatErrorCode: 'TRIP_CHAT_NOT_AVAILABLE');
      return;
    }
    final live = await _rt.ensureSocketConnected(tripId: tripId);
    if (!live) {
      state = state.copyWith(tripChatErrorCode: 'SOCKET');
      return;
    }
    _rt._socket!.emit('trip:chat:send', {
      'tripId': tripId,
      'messageKind': 'template',
      'templateCode': templateCode,
    });
  }

  Future<void> sendTripChatText({
    required String tripId,
    required String text,
  }) async {
    final sanitized = text.trim();
    if (sanitized.isEmpty) return;
    if (!passengerTripChatPhaseActive(state.status)) {
      state = state.copyWith(tripChatErrorCode: 'TRIP_CHAT_NOT_AVAILABLE');
      return;
    }
    final live = await _rt.ensureSocketConnected(tripId: tripId);
    if (!live) {
      state = state.copyWith(tripChatErrorCode: 'SOCKET');
      return;
    }
    _rt._socket!.emit('trip:chat:send', {
      'tripId': tripId,
      'messageKind': 'text',
      'messageText': sanitized,
    });
  }

  /// Hidrata chat desde FCM solo si el WS no puede entregar `trip:chat:new`.
  /// Con socket vivo no insertamos: el push y el WS llegaban a la vez con ids
  /// distintos (`fcm-…` vs UUID) y se veían dos burbujas con horas desfasadas.
  void ingestChatFromPush({
    required String tripId,
    required String messageText,
    String senderRole = 'driver',
  }) {
    if (_rt._socketLive) return;
    final text = messageText.trim();
    if (text.isEmpty) return;
    var body = text;
    final prefixes = <String>['Conductor:', 'Driver:', 'Pasajero:', 'Passenger:'];
    for (final p in prefixes) {
      if (body.toLowerCase().startsWith(p.toLowerCase())) {
        body = body.substring(p.length).trim();
        break;
      }
    }
    if (body.isEmpty) body = text;
    _handleTripChatNew({
      'tripId': tripId,
      'id': 'fcm-${tripId.hashCode}-${body.hashCode}',
      'senderRole': senderRole,
      'messageKind': 'text',
      'messageText': body,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    }, tripId);
  }

  void _handleTripArrivalReminder(Map data, String tripId) {
    try {
      final tripIdData = data['tripId']?.toString();
      if (tripIdData == null || tripIdData != tripId) return;
      if (PassengerTripChatVisibility.isOpenForTrip(tripIdData)) return;
      final fg = PassengerAppVisibility.isInForeground.value;
      if (fg && PassengerNotificationService.shouldPlayForegroundChatAlert()) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
      }
      unawaited(
        PassengerNotificationService.instance.showTripChatMessageIfBackground(
          isAppInForeground: fg,
          tripId: tripIdData,
          senderRole: 'driver',
          messageText: _localizedArrivalReminderMessage(),
          notifyInForeground: true,
          includeSenderPrefix: false,
          titleOverride: PassengerLocaleHolder.l10n().passengerNotifyDriverArrivedTitle,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] Error manejando trip:arrival_reminder: $e');
      }
    }
  }

  DateTime? _parseTripChatCreatedAt(Object? raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    return parsed?.toLocal();
  }

  bool _isSyntheticFcmChatId(String id) => id.startsWith('fcm-');

  /// Misma burbuja lógica aunque FCM y WS usen ids distintos.
  bool _isSameTripChatContent(TripChatMessage a, {
    required String tripId,
    required String senderRole,
    required String messageText,
    required String? templateCode,
    required DateTime? createdAt,
  }) {
    if (a.tripId != tripId || a.senderRole != senderRole) return false;
    final codeA = (a.templateCode ?? '').trim();
    final codeB = (templateCode ?? '').trim();
    final textMatch = codeA.isNotEmpty && codeB.isNotEmpty
        ? codeA == codeB
        : a.messageText.trim() == messageText.trim();
    if (!textMatch) return false;
    // Ventana corta: evita colapsar dos “ok” legítimos minutos después.
    final aAt = a.createdAt;
    final bAt = createdAt;
    if (aAt == null || bAt == null) return true;
    return aAt.difference(bAt).abs() <= const Duration(minutes: 2);
  }

  void _handleTripChatNew(Map data, String tripId) {
    try {
      final eventTripId = data['tripId']?.toString();
      if (eventTripId == null || eventTripId != tripId) return;

      // No descartar por lag de status: FCM puede llegar mientras el UI sigue en
      // "searching". Un mensaje de chat implica viaje operativo (accepted+).
      if (!passengerTripChatPhaseActive(state.status)) {
        if (passengerTripIsAwaitingDriverMatch(state.status) ||
            state.status == null) {
          state = state.copyWith(status: 'accepted', activeTripId: eventTripId);
          unawaited(
            TripSessionStorage.saveLastKnownStatus(
              tripId: eventTripId,
              status: 'accepted',
            ),
          );
          unawaited(_rt.syncTripStatusFromApi(tripId: eventTripId, force: true));
        } else if (!passengerTripIsTrackingDriver(state.status)) {
          // completed/cancelled/expired: no acumular chat.
          return;
        }
        // started/in_trip: aún se muestra historial si llega retraso de WS.
      }

      final id =
          data['id']?.toString() ??
          '${DateTime.now().millisecondsSinceEpoch}-${state.chatMessages.length}';
      final senderRole = data['senderRole']?.toString() ?? 'driver';
      final messageKind = data['messageKind']?.toString() ?? 'text';
      final templateCode = data['templateCode']?.toString();
      final messageText = data['messageText']?.toString().trim() ?? '';
      if (messageText.isEmpty) return;

      // Deduplicar por id (reentregas WS).
      if (state.chatMessages.any((m) => m.id == id)) return;

      final createdAt = _parseTripChatCreatedAt(data['createdAt']);
      final dupIndex = state.chatMessages.indexWhere(
        (m) => _isSameTripChatContent(
          m,
          tripId: eventTripId,
          senderRole: senderRole,
          messageText: messageText,
          templateCode: templateCode,
          createdAt: createdAt,
        ),
      );
      if (dupIndex >= 0) {
        final existing = state.chatMessages[dupIndex];
        // Preferir UUID del WS sobre id sintético FCM; actualizar createdAt del server.
        final upgrade =
            _isSyntheticFcmChatId(existing.id) && !_isSyntheticFcmChatId(id);
        if (!upgrade) return;
        final next = List<TripChatMessage>.from(state.chatMessages);
        next[dupIndex] = TripChatMessage(
          id: id,
          tripId: eventTripId,
          senderRole: senderRole,
          messageKind: messageKind,
          templateCode: templateCode ?? existing.templateCode,
          messageText: messageText,
          createdAt: createdAt ?? existing.createdAt,
        );
        state = state.copyWith(chatMessages: next, tripChatErrorCode: null);
        return;
      }

      final next = List<TripChatMessage>.from(state.chatMessages)
        ..add(
          TripChatMessage(
            id: id,
            tripId: eventTripId,
            senderRole: senderRole,
            messageKind: messageKind,
            templateCode: templateCode,
            messageText: messageText,
            createdAt: createdAt,
          ),
        );
      state = state.copyWith(chatMessages: next, tripChatErrorCode: null);
      final fromOtherRole = senderRole != 'passenger';
      if (fromOtherRole) {
        final inForeground = PassengerAppVisibility.isInForeground.value;
        final chatSheetOpen = PassengerTripChatVisibility.isOpenForTrip(
          eventTripId,
        );
        if (!chatSheetOpen &&
            inForeground &&
            PassengerNotificationService.shouldPlayForegroundChatAlert()) {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.lightImpact();
        }
        if (!chatSheetOpen) {
          final displayText = localizedPassengerTripChatMessage(
            PassengerLocaleHolder.l10n(),
            TripChatMessage(
              id: id,
              tripId: eventTripId,
              senderRole: senderRole,
              messageKind: messageKind,
              templateCode: templateCode,
              messageText: messageText,
              createdAt: createdAt,
            ),
          );
          unawaited(
            PassengerNotificationService.instance
                .showTripChatMessageIfBackground(
                  isAppInForeground: inForeground,
                  tripId: eventTripId,
                  senderRole: senderRole,
                  messageText: displayText,
                  notifyInForeground: true,
                ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PASSENGER_RT] Error manejando trip:chat:new: $e');
      }
    }
  }

  void _handleTripChatError(dynamic data) {
    final code =
        (data is Map ? data['code'] : null)?.toString() ?? 'TRIP_CHAT_ERROR';
    state = state.copyWith(tripChatErrorCode: code);
  }
}
