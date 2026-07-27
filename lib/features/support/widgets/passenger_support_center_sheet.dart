import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/passenger_api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_safe_scrolling.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../support_ticket_models.dart';
import 'passenger_support_ticket_detail_sheet.dart';

/// Centro de soporte: crear ticket, listar recientes y polling de estado.
Future<void> showPassengerSupportCenterSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final repo = ref.read(passengerSupportRepositoryProvider);
  final subjectCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  var category = 'general';
  var loading = true;
  var sending = false;
  var recent = <SupportTicketSummary>[];
  final lastStatusById = <String, String>{};
  Timer? poller;

  Future<void> loadRecent(
    StateSetter setSheetState, {
    BuildContext? notifyCtx,
    bool notifyChanges = false,
  }) async {
    setSheetState(() => loading = true);
    try {
      final parsed = await repo.fetchRecentTickets(limit: 6);
      if (notifyChanges && notifyCtx != null && notifyCtx.mounted) {
        for (final t in parsed) {
          final prev = lastStatusById[t.id];
          if (prev != null && prev != t.status) {
            ScaffoldMessenger.of(notifyCtx).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.profileSupportTicketStatusChanged(
                    t.ticketNumber,
                    t.status,
                  ),
                ),
              ),
            );
          }
        }
      }
      lastStatusById
        ..clear()
        ..addEntries(parsed.map((e) => MapEntry(e.id, e.status)));
      setSheetState(() => recent = parsed);
    } catch (_) {
      setSheetState(() => recent = const []);
    } finally {
      setSheetState(() => loading = false);
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (loading && recent.isEmpty) {
            loadRecent(setSheetState, notifyCtx: ctx);
          }
          poller ??= Timer.periodic(const Duration(seconds: 25), (_) {
            if (!ctx.mounted || sending) return;
            loadRecent(setSheetState, notifyCtx: ctx, notifyChanges: true);
          });
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  AppSafeScrolling.systemNavBottom(ctx),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.profileSupportCenterTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: [
                      DropdownMenuItem(
                        value: 'general',
                        child: Text(l10n.profileSupportCategoryGeneral),
                      ),
                      DropdownMenuItem(
                        value: 'trip',
                        child: Text(l10n.profileSupportCategoryTrip),
                      ),
                      DropdownMenuItem(
                        value: 'payment',
                        child: Text(l10n.profileSupportCategoryPayment),
                      ),
                      DropdownMenuItem(
                        value: 'account',
                        child: Text(l10n.profileSupportCategoryAccount),
                      ),
                      DropdownMenuItem(
                        value: 'safety',
                        child: Text(l10n.profileSupportCategorySafety),
                      ),
                      DropdownMenuItem(
                        value: 'technical',
                        child: Text(l10n.profileSupportCategoryTechnical),
                      ),
                    ],
                    onChanged: sending
                        ? null
                        : (v) {
                            if (v != null) setSheetState(() => category = v);
                          },
                    decoration: InputDecoration(
                      labelText: l10n.profileSupportCategoryLabel,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subjectCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.profileSupportSubjectLabel,
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: messageCtrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: l10n.profileSupportDetailLabel,
                      prefixIcon: const Icon(Icons.message_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: sending
                        ? null
                        : () async {
                            final subject = subjectCtrl.text.trim();
                            final message = messageCtrl.text.trim();
                            if (subject.length < 3 || message.length < 10) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.profileSupportValidationError,
                                  ),
                                ),
                              );
                              return;
                            }
                            setSheetState(() => sending = true);
                            try {
                              await repo.createTicket(
                                category: category,
                                subject: subject,
                                message: message,
                              );
                              subjectCtrl.clear();
                              messageCtrl.clear();
                              await loadRecent(setSheetState);
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.profileSupportSentSuccess),
                                ),
                              );
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        RegExp(r'^Exception:\s*'),
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (ctx.mounted) {
                                setSheetState(() => sending = false);
                              }
                            }
                          },
                    icon: sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      sending
                          ? l10n.profileSupportSending
                          : l10n.profileSupportSendTicket,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.profileSupportRecentTickets,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: sending
                            ? null
                            : () => loadRecent(setSheetState, notifyCtx: ctx),
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: l10n.profileRefreshTooltip,
                      ),
                    ],
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.profileSupportNoTickets),
                    )
                  else
                    ...recent.map(
                      (t) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onTap: () async {
                          try {
                            final detail = await repo.fetchTicketDetail(t.id);
                            if (!ctx.mounted) return;
                            await showPassengerSupportTicketDetailSheet(
                              context: ctx,
                              ref: ref,
                              detail: detail,
                            );
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst(
                                    RegExp(r'^Exception:\s*'),
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                          if (!ctx.mounted) return;
                          await loadRecent(setSheetState, notifyCtx: ctx);
                        },
                        leading: Icon(
                          t.status == 'open'
                              ? Icons.mark_email_unread_outlined
                              : Icons.check_circle_outline,
                          color: t.status == 'open'
                              ? AppColors.primary
                              : AppColors.success,
                        ),
                        title: Text(
                          '${t.ticketNumber} · ${t.subject}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${t.category} · ${t.status}'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  poller?.cancel();
  subjectCtrl.dispose();
  messageCtrl.dispose();
}
