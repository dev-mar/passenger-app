import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../network/passenger_api_client.dart';
import '../../gen_l10n/app_localizations.dart';

enum AppVersionGateOutcome {
  ok,
  optionalUpdate,
  forceBlocked,
}

class AppVersionGateResult {
  const AppVersionGateResult._(this.outcome);

  final AppVersionGateOutcome outcome;

  bool get canProceed => outcome != AppVersionGateOutcome.forceBlocked;

  static const ok = AppVersionGateResult._(AppVersionGateOutcome.ok);
  static const optionalUpdate =
      AppVersionGateResult._(AppVersionGateOutcome.optionalUpdate);
  static const forceBlocked =
      AppVersionGateResult._(AppVersionGateOutcome.forceBlocked);
}

class _AppVersionPolicy {
  const _AppVersionPolicy({
    required this.minVersionCode,
    required this.minVersionName,
    required this.force,
    required this.storeUrl,
  });

  final int minVersionCode;
  final String minVersionName;
  final bool force;
  final String storeUrl;
}

/// Comprueba versión mínima contra backend (fail-open si red falla).
class AppVersionGate {
  AppVersionGate._();

  static bool _checkedThisProcess = false;
  static AppVersionGateResult? _cachedResult;
  static _AppVersionPolicy? _cachedPolicy;

  static Future<AppVersionGateResult> ensureChecked() async {
    if (_checkedThisProcess && _cachedResult != null) {
      return _cachedResult!;
    }
    _checkedThisProcess = true;
    _cachedResult = await _evaluate();
    return _cachedResult!;
  }

  static Future<AppVersionGateResult> _evaluate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return AppVersionGateResult.ok;
    }
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(packageInfo.buildNumber.trim()) ?? 0;
      final policy = await _fetchPolicy().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (policy == null) return AppVersionGateResult.ok;
      _cachedPolicy = policy;
      if (localBuild >= policy.minVersionCode) {
        return AppVersionGateResult.ok;
      }
      if (policy.force) {
        return AppVersionGateResult.forceBlocked;
      }
      return AppVersionGateResult.optionalUpdate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppVersionGate] fail-open: $e');
      }
      return AppVersionGateResult.ok;
    }
  }

  static Future<_AppVersionPolicy?> _fetchPolicy() async {
    final dio = PassengerApiClient.createPublicDio(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    );
    final response = await dio.get<Map<String, dynamic>>(
      '${AppConfig.baseUrlAuth}/config/app-version',
    );
    final body = response.data;
    if (body == null || body['success'] != true) return null;
    final data = body['data'];
    if (data is! Map) return null;
    final passenger = data['passenger'];
    if (passenger is! Map) return null;
    final payload = Map<String, dynamic>.from(passenger);
    final minCodeRaw = payload['min_version_code'];
    final minCode = minCodeRaw is num
        ? minCodeRaw.toInt()
        : int.tryParse('${payload['min_version_code']}') ?? 1;
    final storeUrl = payload['store_url']?.toString().trim() ?? '';
    if (storeUrl.isEmpty) return null;
    return _AppVersionPolicy(
      minVersionCode: minCode,
      minVersionName: payload['min_version_name']?.toString() ?? '1.0.0',
      force: payload['force'] == true,
      storeUrl: storeUrl,
    );
  }

  static Future<void> showGateUi(
    BuildContext context,
    AppVersionGateResult result,
  ) async {
    if (!context.mounted) return;
    final policy = _cachedPolicy ?? await _fetchPolicy();
    if (!context.mounted) return;
    if (policy == null) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    if (result.outcome == AppVersionGateOutcome.forceBlocked) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(l10n.appUpdateRequiredTitle),
            content: Text(l10n.appUpdateRequiredMessage),
            actions: [
              FilledButton(
                onPressed: () => _openStore(policy.storeUrl),
                child: Text(l10n.appUpdateOpenStore),
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (result.outcome == AppVersionGateOutcome.optionalUpdate) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.appUpdateOptionalTitle),
          content: Text(l10n.appUpdateOptionalMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.appUpdateLater),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _openStore(policy.storeUrl);
              },
              child: Text(l10n.appUpdateOpenStore),
            ),
          ],
        ),
      );
    }
  }

  static Future<bool> runStartupCheck(BuildContext context) async {
    final result = await ensureChecked();
    if (!context.mounted) return false;
    if (!result.canProceed) {
      await showGateUi(context, result);
      return false;
    }
    if (result.outcome == AppVersionGateOutcome.optionalUpdate) {
      await showGateUi(context, result);
      if (!context.mounted) return false;
    }
    return true;
  }

  static Future<void> _openStore(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
