import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/passenger_api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_safe_scrolling.dart';
import '../../../gen_l10n/app_localizations.dart';
import '../../login/passenger_profile_photo_helper.dart';
import '../passenger_profile_models.dart';

Future<bool> showPassengerProfileEditSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PassengerProfileVm profile,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final repo = ref.read(passengerProfileRepositoryProvider);
  final nameCtrl = TextEditingController(text: profile.displayName);
  final emailCtrl = TextEditingController(text: profile.email ?? '');
  Uint8List? selectedPhotoBytes;
  String? selectedPhotoB64;
  var saving = false;
  var saved = false;

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
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  AppSafeScrolling.systemNavBottom(ctx),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.profileActionEditInfo,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.surface,
                        backgroundImage: selectedPhotoBytes != null
                            ? MemoryImage(selectedPhotoBytes!)
                            : (profile.profilePhotoUrl != null &&
                                  profile.profilePhotoUrl!.isNotEmpty)
                            ? NetworkImage(profile.profilePhotoUrl!)
                            : null,
                        child:
                            selectedPhotoBytes == null &&
                                (profile.profilePhotoUrl == null ||
                                    profile.profilePhotoUrl!.isEmpty)
                            ? const Icon(
                                Icons.person_rounded,
                                size: 36,
                                color: AppColors.textSecondary,
                              )
                            : null,
                      ),
                      Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final pick = await pickPassengerProfilePhoto(
                                    ctx,
                                    ImageSource.gallery,
                                  );
                                  if (!ctx.mounted) return;
                                  if (pick.tooLarge) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.profilePhotoTooLarge),
                                      ),
                                    );
                                    return;
                                  }
                                  final result = pick.result;
                                  if (result == null) return;
                                  setSheetState(() {
                                    selectedPhotoBytes = result.bytes;
                                    selectedPhotoB64 = result.base64;
                                  });
                                },
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.profileEditDisplayNameLabel,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.profileFieldEmail,
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          if (name.length < 2) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.profileEditNameInvalid),
                                ),
                              );
                            }
                            return;
                          }
                          setSheetState(() => saving = true);
                          try {
                            await repo.updateProfile(
                              displayName: name,
                              email: email.isNotEmpty ? email : null,
                              profilePictureBase64: selectedPhotoB64,
                            );
                            if (!ctx.mounted) return;
                            saved = true;
                            Navigator.of(ctx).pop();
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
                          } finally {
                            if (ctx.mounted) setSheetState(() => saving = false);
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    saving
                        ? l10n.profileEditSaving
                        : l10n.profileEditSaveChanges,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  nameCtrl.dispose();
  emailCtrl.dispose();
  return saved;
}
