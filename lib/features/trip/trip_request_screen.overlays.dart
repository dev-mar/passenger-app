part of 'trip_request_screen.dart';

/// Rating, chat del viaje y efectos lifecycle post-frame del build.
mixin _TripRequestScreenOverlaysMixin on _TripRequestScreenTripOpsMixin {
  _TripRequestScreenState get _o => this as _TripRequestScreenState;

  Future<void> _showRatingSheet(
    BuildContext context,
    String tripId,
    String? driverName,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => PassengerRatingSheetContent(
        driverName: displayDriverName(driverName, l10n.tripDriverNameFallback),
        title: l10n.tripRateDriver,
        subtitle: l10n.tripRateDriverSubtitle,
        sendLabel: l10n.tripSendRating,
        skipLabel: l10n.tripSkipRating,
        onSubmitted: (stars, feedbackCodes) {
          unawaited(
            _submitPassengerRating(
              tripId: tripId,
              stars: stars,
              feedbackCodes: feedbackCodes,
            ),
          );
          Navigator.of(ctx).pop();
          unawaited(() async {
            await _o._resetHomeAfterTripEnded(tripId);
          }());
        },
        onSkipped: () {
          Navigator.of(ctx).pop();
          unawaited(() async {
            await _o._resetHomeAfterTripEnded(tripId);
          }());
        },
      ),
    );

    // Si el usuario cerrÃ³ el sheet sin pulsar botones, igual reseteamos para permitir pedir otro viaje.
    final rt = ref.read(passengerRealtimeProvider);
    final providerTripId = ref.read(tripRequestProvider).tripId;
    if (rt.status == 'completed' &&
        (providerTripId == null || providerTripId == tripId)) {
      await _o._resetHomeAfterTripEnded(tripId);
    }
  }

  Future<void> _submitPassengerRating({
    required String tripId,
    required int stars,
    List<String> feedbackCodes = const [],
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) return;
      await TripsApi(token: token).submitPassengerTripRating(
        tripId: tripId,
        stars: stars,
        feedbackCodes: feedbackCodes,
      );
    } catch (_) {}
  }

  Future<void> _openTripChatSheet({required String tripId}) async {
    if (!passengerTripChatPhaseActive(
      ref.read(passengerRealtimeProvider).status,
    )) {
      return;
    }
    final controller = ref.read(passengerRealtimeProvider.notifier);
    // Rehidrata canal WS antes de enviar/recibir (evita SOCKET fantasma).
    unawaited(
      controller.ensureSocketConnected(
        tripId: tripId,
        quote: ref.read(tripRequestProvider).quote,
      ),
    );
    final textController = TextEditingController();

    _o._tripChatSheetDisplayed = true;
    PassengerTripChatVisibility.setOpen(tripId);
    _markTripChatAsRead();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final mq = MediaQuery.of(ctx);
          return Padding(
            padding: EdgeInsets.only(
              bottom: mq.viewInsets.bottom,
              left: 10,
              right: 10,
              top: 8,
            ),
            child: FractionallySizedBox(
              heightFactor: 0.82,
              child: Consumer(
                builder: (context, ref, _) {
                  final rt = ref.watch(passengerRealtimeProvider);
                  final sheetL10n = AppLocalizations.of(context)!;
                  final quickTemplates = <Map<String, String>>[
                    {
                      'code': 'CANT_FIND_VEHICLE',
                      'label': sheetL10n.passengerTripChatTemplateCantFindVehicle,
                    },
                    {
                      'code': 'WHERE_ARE_YOU',
                      'label': sheetL10n.passengerTripChatTemplateWhereAreYou,
                    },
                    {
                      'code': 'IM_WAITING_HERE',
                      'label': sheetL10n.passengerTripChatTemplateWaitingHere,
                    },
                  ];
                  String formatTime(DateTime? dt) {
                    if (dt == null) return sheetL10n.passengerTripChatNow;
                    final local = dt.toLocal();
                    final hh = local.hour.toString().padLeft(2, '0');
                    final mm = local.minute.toString().padLeft(2, '0');
                    return '$hh:$mm';
                  }

                  String tripChatErrorMessage(String code) {
                    if (code == '42P01' ||
                        code == 'TRIP_CHAT_STORAGE_UNAVAILABLE') {
                      return sheetL10n.passengerTripChatErrorStorage;
                    }
                    if (code == 'TRIP_CHAT_NOT_AVAILABLE') {
                      return sheetL10n.passengerTripChatErrorPhase;
                    }
                    if (code == '23503') {
                      return sheetL10n.passengerTripChatErrorNotReady;
                    }
                    return sheetL10n.passengerTripChatErrorSendReceive(code);
                  }

                  return Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          14,
                          10,
                          14,
                          12 + mq.viewPadding.bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.16,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    sheetL10n.passengerTripChatTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: rt.connected
                                        ? AppColors.success.withValues(
                                            alpha: 0.12,
                                          )
                                        : AppColors.error.withValues(
                                            alpha: 0.12,
                                          ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    rt.connected
                                        ? sheetL10n.passengerTripChatOnline
                                        : sheetL10n.passengerTripChatOffline,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: rt.connected
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            Text(
                              sheetL10n.passengerTripChatSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.95,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 38,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: quickTemplates.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final it = quickTemplates[index];
                                  return OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                    ),
                                    onPressed: () {
                                      textController.text = it['label']!;
                                      textController.selection =
                                          TextSelection.collapsed(
                                            offset: textController.text.length,
                                          );
                                    },
                                    child: Text(
                                      it['label']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (rt.tripChatErrorCode != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  tripChatErrorMessage(rt.tripChatErrorCode!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                                child: rt.chatMessages.isEmpty
                                    ? Center(
                                        child: Text(
                                          sheetL10n.passengerTripChatEmptyState,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textSecondary
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(10),
                                        itemCount: rt.chatMessages.length,
                                        itemBuilder: (context, index) {
                                          final msg = rt.chatMessages[index];
                                          final mine =
                                              msg.senderRole == 'passenger';
                                          return Align(
                                            alignment: mine
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: Container(
                                              constraints: const BoxConstraints(
                                                maxWidth: 280,
                                              ),
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 9,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: mine
                                                    ? AppColors.primary
                                                          .withValues(
                                                            alpha: 0.2,
                                                          )
                                                    : AppColors.surface,
                                                borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      const Radius.circular(14),
                                                  topRight:
                                                      const Radius.circular(14),
                                                  bottomLeft: Radius.circular(
                                                    mine ? 14 : 4,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    mine ? 4 : 14,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    localizedPassengerTripChatMessage(
                                                      sheetL10n,
                                                      msg,
                                                    ),
                                                    style: const TextStyle(
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${mine ? sheetL10n.passengerTripChatSenderYou : sheetL10n.passengerTripChatSenderDriver} · ${formatTime(msg.createdAt)}',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      color: AppColors
                                                          .textSecondary
                                                          .withValues(
                                                            alpha: 0.85,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: textController,
                                        minLines: 1,
                                        maxLines: 4,
                                        decoration: InputDecoration(
                                          hintText:
                                              sheetL10n.passengerTripChatMessageHint,
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      height: 40,
                                      child: FilledButton(
                                        onPressed: () {
                                          final t = textController.text.trim();
                                          if (t.isEmpty) return;
                                          unawaited(
                                            controller.sendTripChatText(
                                              tripId: tripId,
                                              text: t,
                                            ),
                                          );
                                          textController.clear();
                                        },
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          minimumSize: const Size(44, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.send_rounded,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } finally {
      _o._tripChatSheetDisplayed = false;
      PassengerTripChatVisibility.setOpen(null);
      _markTripChatAsRead();
      textController.dispose();
    }
  }

  void _markTripChatAsRead() {
    final total = ref.read(passengerRealtimeProvider).chatMessages.length;
    if (!mounted) {
      _o._tripChatUnreadCount = 0;
      _o._tripChatReadCursor = total;
      return;
    }
    setState(() {
      _o._tripChatUnreadCount = 0;
      _o._tripChatReadCursor = total;
    });
    if (_o._chatAttentionController.isAnimating) {
      _o._chatAttentionController.stop();
      _o._chatAttentionController.value = 0;
    }
  }

  void _syncTripUnreadCounter(PassengerRealtimeState previous, PassengerRealtimeState next) {
    final prevTripId = previous.activeTripId;
    final nextTripId = next.activeTripId;
    final prevLen = previous.chatMessages.length;
    final nextLen = next.chatMessages.length;

    if (nextTripId == null || nextTripId.isEmpty || nextLen == 0) {
      if (_o._tripChatUnreadCount != 0 || _o._tripChatReadCursor != 0) {
        setState(() {
          _o._tripChatUnreadCount = 0;
          _o._tripChatReadCursor = 0;
        });
      }
      if (_o._chatAttentionController.isAnimating) {
        _o._chatAttentionController.stop();
        _o._chatAttentionController.value = 0;
      }
      return;
    }

    // Cambio de viaje o limpieza del historial en provider: reiniciar contador.
    if (prevTripId != nextTripId || nextLen < prevLen || _o._tripChatReadCursor > nextLen) {
      setState(() {
        _o._tripChatUnreadCount = 0;
        _o._tripChatReadCursor = nextLen;
      });
      if (_o._chatAttentionController.isAnimating) {
        _o._chatAttentionController.stop();
        _o._chatAttentionController.value = 0;
      }
      return;
    }

    if (_o._tripChatSheetDisplayed) {
      if (_o._tripChatUnreadCount != 0 || _o._tripChatReadCursor != nextLen) {
        setState(() {
          _o._tripChatUnreadCount = 0;
          _o._tripChatReadCursor = nextLen;
        });
      }
      return;
    }

    if (nextLen <= _o._tripChatReadCursor) return;
    var incomingFromDriver = 0;
    for (var i = _o._tripChatReadCursor; i < nextLen; i++) {
      final msg = next.chatMessages[i];
      if (msg.senderRole != 'passenger') incomingFromDriver++;
    }
    if (incomingFromDriver <= 0) {
      setState(() => _o._tripChatReadCursor = nextLen);
      return;
    }
    setState(() {
      _o._tripChatUnreadCount += incomingFromDriver;
      _o._tripChatReadCursor = nextLen;
    });
    if (!_o._chatAttentionController.isAnimating) {
      _o._chatAttentionController.repeat(reverse: true);
    }
  }
  /// Efectos post-frame: rating, reset completado stale, cancelado/expirado.
  void scheduleActiveTripLifecycleEffects({
    required String? tripId,
    required PassengerRealtimeState rtState,
  }) {
    if (tripId != null &&
        rtState.status == 'completed' &&
        tripId != _o._ratingSheetShownForTripId &&
        !_o._ratingDone) {
      _o._ratingSheetShownForTripId = tripId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showRatingSheet(context, tripId, rtState.driverName);
      });
    }

    if (tripId != null && rtState.status == 'completed' && _o._ratingDone) {
      if (_o._completedStaleAutoResetTripId != tripId) {
        _o._completedStaleAutoResetTripId = tripId;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          if (ref.read(tripRequestProvider).tripId != tripId ||
              ref.read(passengerRealtimeProvider).status != 'completed') {
            _o._completedStaleAutoResetTripId = null;
            return;
          }
          await _o._resetHomeAfterTripEnded(tripId);
        });
      }
    } else if (tripId == null || rtState.status != 'completed') {
      _o._completedStaleAutoResetTripId = null;
    }

    if (tripId != null &&
        (rtState.status == 'cancelled' || rtState.status == 'expired')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_o._resetTripSessionToDraftHome(tripIdForGuard: tripId));
      });
    }
  }

  void _onPassengerTripChatOpenBump() {
    final bump = passengerTripChatOpenBump.value;
    if (bump <= _o._lastHandledTripChatOpenBump) return;
    _o._lastHandledTripChatOpenBump = bump;
    if (!mounted) return;
    final pendingTripId = takePendingPassengerChatTripIdFromNotification();
    if (pendingTripId == null || pendingTripId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final tripId = ref.read(tripRequestProvider).tripId;
      if (tripId == null || tripId != pendingTripId) return;
      await ref
          .read(passengerRealtimeProvider.notifier)
          .syncTripStatusFromApi(tripId: tripId, force: true);
      if (!mounted) return;
      final status = ref.read(passengerRealtimeProvider).status;
      if (!passengerTripChatPhaseActive(status)) return;
      if (_o._tripChatSheetDisplayed) return;
      await _openTripChatSheet(tripId: tripId);
    });
  }
}