import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/ui/app_safe_scrolling.dart';
import '../../gen_l10n/app_localizations.dart';
import '../home/widgets/passenger_home_look.dart';
import 'passenger_notices_repository.dart';

class PassengerNoticesScreen extends ConsumerStatefulWidget {
  const PassengerNoticesScreen({super.key, this.highlightId});

  final String? highlightId;

  @override
  ConsumerState<PassengerNoticesScreen> createState() =>
      _PassengerNoticesScreenState();
}

class _PassengerNoticesScreenState
    extends ConsumerState<PassengerNoticesScreen> {
  PassengerNoticesSnapshot _snap = const PassengerNoticesSnapshot();
  bool _loading = true;
  String? _openId;

  @override
  void initState() {
    super.initState();
    _openId = widget.highlightId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaitedLoad();
    });
  }

  Future<void> unawaitedLoad() async {
    await _reload(markHighlight: true);
  }

  Future<void> _reload({bool markHighlight = false}) async {
    final repo = ref.read(passengerNoticesRepositoryProvider);
    final snap = await repo.fetchInbox();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
    ref.invalidate(passengerNoticesUnreadProvider);
    final hid = widget.highlightId?.trim();
    if (markHighlight && hid != null && hid.isNotEmpty) {
      await repo.markRead(hid);
      if (!mounted) return;
      await _reload();
    }
  }

  Future<void> _open(PassengerNoticeItem item) async {
    TexiUiFeedback.lightTap();
    setState(() => _openId = _openId == item.id ? null : item.id);
    if (item.unread) {
      await ref.read(passengerNoticesRepositoryProvider).markRead(item.id);
      if (!mounted) return;
      await _reload();
    }
  }

  Future<void> _markAll() async {
    if (_snap.unreadCount <= 0) return;
    TexiUiFeedback.lightTap();
    await ref.read(passengerNoticesRepositoryProvider).markAllRead();
    if (!mounted) return;
    await _reload();
  }

  String _when(DateTime? at) {
    if (at == null) return '';
    final now = DateTime.now();
    final local = at.toLocal();
    final sameDay =
        now.year == local.year && now.month == local.month && now.day == local.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = AppSafeScrolling.systemNavBottom(context);
    return Scaffold(
      backgroundColor: PassengerHomeLook.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      TexiUiFeedback.lightTap();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: PassengerHomeLook.ink,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  Expanded(
                    child: Text(
                      l10n.noticesInboxTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: PassengerHomeLook.ink,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: _snap.unreadCount > 0 ? _markAll : null,
                    child: Text(
                      l10n.noticesMarkAll,
                      style: TextStyle(
                        color: _snap.unreadCount > 0
                            ? PassengerHomeLook.sky
                            : PassengerHomeLook.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: PassengerHomeLook.sky,
                backgroundColor: PassengerHomeLook.card,
                onRefresh: _reload,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: PassengerHomeLook.sky,
                          strokeWidth: 2.4,
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottom),
                        itemCount: _snap.items.isEmpty ? 1 : _snap.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (_snap.items.isEmpty) {
                            return _EmptyCard(label: l10n.noticesEmpty);
                          }
                          final item = _snap.items[index];
                          final open = _openId == item.id;
                          return _NoticeCard(
                            item: item,
                            open: open,
                            when: _when(item.sentAt),
                            onTap: () => _open(item),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: PassengerHomeLook.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: PassengerHomeLook.hairline),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 40,
            color: PassengerHomeLook.muted,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PassengerHomeLook.muted,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.item,
    required this.open,
    required this.when,
    required this.onTap,
  });

  final PassengerNoticeItem item;
  final bool open;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.unread ? PassengerHomeLook.cardLift : PassengerHomeLook.card,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.unread ? PassengerHomeLook.sky : Colors.transparent,
                  border: item.unread
                      ? null
                      : Border.all(color: PassengerHomeLook.hairline),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: PassengerHomeLook.ink,
                              fontWeight: item.unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (when.isNotEmpty)
                          Text(
                            when,
                            style: const TextStyle(
                              color: PassengerHomeLook.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: open ? 12 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PassengerHomeLook.muted,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
