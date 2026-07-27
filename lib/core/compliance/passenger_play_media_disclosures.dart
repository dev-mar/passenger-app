import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../gen_l10n/app_localizations.dart';

/// Divulgación Play antes de abrir cámara o galería (Google Play User Data).
Future<bool> passengerEnsureMediaDisclosureBeforePick(
  BuildContext context,
  AppLocalizations l10n, {
  required ImageSource source,
}) async {
  if (!context.mounted) return false;

  final isCamera = source == ImageSource.camera;
  final title = isCamera
      ? l10n.passengerPlayCameraDisclosureTitle
      : l10n.passengerPlayGalleryDisclosureTitle;
  final body = isCamera
      ? l10n.passengerPlayCameraDisclosureBody
      : l10n.passengerPlayGalleryDisclosureBody;

  final proceed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.passengerPlayDisclosureContinue),
          ),
        ],
      );
    },
  );
  return proceed == true;
}
