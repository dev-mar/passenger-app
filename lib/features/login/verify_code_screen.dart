import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../core/l10n/trip_error_localization.dart';
import 'login_controller.dart';
import 'widgets/passenger_auth_shell.dart';

/// Pantalla para ingresar el código de 6 dígitos y activar al pasajero.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
    this.verificationChannel,
    this.challengeId,
    this.waDeepLink,
  });

  final String countryCode;
  final String phoneNumber;
  final String? verificationChannel;
  final String? challengeId;
  final String? waDeepLink;

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _waPollTimer;
  bool _waWaiting = false;
  bool _waExpired = false;
  bool _waOutboundLoading = false;

  bool get _isWhatsAppInbound =>
      widget.verificationChannel == 'whatsapp_inbound' &&
      (widget.challengeId?.isNotEmpty ?? false);

  PassengerApiClient get _api => ref.read(passengerApiClientProvider);

  @override
  void initState() {
    super.initState();
    if (_isWhatsAppInbound) {
      _waWaiting = true;
      _waPollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _pollWhatsAppChallenge(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openWhatsAppDeepLink();
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
          _waExpired = data['fallback_channel'] == 'whatsapp_outbound';
        });
        return;
      }
      if (status != 'verified') return;

      _waPollTimer?.cancel();
      if (!mounted) return;

      final reuseDriver = data['reuse_driver_profile'] == true ||
          data['reuse_driver_profile'] == 'true';
      if (reuseDriver) {
        setState(() {
          _isLoading = true;
          _waWaiting = false;
        });
        await _completePassengerFromDriver();
        return;
      }

      await AuthService.persistLoginPhoneE164(fullPhone);
      if (!mounted) return;
      context.goNamed(
        'profile_setup',
        queryParameters: {
          'cc': widget.countryCode,
          'phone': widget.phoneNumber,
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage ??= l10n.verifyCodeErrorNetwork;
      });
    }
  }

  Future<void> _requestWhatsAppOutboundCode() async {
    if (!_isWhatsAppInbound || _waOutboundLoading) return;
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
    if (next == LoginNextStep.stepUp) {
      context.goNamed(
        'auth_step_up',
        queryParameters: {'cc': widget.countryCode, 'phone': widget.phoneNumber},
      );
      return;
    }
    if (next == LoginNextStep.verifyCode) {
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

  @override
  void dispose() {
    _waPollTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
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

    final phoneOnlyDigits =
        widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

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
            Text(
              _isWhatsAppInbound ? l10n.verifyCodeWaTitle : l10n.verifyCodeTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isWhatsAppInbound
                  ? l10n.verifyCodeWaSubtitle(maskedPhone)
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
              if (_waWaiting) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        l10n.verifyCodeWaWaiting,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
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
              if (_waExpired) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _waOutboundLoading ? null : _requestWhatsAppOutboundCode,
                  child: Text(l10n.verifyCodeWaRequestOutbound),
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
            if (!_isWhatsAppInbound) ...[
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.verifyCodeConfirm,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.verifyCodeRetryHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    height: 1.4,
                    fontSize: 12.5,
                  ),
              textAlign: TextAlign.center,
            ),
            ],
          ],
        ),
      ),
    );
  }
}

