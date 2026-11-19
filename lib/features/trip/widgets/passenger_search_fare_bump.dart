import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../trip_request_state.dart';

/// Sube la oferta durante la búsqueda. El mínimo es la tarifa calculada.
/// El reenvío lo hace la pantalla: anula el matching y crea otra solicitud.
class PassengerSearchFareBump extends ConsumerStatefulWidget {
  const PassengerSearchFareBump({
    super.key,
    required this.busy,
    required this.onResubmit,
  });

  final bool busy;
  final Future<void> Function(double amount) onResubmit;

  @override
  ConsumerState<PassengerSearchFareBump> createState() =>
      _PassengerSearchFareBumpState();
}

class _PassengerSearchFareBumpState extends ConsumerState<PassengerSearchFareBump> {
  static const _ink = Color(0xFFF2EDE4);
  static const _muted = Color(0xFFB0A99C);
  static const _accent = Color(0xFFFFC107);
  static const _notice = Color(0xFFFFE082);

  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  String? _syncedTripId;
  double? _syncedCommitted;
  double? _draft;
  bool _editing = false;
  bool _textDirty = false;
  bool _syncingText = false;
  bool _floorNotice = false;

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(_onAmountFocus);
  }

  @override
  void dispose() {
    _amountFocus.removeListener(_onAmountFocus);
    _amountFocus.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountFocus() {
    if (!mounted || _amountFocus.hasFocus || !_editing) return;
    final parsed = int.tryParse(_amountController.text.trim());
    setState(() {
      _editing = false;
      if (_textDirty && parsed != null && parsed > 0) {
        _draft = parsed.toDouble();
      }
    });
  }

  double _shown({required String? tripId, required double committed}) {
    if (_syncedTripId != tripId || _syncedCommitted != committed) {
      _syncedTripId = tripId;
      _syncedCommitted = committed;
      _draft = committed;
      _editing = false;
      _textDirty = false;
      _floorNotice = false;
    }
    return _draft ?? committed;
  }

  String _seedText(double value) => roundTripAmount(value).truncate().toString();

  void _setController(String text, {required bool selectAll}) {
    _syncingText = true;
    _amountController.value = TextEditingValue(
      text: text,
      selection: selectAll
          ? TextSelection(baseOffset: 0, extentOffset: text.length)
          : TextSelection.collapsed(offset: text.length),
    );
    _syncingText = false;
  }

  void _openEditor(double shown) {
    if (widget.busy) return;
    HapticFeedback.lightImpact();
    setState(() {
      _editing = true;
      _textDirty = false;
      _floorNotice = false;
    });
    _setController(_seedText(shown), selectAll: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  void _step({
    required double shown,
    required double floor,
    required int delta,
  }) {
    final typed = int.tryParse(_amountController.text.trim());
    final base = (_editing && typed != null && typed > 0)
        ? typed.toDouble()
        : shown;
    final raw = base + delta;
    final value = raw < floor ? floor : raw;
    final whole = roundTripAmount(value);
    final isWhole = (whole - whole.truncateToDouble()).abs() < 0.001;
    final keepEditing = _editing && isWhole;
    setState(() {
      _draft = value;
      _floorNotice = false;
      _textDirty = keepEditing;
      _editing = keepEditing;
    });
    if (keepEditing) {
      _setController(whole.truncate().toString(), selectAll: false);
      return;
    }
    _amountFocus.unfocus();
  }

  double? _effectiveAmount(double shown) {
    if (_editing) {
      final parsed = int.tryParse(_amountController.text.trim());
      if (parsed == null || parsed <= 0) return null;
      return parsed.toDouble();
    }
    return shown;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trip = ref.watch(tripRequestProvider);
    final searchLocked =
        ref.watch(passengerSearchLockProvider) != PassengerSearchLock.idle;
    final quote = trip.quote;
    final floor = trip.previewTotalPrice;
    if (quote == null || !quote.isOfferable || floor == null || floor <= 0) {
      return const SizedBox.shrink();
    }
    final committedRaw = trip.passengerOfferAmount ?? floor;
    final committed = committedRaw < floor ? floor : committedRaw;
    final shown = _shown(tripId: trip.tripId, committed: committed);
    final steppingBase = () {
      final typed = int.tryParse(_amountController.text.trim());
      if (_editing && typed != null && typed > 0) {
        return typed.toDouble();
      }
      return shown;
    }();
    final atFloor = steppingBase <= floor + 0.009;
    final effective = _effectiveAmount(shown);
    final belowFloor = effective == null || effective + 0.009 < floor;
    final changed =
        effective != null && (effective - committed).abs() > 0.009;
    final busy = widget.busy || searchLocked;
    final canSend = !busy && changed && !belowFloor;
    final canWarn = !busy && belowFloor && (_editing || shown + 0.009 < floor);
    final floorLabel = formatTripMoney(floor, currencyCode: quote.currencyCode);

    void trySend() {
      if (ref.read(passengerSearchLockProvider) != PassengerSearchLock.idle) {
        return;
      }
      final amount = _effectiveAmount(shown);
      if (amount == null || amount + 0.009 < floor) {
        HapticFeedback.lightImpact();
        setState(() => _floorNotice = true);
        return;
      }
      if ((amount - committed).abs() <= 0.009) return;
      HapticFeedback.lightImpact();
      setState(() => _floorNotice = false);
      widget.onResubmit(amount);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.offerableSearchRaiseTitle,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.offerableSearchRaiseHint,
          style: const TextStyle(color: _muted, fontSize: 12, height: 1.3),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StepButton(
              icon: Icons.remove_rounded,
              tooltip: l10n.offerableSearchRaiseTitle,
              onPressed: busy || atFloor
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _step(shown: shown, floor: floor, delta: -1);
                    },
            ),
            Expanded(
              child: _editing
                  ? TextField(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                      cursorColor: _accent,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      scrollPadding: const EdgeInsets.only(bottom: 140),
                      onChanged: (raw) {
                        if (_syncingText) return;
                        final parsed = int.tryParse(raw.trim());
                        setState(() {
                          _textDirty = true;
                          _floorNotice = false;
                          if (parsed != null && parsed > 0) {
                            _draft = parsed.toDouble();
                          }
                        });
                      },
                      onSubmitted: (_) => trySend(),
                    )
                  : Semantics(
                      button: true,
                      label: l10n.offerableSearchRaiseEdit,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: busy ? null : () => _openEditor(shown),
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 48,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    formatTripMoney(
                                      shown,
                                      currencyCode: quote.currencyCode,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: _muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              tooltip: l10n.offerableSearchRaiseTitle,
              onPressed: busy
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _step(shown: shown, floor: floor, delta: 1);
                    },
            ),
          ],
        ),
        if (_floorNotice) ...[
          const SizedBox(height: 6),
          Text(
            l10n.offerableSearchRaiseBelowFloor(floorLabel),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _notice, fontSize: 12, height: 1.3),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: canSend || canWarn ? trySend : null,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              disabledBackgroundColor: _accent.withValues(alpha: 0.28),
              foregroundColor: const Color(0xFF1A1408),
              disabledForegroundColor: const Color(0xFF1A1408).withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    canSend || canWarn
                        ? l10n.offerableSearchRaiseCta
                        : l10n.offerableSearchRaiseNeedMore,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: const Color(0xFFFFC107)),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107).withValues(alpha: 0.12),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
