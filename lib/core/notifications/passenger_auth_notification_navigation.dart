import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../router/app_router.dart';
import 'passenger_notification_service.dart';

/// Payload local: `auth:wa_inbound:profile|driver|link?cc=...&phone=...`
class PassengerWaInboundVerifiedPayload {
  const PassengerWaInboundVerifiedPayload({
    required this.action,
    required this.countryCode,
    required this.phoneNumber,
    this.returnTo,
  });

  final String action;
  final String countryCode;
  final String phoneNumber;
  final String? returnTo;
}

class PassengerAuthNotificationNavigation {
  PassengerAuthNotificationNavigation._();

  static const String _prefix = 'auth:wa_inbound:';

  static bool isAuthPayload(String? raw) {
    final v = raw?.trim() ?? '';
    return v.startsWith('auth:');
  }

  static String buildWaInboundVerifiedPayload({
    required bool reuseDriverProfile,
    required bool linkPhoneMode,
    required String countryCode,
    required String phoneNumber,
    String? returnTo,
  }) {
    final action = linkPhoneMode
        ? 'link'
        : (reuseDriverProfile ? 'driver' : 'profile');
    final cc = Uri.encodeComponent(countryCode);
    final phone = Uri.encodeComponent(phoneNumber);
    final base = '$_prefix$action?cc=$cc&phone=$phone';
    if (linkPhoneMode && returnTo != null && returnTo.trim().isNotEmpty) {
      return '$base&return_to=${Uri.encodeComponent(returnTo.trim())}';
    }
    return base;
  }

  static PassengerWaInboundVerifiedPayload? parsePayload(String? raw) {
    final value = raw?.trim() ?? '';
    if (!value.startsWith(_prefix)) return null;
    final rest = value.substring(_prefix.length);
    final qIndex = rest.indexOf('?');
    if (qIndex < 0) return null;
    final action = rest.substring(0, qIndex).trim();
    if (action.isEmpty) return null;
    final params = Uri.splitQueryString(rest.substring(qIndex + 1));
    final cc = params['cc']?.trim();
    final phone = params['phone']?.trim();
    if (cc == null || cc.isEmpty || phone == null || phone.isEmpty) {
      return null;
    }
    return PassengerWaInboundVerifiedPayload(
      action: action,
      countryCode: cc,
      phoneNumber: phone,
      returnTo: params['return_to']?.trim(),
    );
  }

  static Future<void> handleLocalNotificationTap(String? payload) async {
    final parsed = parsePayload(payload);
    if (parsed == null) return;

    if (await AuthService.hasStoredSession()) {
      await PassengerNotificationService.instance
          .cancelWaInboundVerifiedReturnPrompt();
      return;
    }

    await PassengerNotificationService.instance
        .cancelWaInboundVerifiedReturnPrompt();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;

      switch (parsed.action) {
        case 'driver':
          AppRouter.router.goNamed(
            AppRouter.verifyCode,
            queryParameters: <String, String>{
              'cc': parsed.countryCode,
              'phone': parsed.phoneNumber,
              'channel': 'whatsapp_inbound',
              'wa_resume': 'driver',
            },
          );
          break;
        case 'link':
          AppRouter.router.goNamed(
            AppRouter.verifyCode,
            queryParameters: <String, String>{
              'cc': parsed.countryCode,
              'phone': parsed.phoneNumber,
              'channel': 'whatsapp_inbound',
              'wa_resume': 'link',
              if (parsed.returnTo != null && parsed.returnTo!.isNotEmpty)
                'return_to': parsed.returnTo!,
              'link': '1',
            },
          );
          break;
        case 'profile':
        default:
          unawaited(_persistPhoneAndGoProfile(parsed));
          break;
      }
    });
  }

  static Future<void> _persistPhoneAndGoProfile(
    PassengerWaInboundVerifiedPayload parsed,
  ) async {
    final phoneDigits = parsed.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final cc = parsed.countryCode.startsWith('+')
        ? parsed.countryCode
        : '+${parsed.countryCode}';
    await AuthService.persistLoginPhoneE164('$cc$phoneDigits');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.router.goNamed(
        AppRouter.profileSetup,
        queryParameters: <String, String>{
          'cc': parsed.countryCode,
          'phone': parsed.phoneNumber,
        },
      );
    });
  }
}

void schedulePassengerAuthLocalNotificationTap(String? payload) {
  unawaited(PassengerAuthNotificationNavigation.handleLocalNotificationTap(payload));
}
