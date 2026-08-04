import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_lifecycle/passenger_app_visibility.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/passenger_api_client.dart';
import '../../core/network/passenger_api_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../core/network/passenger_client_meta.dart';
import '../../core/network/passenger_http_resilience.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/config/passenger_app_environment.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../core/notifications/passenger_notification_service.dart';
import '../../core/router/app_router.dart';
import 'login_controller.dart';
import 'utils/login_attempts_limit_dialog.dart';
import 'utils/login_auth_rate_limit.dart';
import 'widgets/login_auth_action_row.dart';
import 'widgets/login_auth_info_button.dart';
import 'widgets/login_whatsapp_brand_icon.dart';
import 'widgets/passenger_auth_shell.dart';

/// Pantalla para ingresar el código de 6 dígitos y activar al pasajero.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
    this.email,
    this.verificationChannel,
    this.challengeId,
    this.waDeepLink,
    this.linkPhoneMode = false,
    this.returnTo,
    this.waResumeMode,
  });

  final String countryCode;
  final String phoneNumber;
  final String? email;
  final String? verificationChannel;
  final String? challengeId;
  final String? waDeepLink;
  final bool linkPhoneMode;
  final String? returnTo;
  /// Tras toque en notificación local (`driver` | `link` | `profile`).
  final String? waResumeMode;

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen>
    with WidgetsBindingObserver {
  static const Duration _outboundHelpRevealDelay = Duration(seconds: 75);

  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _waPollTimer;
  bool _waWaiting = false;
  bool _waExpired = false;
  bool _waOutboundLoading = false;
  bool _outboundFallbackAvailable = false;
  bool _smsFallbackAvailable = false;
  bool _waVerifiedSuccess = false;
  bool _waVerifiedPendingNavigation = false;
  bool _waVerifiedReuseDriver = false;
  Timer? _outboundHelpTimer;
  bool _outboundHelpExpanded = false;

  bool get _isPlayReview => widget.verificationChannel == 'play_review';

  bool get _isWhatsAppOutbound =>
      widget.verificationChannel == 'whatsapp_outbound';

  bool get _isWhatsAppInbound =>
      widget.verificationChannel == 'whatsapp_inbound' &&
      (widget.challengeId?.isNotEmpty ?? false);

  bool get _isEmailLogin =>
      widget.verificationChannel == 'email' &&
      (widget.email?.trim().isNotEmpty ?? false);

  bool get _isSmsFirebase =>
      widget.verificationChannel == 'sms_firebase' ||
      widget.verificationChannel == 'sms';

  void _openSmsVerifyScreen() {
    context.goNamed(
      'verify_sms',
      queryParameters: {
        'cc': widget.countryCode,
        'phone': widget.phoneNumber,
      },
    );
  }

  PassengerApiClient get _api => ref.read(passengerApiClientProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isWhatsAppInbound) {
      _waWaiting = true;
      _waPollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _pollWhatsAppChallenge(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openWhatsAppDeepLink();
        _maybeResumeFromWaNotification();
      });
    } else if (_isSmsFirebase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openSmsVerifyScreen();
      });
    } else if (_isWhatsAppOutbound) {
      _outboundHelpTimer = Timer(_outboundHelpRevealDelay, () {
        if (!mounted || _outboundHelpExpanded) return;
        setState(() => _outboundHelpExpanded = true);
      });
    }
  }

  Future<void> _openWhatsAppDeepLink() async {
    final link = widget.waDeepLink?.trim();
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pollWhatsAppChallenge() async {
    if (!_isWhatsAppInbound || !mounted || _isLoading) return;
    final l10n = AppLocalizations.of(context)!;
    final phoneDigits = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final cc = widget.countryCode.startsWith('+')
        ? widget.countryCode
        : '+${widget.countryCode}';
    final fullPhone = '$cc$phoneDigits';

    try {
      final response = await _api.getPublic<Map<String, dynamic>>(
        path: AppConfig.authChallengeStatusPath,
        queryParameters: <String, String>{
          'phone_e164': fullPhone,
          'challenge_id': widget.challengeId!,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) return;
      if (body['success'] != true) return;
      final rawData = body['data'];
      if (rawData is! Map) return;
      final data = Map<String, dynamic>.from(rawData);
      final status = data['status']?.toString();
      if (status == 'expired') {
        _waPollTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _waWaiting = false;
          _waExpired = true;
          _outboundFallbackAvailable =
              data['fallback_channel'] == 'whatsapp_outbound';
          _smsFallbackAvailable = data['fallback_channel'] == 'sms_firebase';
        });
        return;
      }
      if (status != 'verified') return;

      await _onWhatsAppInboundVerified(data);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage ??= l10n.verifyCodeErrorNetwork;
      });
    }
  }

  Future<bool> _navigateIfAuthLockout({
    required String? code,
    dynamic responseData,
  }) async {
    if (await showLoginAuthRateLimitIfNeeded(
      context,
      code: code,
      responseData: responseData,
      countryCode: widget.countryCode,
      phoneNumber: widget.phoneNumber,
    )) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _waOutboundLoading = false;
        });
      }
      return true;
    }
    return false;
  }

  Future<void> _requestWhatsAppOutboundCode() async {
    if (!_isWhatsAppInbound || _waOutboundLoading) return;
    await _issueWhatsAppOutboundCode(showResentSnackBar: false);
  }

  Future<void> _resendWhatsAppOutboundCode() async {
    if (!_isWhatsAppOutbound || _waOutboundLoading) return;
    await _issueWhatsAppOutboundCode(showResentSnackBar: true);
  }

  Future<void> _issueWhatsAppOutboundCode({
    required bool showResentSnackBar,
  }) async {
    if (_waOutboundLoading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _waOutboundLoading = true;
      _errorMessage = null;
    });
    final cc = widget.countryCode.startsWith('+')
        ? widget.countryCode
        : '+${widget.countryCode}';
    final phoneDigits = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final fullPhone = '$cc$phoneDigits';
    final next = await ref.read(loginControllerProvider.notifier).requestWhatsAppOutbound(
          countryCode: widget.countryCode,
          phoneNumber: widget.phoneNumber,
          fullPhone: fullPhone,
        );
    if (!mounted) return;
    setState(() => _waOutboundLoading = false);
    if (next == LoginNextStep.stepUp ||
        next == LoginNextStep.attemptsLimitReached) {
      await showLoginAttemptsLimitDialog(context);
      return;
    }
    if (next == LoginNextStep.authLockout) {
      final lockout = ref.read(loginControllerProvider).authLockout;
      if (lockout != null) {
        await navigateToPassengerAuthLockout(
          context,
          lockout: lockout,
          countryCode: widget.countryCode,
          phoneNumber: widget.phoneNumber,
        );
      } else {
        await showLoginAttemptsLimitDialog(context);
      }
      return;
    }
    if (next == LoginNextStep.verifyCode) {
      if (showResentSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.verifyCodeOutboundResent),
          ),
        );
        _codeController.clear();
        setState(() => _errorMessage = null);
        return;
      }
      context.goNamed(
        'verify_code',
        queryParameters: {
          'cc': widget.countryCode,
          'phone': widget.phoneNumber,
          'channel': 'whatsapp_outbound',
        },
      );
      return;
    }
    setState(() {
      _errorMessage = ref.read(loginControllerProvider).errorMessage ??
          l10n.verifyCodeWaOutboundFailed;
    });
  }

  Future<void> _startWhatsAppInboundFromOutbound() async {
    if (!_isWhatsAppOutbound || _isLoading || _waOutboundLoading) return;
    final l10n = AppLocalizations.of(context)!;
    final phoneDigits = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final cc = widget.countryCode.startsWith('+')
        ? widget.countryCode
        : '+${widget.countryCode}';
    final fullPhone = '$cc$phoneDigits';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final next = await ref.read(loginControllerProvider.notifier).login(
          countryCode: widget.countryCode,
          phoneNumber: widget.phoneNumber,
          fullPhone: fullPhone,
          otpChannel: 'whatsapp_inbound',
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (next == LoginNextStep.stepUp ||
        next == LoginNextStep.attemptsLimitReached) {
      await showLoginAttemptsLimitDialog(context);
      return;
    }
    if (next == LoginNextStep.authLockout) {
      final lockout = ref.read(loginControllerProvider).authLockout;
      if (lockout != null) {
        await navigateToPassengerAuthLockout(
          context,
          lockout: lockout,
          countryCode: widget.countryCode,
          phoneNumber: widget.phoneNumber,
        );
      } else {
        await showLoginAttemptsLimitDialog(context);
      }
      return;
    }
    if (next == LoginNextStep.verifyCode) {
      final loginState = ref.read(loginControllerProvider);
      context.goNamed(
        'verify_code',
        queryParameters: {
          'cc': widget.countryCode,
          'phone': widget.phoneNumber,
          if (loginState.verificationChannel != null &&
              loginState.verificationChannel!.isNotEmpty)
            'channel': loginState.verificationChannel!,
          if (loginState.challengeId != null &&
              loginState.challengeId!.isNotEmpty)
            'challenge_id': loginState.challengeId!,
          if (loginState.waDeepLink != null &&
              loginState.waDeepLink!.isNotEmpty)
            'wa_deep_link': loginState.waDeepLink!,
        },
      );
      return;
    }
    setState(() {
      _errorMessage = ref.read(loginControllerProvider).errorMessage ??
          l10n.verifyCodeWaOutboundFailed;
    });
  }

  void _expandOutboundHelp() {
    if (_outboundHelpExpanded || !_isWhatsAppOutbound) return;
    TexiUiFeedback.softImpact();
    setState(() => _outboundHelpExpanded = true);
  }

  Widget _buildOutboundDeliveryHelp(AppLocalizations l10n) {
    if (_isPlayReview) {
      return const SizedBox.shrink();
    }
    if (!_isWhatsAppOutbound) {
      return Text(
        l10n.verifyCodeRetryHint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              height: 1.4,
              fontSize: 12.5,
            ),
        textAlign: TextAlign.center,
      );
    }

    final multichannel = PassengerAppEnvironment.multichannelAuthEnabled;
    final actionsEnabled = !_isLoading && !_waOutboundLoading;

    if (!_outboundHelpExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.verifyCodeRetryHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  height: 1.4,
                  fontSize: 12.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: actionsEnabled ? _expandOutboundHelp : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary.withValues(alpha: 0.92),
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.verifyCodeOutboundHelpLink,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.verifyCodeOutboundHelpSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  height: 1.45,
                  fontSize: 13,
                ),
          ),
          const SizedBox(height: 16),
          if (multichannel) ...[
            LoginAuthActionRow(
              enabled: actionsEnabled,
              highlighted: true,
              accent: LoginWhatsAppBrandIcon.brandGreen,
              icon: const LoginWhatsAppBrandIcon(size: 28),
              label: l10n.loginVerifyMethodWaInboundShort,
              badge: l10n.loginVerifyMethodRecommendedBadge,
              infoMessage: l10n.loginVerifyMethodWaInboundInfo,
              onTap: _startWhatsAppInboundFromOutbound,
            ),
            const SizedBox(height: 10),
          ],
          LoginAuthActionRow(
            enabled: actionsEnabled,
            highlighted: false,
            icon: Icon(
              Icons.pin_outlined,
              color: AppColors.textPrimary.withValues(alpha: 0.88),
              size: 22,
            ),
            label: l10n.verifyCodeOutboundResend,
            infoMessage: l10n.loginVerifyMethodCodeInfo,
            onTap: _resendWhatsAppOutboundCode,
          ),
          if (multichannel) ...[
            const SizedBox(height: 10),
            LoginAuthActionRow(
              enabled: actionsEnabled,
              highlighted: false,
              icon: Icon(
                Icons.sms_outlined,
                color: AppColors.textPrimary.withValues(alpha: 0.88),
                size: 22,
              ),
              label: l10n.verifyCodeWaRequestSms,
              infoMessage: l10n.verifyCodeSmsSubtitle(
                '${widget.countryCode} ${widget.phoneNumber.replaceAll(RegExp(r".(?=.{2})"), "•")}',
              ),
              onTap: _requestSmsFirebaseCode,
            ),
          ],
        ],
      ),
    );
  }

  void _requestSmsFirebaseCode() {
    _openSmsVerifyScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waPollTimer?.cancel();
    _outboundHelpTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_waVerifiedPendingNavigation) {
      unawaited(_completeWaVerifiedNavigation());
      return;
    }
    if (_isWhatsAppInbound && !_waVerifiedSuccess && !_waExpired) {
      unawaited(_pollWhatsAppChallenge());
    }
  }

  void _maybeResumeFromWaNotification() {
    final mode = widget.waResumeMode?.trim();
    if (mode == null || mode.isEmpty) return;
    if (mode == 'driver') {
      unawaited(_completePassengerFromDriver());
      return;
    }
    if (mode == 'link') {
      unawaited(_completeWaVerifiedNavigation(reuseDriver: false));
      return;
    }
    if (mode == 'profile') {
      unawaited(_completeWaVerifiedNavigation(reuseDriver: false));
    }
  }

  Future<void> _onWhatsAppInboundVerified(Map<String, dynamic> data) async {
    _waPollTimer?.cancel();
    if (!mounted) return;

    final reuseDriver = data['reuse_driver_profile'] == true ||
        data['reuse_driver_profile'] == 'true';
    final inForeground = PassengerAppVisibility.isInForeground.value;

    if (!inForeground) {
      setState(() {
        _waWaiting = false;
        _waVerifiedPendingNavigation = true;
        _waVerifiedReuseDriver = reuseDriver;
      });
      final challengeId = widget.challengeId?.trim();
      if (challengeId != null && challengeId.isNotEmpty) {
        await PassengerNotificationService.instance
            .showWaInboundVerifiedReturnPrompt(
          challengeId: challengeId,
          countryCode: widget.countryCode,
          phoneNumber: widget.phoneNumber,
          reuseDriverProfile: reuseDriver,
          linkPhoneMode: widget.linkPhoneMode,
          returnTo: widget.returnTo,
        );
      }
      return;
    }

    setState(() {
      _waWaiting = false;
      _waVerifiedSuccess = true;
      _errorMessage = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _completeWaVerifiedNavigation(reuseDriver: reuseDriver);
  }

  Future<void> _completeWaVerifiedNavigation({bool? reuseDriver}) async {
    if (_isLoading) return;
    await PassengerNotificationService.instance
        .cancelWaInboundVerifiedReturnPrompt();
    _waVerifiedPendingNavigation = false;

    final useDriver = reuseDriver ?? _waVerifiedReuseDriver;
    if (useDriver) {
      setState(() {
        _isLoading = true;
        _waWaiting = false;
      });
      await _completePassengerFromDriver();
      return;
    }

    final phoneDigits = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final cc = widget.countryCode.startsWith('+')
        ? widget.countryCode
        : '+${widget.countryCode}';
    final fullPhone = '$cc$phoneDigits';
    await AuthService.persistLoginPhoneE164(fullPhone);
    if (!mounted) return;

    if (widget.linkPhoneMode) {
      final returnTo = widget.returnTo?.trim();
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      } else {
        context.goNamed(AppRouter.tripRequest);
      }
      return;
    }

    context.goNamed(
      AppRouter.profileSetup,
      queryParameters: {
        'cc': widget.countryCode,
        'phone': widget.phoneNumber,
      },
    );
  }

  /// Mismo número ya registrado como conductor: completar pasajero con datos existentes (solo OTP).
  Future<void> _completePassengerFromDriver() async {
    final l10n = AppLocalizations.of(context)!;
    final phoneDigits =
        widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final cc = widget.countryCode.startsWith('+')
        ? widget.countryCode
        : '+${widget.countryCode}';
    final fullPhone = '$cc$phoneDigits';

    try {
      final clientMeta = await passengerAuthClientMeta();
      final googleLinkToken =
          ref.read(loginControllerProvider).googleLinkToken?.trim();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.authUsersPath,
        data: <String, dynamic>{
          ...clientMeta,
          'phone_number': fullPhone,
          'alias_name': '',
          'profile_picture': null,
          'reuse_driver_profile': true,
          if (googleLinkToken != null && googleLinkToken.isNotEmpty)
            'google_link_token': googleLinkToken,
        },
      );

      final body = response.data;
      if (body is! Map) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.verifyCodeErrorActivateAccount;
        });
        return;
      }
      final envelope = Map<String, dynamic>.from(body as Map);
      if (envelope['success'] != true) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = envelope['message']?.toString() ??
              l10n.verifyCodeErrorActivateAccount;
        });
        return;
      }

      final data = envelope['data'];
      if (data is! Map) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.verifyCodeErrorIncompleteResponse;
        });
        return;
      }

      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.verifyCodeErrorTokenMissing;
        });
        return;
      }

      final refreshToken = data['refresh_token']?.toString();
      final expiresIn = data['expires_in'];
      int? expiresInSec;
      if (expiresIn is int) {
        expiresInSec = expiresIn;
      } else if (expiresIn is num) {
        expiresInSec = expiresIn.toInt();
      }

      await AuthService.saveSession(
        token: token,
        refreshToken: refreshToken,
        expiresInSeconds: expiresInSec,
      );
      await AuthService.persistLoginPhoneE164(fullPhone);
      final display = data['display_name']?.toString().trim();
      if (display != null && display.isNotEmpty) {
        await AuthService.savePassengerDisplayName(display);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.goNamed('trip_request');
    } on DioException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final d = e.response?.data;
      final code = TexiBackendError.codeFromResponse(d);
      final raw = TexiBackendError.messageFromResponse(d) ??
          (d is Map ? d['message']?.toString() : null);
      setState(() {
        _isLoading = false;
        _errorMessage = (code != null && code.startsWith('RBAC_'))
            ? localizedTripApiError(l10n, code, fallbackMessage: raw)
            : (raw ?? l10n.verifyCodeErrorNetwork);
      });
    }
  }

  Future<void> _verify() async {
    _codeFocusNode.unfocus();
    TexiUiFeedback.softImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final codeText = _codeController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (codeText.length != 6 || int.tryParse(codeText) == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.verifyCodeErrorInvalidCodeInput;
      });
      return;
    }

    if (_isEmailLogin) {
      final email = widget.email!.trim();
      final next = await ref
          .read(loginControllerProvider.notifier)
          .verifyEmailLoginCode(email: email, code: codeText);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (next == LoginNextStep.tripRequest) {
        context.goNamed('trip_request');
        return;
      }
      if (next == LoginNextStep.profileRequired) {
        context.goNamed(
          'profile_setup',
          queryParameters: {'email': email},
        );
        return;
      }
      if (next == LoginNextStep.attemptsLimitReached) {
        await showLoginAttemptsLimitDialog(context);
        if (!mounted) return;
        context.goNamed('login');
        return;
      }
      if (next == LoginNextStep.authLockout) {
        final lockout = ref.read(loginControllerProvider).authLockout;
        if (lockout != null) {
          await navigateToPassengerAuthLockout(
            context,
            lockout: lockout,
            countryCode: widget.countryCode,
            phoneNumber: widget.phoneNumber,
          );
        } else {
          await showLoginAttemptsLimitDialog(context);
          if (!mounted) return;
          context.goNamed('login');
        }
        return;
      }
      if (next == LoginNextStep.error) {
        final loginState = ref.read(loginControllerProvider);
        if (await showLoginAuthRateLimitIfNeeded(
          context,
          code: loginState.errorCode,
        )) {
          if (!mounted) return;
          context.goNamed('login');
          return;
        }
        setState(() => _errorMessage = loginState.errorMessage);
      }
      return;
    }

    final phoneOnlyDigits =
        widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (widget.linkPhoneMode) {
      final ok = await ref.read(loginControllerProvider.notifier).linkPhoneVerify(
            countryCode: widget.countryCode,
            phoneNumber: phoneOnlyDigits,
            verificationCode: codeText,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (ok) {
        final ccNav = widget.countryCode.startsWith('+')
            ? widget.countryCode
            : '+${widget.countryCode}';
        await AuthService.persistLoginPhoneE164('$ccNav$phoneOnlyDigits');
        await ref
            .read(passengerMeProfileServiceProvider)
            .fetchData(forceRefresh: true);
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.phoneLinkSuccess),
          ),
        );
        final dest = widget.returnTo?.trim();
        if (dest != null && dest.isNotEmpty) {
          context.goNamed(dest);
        } else {
          context.goNamed('trip_request');
        }
        return;
      }
      setState(() => _errorMessage = l10n.verifyCodeErrorValidateCode);
      return;
    }

    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.authVerifyCodePath,
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': widget.countryCode,
          'phone_number': phoneOnlyDigits,
          'verification_code': codeText,
        },
      );

      final body = response.data;
      if (body is! Map) {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.verifyCodeErrorValidateCode;
        });
        return;
      }
      final envelope = Map<String, dynamic>.from(body as Map);
      if (envelope['success'] != true) {
        final message = envelope['message']?.toString() ??
            l10n.verifyCodeErrorValidateCode;
        final code = envelope['code']?.toString();
        if (!mounted) return;
        if (await _navigateIfAuthLockout(code: code, responseData: envelope)) {
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
        return;
      }

      if (!mounted) return;

      final rawData = envelope['data'];
      final reuseDriver = rawData is Map &&
          (rawData['reuse_driver_profile'] == true ||
              rawData['reuse_driver_profile'] == 'true');

      if (reuseDriver) {
        await _completePassengerFromDriver();
        return;
      }

      setState(() => _isLoading = false);

      final phoneDigitsNav = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final ccNav = widget.countryCode.startsWith('+')
          ? widget.countryCode
          : '+${widget.countryCode}';
      await AuthService.persistLoginPhoneE164('$ccNav$phoneDigitsNav');

      if (!mounted) return;
      // Código válido: continuar con UX de perfil (nombre obligatorio + foto opcional).
      context.goNamed(
        'profile_setup',
        queryParameters: {
          'cc': widget.countryCode,
          'phone': widget.phoneNumber,
        },
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final code = TexiBackendError.codeFromResponse(data);
      final networkCode = networkErrorCodeFromDio(e);
      if (networkCode == 'NETWORK_TIMEOUT') {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.verifyCodeErrorNetwork;
        });
        return;
      }
      if (networkCode == 'NETWORK_CONNECTION') {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.verifyCodeErrorConnection;
        });
        return;
      }
      final backendMsg = TexiBackendError.messageFromResponse(data);
      String? detail;
      if (data is Map<String, dynamic>) {
        final err = data['error'];
        if (err is Map) {
          detail = err['details']?.toString();
        }
      }
      final fallback = detail ??
          backendMsg ??
          (data is Map ? data['message']?.toString() : null) ??
          (e.message != null && e.message!.isNotEmpty ? e.message! : null);
      if (!mounted) return;
      if (await _navigateIfAuthLockout(code: code, responseData: data)) {
        return;
      }
      final message = (code != null && code.startsWith('RBAC_'))
          ? localizedTripApiError(l10n, code, fallbackMessage: fallback)
          : localizedTripApiError(l10n, code, fallbackMessage: fallback);
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.verifyCodeErrorUnexpected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maskedPhone =
        '${widget.countryCode} ${widget.phoneNumber.replaceAll(RegExp(r".(?=.{2})"), "•")}';

    return PassengerAuthShell(
      loading: _isLoading,
      loadingMessage: l10n.commonLoading,
      leading: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: _isLoading ? null : () => context.goNamed('login'),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      child: PassengerAuthEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 42),
                  child: Text(
                    _isWhatsAppInbound
                        ? l10n.verifyCodeWaTitle
                        : l10n.verifyCodeTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: LoginAuthInfoButton(
                    message: _isWhatsAppInbound
                        ? l10n.verifyCodeWaInfo
                        : l10n.verifyCodeEntryInfo,
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isWhatsAppInbound
                  ? l10n.verifyCodeWaSubtitle(maskedPhone)
                  : _isPlayReview
                      ? l10n.verifyCodePlayReviewSubtitle
                      : l10n.verifyCodeSubtitle(maskedPhone),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    height: 1.4,
                    fontSize: 13.5,
                  ),
            ),
            if (_isWhatsAppInbound) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isLoading ? null : _openWhatsAppDeepLink,
                icon: const Icon(Icons.chat_rounded),
                label: Text(l10n.verifyCodeWaOpenButton),
              ),
              if (_waWaiting || _waVerifiedSuccess) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _waVerifiedSuccess
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      size: 20,
                      color: _waVerifiedSuccess
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _waVerifiedSuccess
                            ? l10n.verifyCodeWaVerified
                            : l10n.verifyCodeWaWaiting,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _waVerifiedSuccess
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.verifyCodeWaFallbackHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                    ),
              ),
              if (_waExpired && _outboundFallbackAvailable) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _waOutboundLoading ? null : _requestWhatsAppOutboundCode,
                  child: Text(l10n.verifyCodeWaRequestOutbound),
                ),
              ],
              if (_waExpired && _smsFallbackAvailable) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _requestSmsFirebaseCode,
                  child: Text(l10n.verifyCodeWaRequestSms),
                ),
              ],
            ],
            if (_isWhatsAppInbound && _errorMessage != null) ...[
              const SizedBox(height: 12),
              PremiumStateView(
                icon: Icons.error_outline_rounded,
                title: l10n.loginReviewDataTitle,
                message: _errorMessage!,
                actionLabel: l10n.homeRetry,
                onAction: () {
                  setState(() => _errorMessage = null);
                  _pollWhatsAppChallenge();
                },
              ),
            ],
            if (!_isWhatsAppInbound && !_isSmsFirebase) ...[
            const SizedBox(height: 22),
            PassengerAuthGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: l10n.verifyCodeFieldLabel,
                    child: TextField(
                      controller: _codeController,
                      focusNode: _codeFocusNode,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: passengerAuthFieldDecoration(
                        label: l10n.verifyCodeFieldLabel,
                        hint: l10n.verifyCodeMaskHint,
                      ).copyWith(counterText: ''),
                      onSubmitted: (_) => _verify(),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.xxx),
                    PremiumStateView(
                      icon: Icons.sms_failed_rounded,
                      title: l10n.loginReviewDataTitle,
                      message: _errorMessage!,
                      actionLabel: l10n.homeRetry,
                      onAction: _verify,
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: TexiScalePress(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _verify,
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          ),
                        ),
                        child: Text(
                          l10n.verifyCodeConfirm,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildOutboundDeliveryHelp(l10n),
            ],
          ],
        ),
      ),
    );
  }
}

