import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../router/app_router.dart';
import '../../gen_l10n/app_localizations.dart';

/// Google Play In-App Updates (Android). Fail-open fuera de Play Store o sin red.
class PlayInAppUpdateHelper {
  PlayInAppUpdateHelper._();

  static StreamSubscription<InstallStatus>? _installSubscription;
  static bool _listenerRegistered = false;

  static bool get _isSupported => !kIsWeb && Platform.isAndroid;

  static void ensureFlexibleUpdateListener() {
    if (!_isSupported || _listenerRegistered) return;
    _listenerRegistered = true;
    _installSubscription?.cancel();
    _installSubscription = InAppUpdate.installUpdateListener.listen(
      _onInstallStatus,
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('[PlayInAppUpdate] listener error: $e');
        }
      },
    );
  }

  static void _onInstallStatus(InstallStatus status) {
    if (status != InstallStatus.downloaded) return;
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.appUpdateDownloadedMessage),
        action: SnackBarAction(
          label: l10n.appUpdateRestart,
          onPressed: () {
            unawaited(InAppUpdate.completeFlexibleUpdate());
          },
        ),
        duration: const Duration(days: 1),
      ),
    );
  }

  /// Actualización inmediata (bloqueante). Solo cuando Play lo permite.
  static Future<bool> tryImmediateUpdate() async {
    if (!_isSupported) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }
      if (!info.immediateUpdateAllowed) return false;
      final result = await InAppUpdate.performImmediateUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PlayInAppUpdate] immediate fail-open: $e');
      }
      return false;
    }
  }

  /// Descarga flexible en segundo plano. El listener avisa cuando está lista.
  static Future<bool> tryFlexibleUpdate() async {
    if (!_isSupported) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }
      if (!info.flexibleUpdateAllowed) return false;
      ensureFlexibleUpdateListener();
      final result = await InAppUpdate.startFlexibleUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PlayInAppUpdate] flexible fail-open: $e');
      }
      return false;
    }
  }

  /// Cuando el backend no exige update, aún puede haber versión nueva en Play.
  static void scheduleOptionalPlayUpdateCheck() {
    if (!_isSupported) return;
    ensureFlexibleUpdateListener();
    unawaited(tryFlexibleUpdate());
  }
}
