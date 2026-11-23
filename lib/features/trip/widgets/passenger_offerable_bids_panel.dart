import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/network/trips_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/texi_scale_press.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../passenger_realtime_controller.dart';
import '../trip_request_state.dart';

class _FareBid {
  const _FareBid({
    required this.id,
    required this.amount,
    required this.driverName,
    required this.driverRating,
    this.driverId = '',
    this.etaMinutes,
    this.createdAt,
  });

  final String id;
  final double amount;
  final String driverName;
  final double driverRating;
  final String driverId;
  final double? etaMinutes;
  final DateTime? createdAt;

  factory _FareBid.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    final ratingRaw = json['driverRating'];
    final etaRaw = json['etaMinutes'];
    return _FareBid(
      id: json['id']?.toString() ?? '',
      amount: amountRaw is num
          ? amountRaw.toDouble()
          : double.tryParse('$amountRaw') ?? 0,
      driverName: json['driverName']?.toString().trim() ?? '',
      driverRating: ratingRaw is num ? ratingRaw.toDouble() : 5,
      driverId: json['driverIdentityUserId']?.toString().trim() ?? '',
      etaMinutes: etaRaw is num
          ? etaRaw.toDouble()
          : double.tryParse('${etaRaw ?? ''}'),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

List<_FareBid> _uniqueFareBids(List<_FareBid> raw) {
  final seenIds = <String>{};
  final indexByDriver = <String, int>{};
  final unique = <_FareBid>[];
  for (final bid in raw) {
    if (bid.id.isEmpty || !seenIds.add(bid.id)) continue;
    final driverKey = bid.driverId.isEmpty ? bid.id : bid.driverId;
    final existingIndex = indexByDriver[driverKey];
    if (existingIndex == null) {
      indexByDriver[driverKey] = unique.length;
      unique.add(bid);
      continue;
    }
    final current = unique[existingIndex];
    final nextAt = bid.createdAt;
    final currentAt = current.createdAt;
    if (currentAt == null || (nextAt != null && nextAt.isAfter(currentAt))) {
      unique[existingIndex] = bid;
    }
  }
  return unique;
}

class PassengerOfferableBidsPanel extends ConsumerStatefulWidget {
  const PassengerOfferableBidsPanel({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<PassengerOfferableBidsPanel> createState() =>
      _PassengerOfferableBidsPanelState();
}

class _PassengerOfferableBidsPanelState
    extends ConsumerState<PassengerOfferableBidsPanel> {
  Timer? _timer;
  List<_FareBid> _bids = const [];
  String? _busyId;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void didUpdateWidget(covariant PassengerOfferableBidsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId != widget.tripId) {
      _bids = const [];
      _busyId = null;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<TripsApi?> _api() async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) return null;
    return TripsApi(token: token);
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    final api = await _api();
    if (api == null || !mounted || token != _loadToken) return;
    try {
      final data = await api.listFareBids(widget.tripId);
      final raw = data['bids'];
      final next = raw is List
          ? _uniqueFareBids(
              raw
                  .whereType<Map>()
                  .map(
                    (e) => _FareBid.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList(),
            )
          : <_FareBid>[];
      if (!mounted || token != _loadToken) return;
      setState(() => _bids = next);
    } catch (_) {}
  }

  Future<void> _accept(_FareBid bid) async {
    if (ref.read(passengerSearchLockProvider) != PassengerSearchLock.idle) {
      return;
    }
    if (ref.read(tripRequestProvider).tripId != widget.tripId) return;
    ref.read(passengerSearchLockProvider.notifier).state =
        PassengerSearchLock.bid;
    HapticFeedback.lightImpact();
    if (mounted) setState(() => _busyId = bid.id);
    try {
      final api = await _api();
      if (api == null) return;
      if (ref.read(tripRequestProvider).tripId != widget.tripId) return;
      await api.acceptFareBid(tripId: widget.tripId, negotiationId: bid.id);
      await ref.read(passengerRealtimeProvider.notifier).syncTripStatusFromApi(
            tripId: widget.tripId,
            force: true,
          );
    } catch (_) {
    } finally {
      if (ref.read(passengerSearchLockProvider) == PassengerSearchLock.bid) {
        ref.read(passengerSearchLockProvider.notifier).state =
            PassengerSearchLock.idle;
      }
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decline(_FareBid bid) async {
    if (ref.read(passengerSearchLockProvider) != PassengerSearchLock.idle) {
      return;
    }
    if (ref.read(tripRequestProvider).tripId != widget.tripId) return;
    ref.read(passengerSearchLockProvider.notifier).state =
        PassengerSearchLock.bid;
    HapticFeedback.lightImpact();
    if (mounted) setState(() => _busyId = bid.id);
    try {
      final api = await _api();
      if (api == null) return;
      if (ref.read(tripRequestProvider).tripId != widget.tripId) return;
      await api.declineFareBid(tripId: widget.tripId, negotiationId: bid.id);
      await _load();
    } catch (_) {
    } finally {
      if (ref.read(passengerSearchLockProvider) == PassengerSearchLock.bid) {
        ref.read(passengerSearchLockProvider.notifier).state =
            PassengerSearchLock.idle;
      }
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = ref.watch(tripRequestProvider).quote;
    if (quote == null || !quote.isOfferable || _bids.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final searchLocked =
        ref.watch(passengerSearchLockProvider) != PassengerSearchLock.idle;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.42;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Material(
        color: const Color(0xF21A1814),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            children: [
                Text(
                  l10n.offerableBidsTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.offerableBidsBody,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.96),
                  ),
                ),
                const SizedBox(height: 12),
                ...[
                  for (var i = 0; i < _bids.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _FareBidCard(
                      key: ValueKey(_bids[i].id),
                      l10n: l10n,
                      bid: _bids[i],
                      currencyCode: quote.currencyCode,
                      busy: _busyId == _bids[i].id,
                      locked: _busyId != null || searchLocked,
                      onAccept: () => _accept(_bids[i]),
                      onDecline: () => _decline(_bids[i]),
                    ),
                  ],
                ],
              ],
          ),
        ),
      ),
    );
  }
}

class _FareBidCard extends StatelessWidget {
  const _FareBidCard({
    super.key,
    required this.l10n,
    required this.bid,
    required this.currencyCode,
    required this.busy,
    required this.locked,
    required this.onAccept,
    required this.onDecline,
  });

  final AppLocalizations l10n;
  final _FareBid bid;
  final String? currencyCode;
  final bool busy;
  final bool locked;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final name = bid.driverName.isEmpty
        ? l10n.tripDriverNameFallback
        : bid.driverName;
    final eta = bid.etaMinutes;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: AppColors.primary.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.primary.withValues(alpha: 0.95),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            eta == null
                                ? bid.driverRating.toStringAsFixed(1)
                                : '${bid.driverRating.toStringAsFixed(1)} · ${l10n.offerableBidEta(eta.round())}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTripMoney(bid.amount, currencyCode: currencyCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: locked ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.9),
                    ),
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.offerableBidDecline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TexiScalePress(
                  child: FilledButton(
                    onPressed: locked ? null : onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(
                            l10n.offerableBidAccept,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
