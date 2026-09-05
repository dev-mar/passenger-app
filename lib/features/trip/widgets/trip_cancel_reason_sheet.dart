import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../trip_cancel_reason.dart';

Future<TripCancelReasonChoice?> showTripCancelReasonSheet({
  required BuildContext context,
  required Future<List<TripCancelReasonItem>> Function() loadReasons,
  required bool connected,
}) {
  return showModalBottomSheet<TripCancelReasonChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheetTop)),
    ),
    builder: (ctx) => _TripCancelReasonSheet(
      loadReasons: loadReasons,
      connected: connected,
    ),
  );
}

class _TripCancelReasonSheet extends StatefulWidget {
  const _TripCancelReasonSheet({
    required this.loadReasons,
    required this.connected,
  });

  final Future<List<TripCancelReasonItem>> Function() loadReasons;
  final bool connected;

  @override
  State<_TripCancelReasonSheet> createState() => _TripCancelReasonSheetState();
}

class _TripCancelReasonSheetState extends State<_TripCancelReasonSheet> {
  bool _loading = true;
  String? _loadError;
  List<TripCancelReasonItem> _items = const [];
  String? _selectedCode;
  final _noteCtrl = TextEditingController();
  bool _confirmStep = false;

  TripCancelReasonItem? get _selected {
    final code = _selectedCode;
    if (code == null) return null;
    for (final item in _items) {
      if (item.code == code) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final items = await widget.loadReasons();
      if (!mounted) return;
      setState(() {
        _items = items.where((e) => e.code.isNotEmpty && e.label.isNotEmpty).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'load';
      });
    }
  }

  bool get _noteOk {
    final item = _selected;
    if (item == null) return false;
    if (!item.requiresNote) return true;
    return _noteCtrl.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxx,
        AppSpacing.xl,
        AppSpacing.xxx,
        AppSpacing.sheetV + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            _confirmStep ? l10n.tripCancelConfirmTitle : l10n.tripCancelChooseReason,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            Column(
              children: [
                Text(l10n.tripCancelReasonsLoadError),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: _load,
                  child: Text(l10n.tripRecoveringRetryCta),
                ),
              ],
            )
          else if (_items.isEmpty)
            Text(l10n.tripCancelReasonsEmpty)
          else if (!_confirmStep) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in _items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _selectedCode == item.code
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(item.label),
                      onTap: () => setState(() => _selectedCode = item.code),
                    ),
                ],
              ),
            ),
            if (_selected?.requiresNote == true) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _noteCtrl,
                maxLength: 400,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.tripCancelNoteHint,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _selectedCode != null && _noteOk
                  ? () {
                      HapticFeedback.lightImpact();
                      setState(() => _confirmStep = true);
                    }
                  : null,
              child: Text(l10n.tripCancelContinue),
            ),
          ] else ...[
            Text(
              _selected?.confirmText.isNotEmpty == true
                  ? _selected!.confirmText
                  : l10n.tripCancelConfirmFallback,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (!widget.connected) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.tripCancelNeedConnection,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: widget.connected && _selected != null
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop(
                        TripCancelReasonChoice(
                          code: _selected!.code,
                          note: _noteCtrl.text.trim().isEmpty
                              ? null
                              : _noteCtrl.text.trim(),
                        ),
                      );
                    }
                  : null,
              child: Text(l10n.tripCancelConfirm),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => setState(() => _confirmStep = false),
              child: Text(l10n.tripCancelBack),
            ),
          ],
        ],
      ),
    );
  }
}
