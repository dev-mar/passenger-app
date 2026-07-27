import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/passenger_api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_safe_scrolling.dart';
import '../../../core/compliance/passenger_play_media_disclosures.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../support_ticket_models.dart';

Future<void> showPassengerSupportTicketDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required SupportTicketDetail detail,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final repo = ref.read(passengerSupportRepositoryProvider);
  var uploading = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (detailCtx) {
      return StatefulBuilder(
        builder: (detailCtx, setDetailState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + AppSafeScrolling.systemNavBottom(detailCtx),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${detail.ticketNumber} · ${detail.subject}',
                    style: Theme.of(detailCtx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${detail.category} · ${detail.status} · ${detail.priority}',
                  ),
                  const SizedBox(height: 12),
                  Text(detail.message),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: uploading
                        ? null
                        : () async {
                            if (!await passengerEnsureMediaDisclosureBeforePick(
                              detailCtx,
                              l10n,
                              source: ImageSource.gallery,
                            )) {
                              return;
                            }
                            final file = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                              maxWidth: 1600,
                            );
                            if (file == null) return;
                            final bytes = await file.readAsBytes();
                            if (bytes.isEmpty) return;
                            setDetailState(() => uploading = true);
                            try {
                              final ext = file.name.toLowerCase();
                              final ct = ext.endsWith('.png')
                                  ? 'image/png'
                                  : ext.endsWith('.webp')
                                  ? 'image/webp'
                                  : 'image/jpeg';
                              final presign = await repo.presignAttachment(
                                ticketId: detail.id,
                                fileName: file.name,
                                contentType: ct,
                                sizeBytes: bytes.length,
                              );
                              await repo.uploadAttachmentBytes(
                                uploadUrl: presign.uploadUrl,
                                bytes: bytes,
                                contentType: ct,
                              );
                              await repo.registerAttachment(
                                ticketId: detail.id,
                                storageKey: presign.storageKey,
                                fileName: file.name,
                                contentType: ct,
                                sizeBytes: bytes.length,
                              );
                              if (detailCtx.mounted) {
                                ScaffoldMessenger.of(detailCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.profileSupportAttachSuccess),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (detailCtx.mounted) {
                                ScaffoldMessenger.of(detailCtx).showSnackBar(
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
                              if (detailCtx.mounted) {
                                setDetailState(() => uploading = false);
                              }
                            }
                          },
                    icon: uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.attachment_rounded),
                    label: Text(
                      uploading
                          ? l10n.profileSupportAttachUploading
                          : l10n.profileSupportAttachImage,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.profileSupportTimeline,
                    style: Theme.of(detailCtx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...detail.events.map(
                    (e) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.timeline_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(e.message),
                      subtitle: Text('${e.actorType} · ${e.eventType}'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileSupportAttachments,
                    style: Theme.of(detailCtx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (detail.attachments.isEmpty)
                    Text(l10n.profileSupportNoAttachments)
                  else
                    ...detail.attachments.map(
                      (a) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onTap: a.previewUrl.isEmpty
                            ? null
                            : () {
                                showDialog<void>(
                                  context: detailCtx,
                                  builder: (_) => Dialog(
                                    insetPadding: const EdgeInsets.all(12),
                                    child: InteractiveViewer(
                                      minScale: 1,
                                      maxScale: 4,
                                      child: Image.network(
                                        a.previewUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Padding(
                                                  padding: EdgeInsets.all(24),
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                        leading: const Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          a.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${a.contentType} · ${a.sizeBytes} bytes',
                        ),
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
}
