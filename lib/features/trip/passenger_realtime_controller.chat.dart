part of 'passenger_realtime_controller.dart';

mixin _PassengerRealtimeChatMixin on StateNotifier<PassengerRealtimeState> {
  PassengerRealtimeController get _rt => this as PassengerRealtimeController;

  void sendTripChatTemplate({
    required String tripId,
    required String templateCode,
  }) {
    if (!passengerTripChatPhaseActive(state.status)) {
      state = state.copyWith(tripChatErrorCode: 'TRIP_CHAT_NOT_AVAILABLE');
      return;
    }
    if (_rt._socket == null || !state.connected) {
      state = state.copyWith(tripChatErrorCode: 'SOCKET');
      return;
    }
    _rt._socket!.emit('trip:chat:send', {
      'tripId': tripId,
      'messageKind': 'template',
      'templateCode': templateCode,
    });
  }

  void sendTripChatText({required String tripId, required String text}) {
    final sanitized = text.trim();
    if (sanitized.isEmpty) return;
    if (!passengerTripChatPhaseActive(state.status)) {
      state = state.copyWith(tripChatErrorCode: 'TRIP_CHAT_NOT_AVAILABLE');
      return;
    }
    if (_rt._socket == null || !state.connected) {
      state = state.copyWith(tripChatErrorCode: 'SOCKET');
      return;
    }
    _rt._socket!.emit('trip:chat:send', {
      'tripId': tripId,
      'messageKind': 'text',
      'messageText': sanitized,
    });
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

  void _handleTripChatNew(Map data, String tripId) {
    try {
      if (!passengerTripChatPhaseActive(state.status)) return;
      final eventTripId = data['tripId']?.toString();
      if (eventTripId == null || eventTripId != tripId) return;
      final id =
          data['id']?.toString() ??
          '${DateTime.now().millisecondsSinceEpoch}-${state.chatMessages.length}';
      final senderRole = data['senderRole']?.toString() ?? 'driver';
      final messageKind = data['messageKind']?.toString() ?? 'text';
      final templateCode = data['templateCode']?.toString();
      final messageText = data['messageText']?.toString().trim() ?? '';
      if (messageText.isEmpty) return;
      final createdAt = DateTime.tryParse(
        data['createdAt']?.toString() ?? '',
      );
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
