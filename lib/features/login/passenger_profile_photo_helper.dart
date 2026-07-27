import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/compliance/passenger_play_media_disclosures.dart';
import '../../gen_l10n/app_localizations.dart';

/// Límites alineados al selfie del conductor (`facePortrait`).
const int kPassengerProfilePhotoMaxBytes = 320 * 1024;
const double kPassengerProfilePhotoPickerMaxEdge = 1920;
const int kPassengerProfilePhotoCropMaxEdge = 640;

const bool kPassengerSelfieCropEnabled = bool.fromEnvironment(
  'PASSENGER_SELFIE_CROP_ENABLED',
  defaultValue: bool.fromEnvironment(
    'SELFIE_CROP_ENABLED',
    defaultValue: true,
  ),
);

class PassengerProfilePhotoPickResult {
  const PassengerProfilePhotoPickResult({
    required this.bytes,
    required this.base64,
  });

  final Uint8List bytes;
  final String base64;
}

typedef PassengerProfilePhotoPickOutcome = ({
  PassengerProfilePhotoPickResult? result,
  bool tooLarge,
});

Future<PassengerProfilePhotoPickOutcome> pickPassengerProfilePhoto(
  BuildContext context,
  ImageSource source,
) async {
  final l10n = AppLocalizations.of(context)!;
  if (!await passengerEnsureMediaDisclosureBeforePick(context, l10n, source: source)) {
    return (result: null, tooLarge: false);
  }
  final picker = ImagePicker();
  final xfile = await picker.pickImage(
    source: source,
    imageQuality: 85,
    maxWidth: kPassengerProfilePhotoPickerMaxEdge,
  );
  if (xfile == null) return (result: null, tooLarge: false);

  final cropTitle = l10n.profilePhotoCropTitle;
  var path = xfile.path;
  if (kPassengerSelfieCropEnabled) {
    if (!context.mounted) return (result: null, tooLarge: false);
    path = await _maybeCropFacePath(context, path, cropTitle);
  }

  var bytes = await XFile(path).readAsBytes();
  if (bytes.isEmpty) return (result: null, tooLarge: false);

  if (bytes.lengthInBytes > kPassengerProfilePhotoMaxBytes) {
    final compressed = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: kPassengerProfilePhotoCropMaxEdge,
      minHeight: kPassengerProfilePhotoCropMaxEdge,
      quality: 72,
      format: CompressFormat.jpeg,
    );
    if (compressed != null && compressed.isNotEmpty) {
      bytes = compressed;
    }
  }

  if (bytes.lengthInBytes > kPassengerProfilePhotoMaxBytes) {
    return (result: null, tooLarge: true);
  }

  return (
    result: PassengerProfilePhotoPickResult(
      bytes: bytes,
      base64: base64Encode(bytes),
    ),
    tooLarge: false,
  );
}

Future<String> _maybeCropFacePath(
  BuildContext context,
  String sourcePath,
  String title,
) async {
  try {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      maxWidth: kPassengerProfilePhotoCropMaxEdge,
      maxHeight: kPassengerProfilePhotoCropMaxEdge,
      compressQuality: 82,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: const Color(0xFFFFFFFF),
          toolbarWidgetColor: const Color(0xFF1C1B1F),
          statusBarLight: true,
          navBarLight: true,
          hideBottomControls: false,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: title,
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: false,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null) return sourcePath;
    return cropped.path;
  } catch (_) {
    return sourcePath;
  }
}
