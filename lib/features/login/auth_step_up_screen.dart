import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/passenger_api_client.dart';
import '../../core/network/passenger_api_providers.dart';
import '../../core/network/passenger_client_meta.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';
import 'widgets/passenger_auth_captcha_card.dart';
import 'widgets/passenger_auth_shell.dart';
import 'widgets/passenger_turnstile_widget.dart';
import 'services/passenger_google_sign_in_service.dart';

/// Fase 2 — verificación adicional (email + captcha) para desbloquear login.
class AuthStepUpScreen extends ConsumerStatefulWidget {
  const AuthStepUpScreen({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
  });

  final String countryCode;
  final String phoneNumber;

  @override
  ConsumerState<AuthStepUpScreen> createState() => _AuthStepUpScreenState();
}

class _AuthStepUpScreenState extends ConsumerState<AuthStepUpScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _turnstileKey = GlobalKey<PassengerTurnstileWidgetState>();
  String? _captchaToken;
  bool _emailSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  final _googleSignIn = PassengerGoogleSignInService();

  PassengerApiClient get _api => ref.read(passengerApiClientProvider);

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    if (local.length <= 2) return email;
    return '${local.substring(0, 2)}•••@${parts[1]}';
  }

  Future<void> _sendEmailCode() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = l10n.stepUpEmailInvalid);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.authStepUpEmailChallengePath,
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': widget.countryCode,
          'phone_number': widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          'email': email,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        setState(() {
          _isLoading = false;
          _errorMessage = body is Map<String, dynamic>
              ? body['message']?.toString() ?? l10n.stepUpEmailSendFailed
              : l10n.stepUpEmailSendFailed;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
        _captchaToken = null;
        _codeController.clear();
      });
      TexiUiFeedback.softImpact();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = TexiBackendError.messageFromResponse(e.response?.data) ??
            l10n.stepUpEmailSendFailed;
      });
    }
  }

  Future<void> _pickDeviceEmail() async {
    if (!_googleSignIn.isConfigured) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final email = await _googleSignIn.pickAccountEmail();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (email == null) return;
      _emailController.text = email;
      TexiUiFeedback.softImpact();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeStepUp() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (email.isEmpty || code.length != 6) {
      setState(() => _errorMessage = l10n.stepUpCodeInvalid);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_captchaToken == null || _captchaToken!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.stepUpCaptchaRequired;
      });
      return;
    }

    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.authStepUpCompletePath,
        data: <String, dynamic>{
          ...clientMeta,
          'country_code': widget.countryCode,
          'phone_number': widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), ''),
          'email': email,
          'email_code': code,
          'captcha_token': _captchaToken,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        final msg = body is Map<String, dynamic>
            ? body['message']?.toString() ?? l10n.stepUpCompleteFailed
            : l10n.stepUpCompleteFailed;
        final codeRaw = body is Map<String, dynamic> ? body['code']?.toString() : null;
        if (_isCaptchaFailure(msg, codeRaw)) {
          _captchaToken = null;
          await _turnstileKey.currentState?.resetWidget();
        }
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
        return;
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      TexiUiFeedback.softImpact();
      context.goNamed(
        'login',
        queryParameters: {
          'cc': widget.countryCode,
          'phone': widget.phoneNumber,
          'step_up_done': '1',
        },
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = TexiBackendError.messageFromResponse(data) ??
          l10n.stepUpCompleteFailed;
      final codeRaw = data is Map ? data['code']?.toString() : null;
      if (_isCaptchaFailure(msg, codeRaw)) {
        _captchaToken = null;
        await _turnstileKey.currentState?.resetWidget();
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    }
  }

  bool _isCaptchaFailure(String message, String? code) {
    if (code == 'PASS_AUTH_CAPTCHA_FAILED' ||
        code == 'PASS_AUTH_CAPTCHA_NOT_CONFIGURED') {
      return true;
    }
    final lower = message.toLowerCase();
    return lower.contains('captcha');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final canConfirm = _emailSent &&
        _codeController.text.trim().length == 6 &&
        _captchaToken != null &&
        !_isLoading;

    return PassengerAuthShell(
      loading: _isLoading,
      loadingMessage: l10n.commonLoading,
      leading: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: _isLoading ? null : () => context.goNamed('login'),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
        ),
      ),
      child: PassengerAuthEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.95),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.stepUpTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.stepUpSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 22),
            PassengerAuthGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AutofillGroup(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      readOnly: _emailSent && _isLoading,
                      decoration: passengerAuthFieldDecoration(
                        label: l10n.stepUpEmailLabel,
                        hint: l10n.stepUpEmailHint,
                      ),
                    ),
                  ),
                  if (_googleSignIn.isConfigured && !_emailSent) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _pickDeviceEmail,
                        icon: const Icon(Icons.account_circle_outlined, size: 20),
                        label: Text(l10n.stepUpUseGoogleEmail),
                      ),
                    ),
                  ],
                  if (!_emailSent) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: TexiScalePress(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _sendEmailCode,
                          icon: const Icon(Icons.mail_outline_rounded, size: 20),
                          label: Text(l10n.stepUpSendEmailCode),
                        ),
                      ),
                    ),
                  ],
                  if (_emailSent) ...[
                    const SizedBox(height: 16),
                    _EmailSentBanner(
                      message: l10n.stepUpEmailSentBanner(_maskEmail(email)),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _codeController,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            letterSpacing: 6,
                            fontWeight: FontWeight.w600,
                          ),
                      onChanged: (_) => setState(() {}),
                      decoration: passengerAuthFieldDecoration(
                        label: l10n.stepUpEmailCodeLabel,
                        hint: l10n.verifyCodeMaskHint,
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _sendEmailCode,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.stepUpResendCode),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_emailSent) ...[
              const SizedBox(height: 18),
              Text(
                l10n.stepUpSecurityLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 10),
              PassengerAuthCaptchaCard(
                turnstileKey: _turnstileKey,
                captchaContext: PassengerCaptchaContext.stepUp,
                onToken: (token) {
                  setState(() {
                    _captchaToken = token;
                    if (_errorMessage != null &&
                        (_errorMessage!.toLowerCase().contains('captcha') ||
                            _errorMessage == l10n.stepUpCaptchaRequired ||
                            _errorMessage == l10n.stepUpCaptchaLoadFailed)) {
                      _errorMessage = null;
                    }
                  });
                },
                onError: () {
                  setState(() {
                    _captchaToken = null;
                    _errorMessage = l10n.stepUpCaptchaLoadFailed;
                  });
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: TexiScalePress(
                  child: FilledButton(
                    onPressed: canConfirm ? _completeStepUp : null,
                    child: Text(l10n.stepUpConfirmButton),
                  ),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              PremiumStateView(
                icon: Icons.shield_outlined,
                title: l10n.loginReviewDataTitle,
                message: _errorMessage!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmailSentBanner extends StatelessWidget {
  const _EmailSentBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.primary.withValues(alpha: 0.95),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
