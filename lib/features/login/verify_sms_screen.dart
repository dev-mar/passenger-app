import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/config/passenger_app_environment.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../core/network/passenger_api_client.dart';
import '../../core/network/passenger_api_providers.dart';
import '../../core/network/passenger_client_meta.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';
import 'login_controller.dart';
import 'passenger_firebase_auth_errors.dart';
import 'passenger_sms_firebase_auth.dart';
import 'services/passenger_google_sign_in_service.dart';
import 'utils/login_attempts_limit_dialog.dart';
import 'utils/login_auth_rate_limit.dart';
import 'widgets/login_google_brand_icon.dart';
import 'widgets/passenger_auth_shell.dart';

enum _VerifySmsPhase { googleGate, sendingSms, codeEntry }

/// Flujo SMS premium: Google del dispositivo → Firebase Phone → código.
class VerifySmsScreen extends ConsumerStatefulWidget {
  const VerifySmsScreen({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
  });

  final String countryCode;
  final String phoneNumber;

  @override
  ConsumerState<VerifySmsScreen> createState() => _VerifySmsScreenState();
}

class _VerifySmsScreenState extends ConsumerState<VerifySmsScreen> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  final _googleSignIn = PassengerGoogleSignInService();

  _VerifySmsPhase _phase = _VerifySmsPhase.googleGate;
  bool _isLoading = false;
  String? _errorMessage;
  PassengerFirebaseAuthErrorKind? _errorKind;
  String? _linkedGoogleEmail;
  bool _smsWaiting = false;

  String get _fullPhoneE164 {
    final phoneDigits = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final cc = widget.countryCode.startsWith('+')
        ? widget.countryCode
        : '+${widget.countryCode}';
    return '$cc$phoneDigits';
  }

  String get _maskedPhone {
    return '${widget.countryCode} ${widget.phoneNumber.replaceAll(RegExp(r".(?=.{2})"), "•")}';
  }

  PassengerApiClient get _api => ref.read(passengerApiClientProvider);

  bool _isFirebaseSetupError(AppLocalizations l10n) {
    return _resolveErrorPresentation(l10n).preferBackToLogin;
  }

  void _setError({
    required String message,
    PassengerFirebaseAuthErrorKind? kind,
  }) {
    _errorMessage = message;
    _errorKind = kind;
  }

  void _clearError() {
    _errorMessage = null;
    _errorKind = null;
  }

  PassengerSmsAuthErrorPresentation _resolveErrorPresentation(
    AppLocalizations l10n,
  ) {
    final kind = _errorKind;
    if (kind != null) {
      return passengerSmsAuthErrorPresentation(
        l10n,
        kind: kind,
        rawMessage: _errorMessage,
      );
    }
    return passengerSmsGenericErrorPresentation(
      l10n,
      message: _errorMessage ?? l10n.verifyCodeSmsFailed,
    );
  }

  void _navigateBack(AppLocalizations l10n) {
    if (_isLoading) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed('login');
  }

  bool get _googleConfigured =>
      PassengerAppEnvironment.multichannelAuthEnabled &&
      AppConfig.googleAuthEnabled &&
      _googleSignIn.isConfigured;

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    if (_isLoading || !_googleConfigured) return;
    final l10n = AppLocalizations.of(context)!;
    TexiUiFeedback.softImpact();
    setState(() {
      _isLoading = true;
      _clearError();
    });

    final creds = await _googleSignIn.signInAndGetCredentials();
    if (!mounted) return;
    if (creds == null) {
      setState(() {
        _isLoading = false;
        _setError(
          message: l10n.verifySmsGoogleCancelled,
          kind: PassengerFirebaseAuthErrorKind.googleCancelled,
        );
      });
      return;
    }

    setState(() {
      _linkedGoogleEmail = creds.email;
      _phase = _VerifySmsPhase.sendingSms;
    });

    final next = await ref.read(loginControllerProvider.notifier).requestSmsFirebase(
          countryCode: widget.countryCode,
          phoneNumber: widget.phoneNumber,
          fullPhone: _fullPhoneE164,
          googleIdToken: creds.idToken,
        );

    if (!mounted) return;

    if (next == LoginNextStep.attemptsLimitReached) {
      setState(() => _isLoading = false);
      await showLoginAttemptsLimitDialog(context);
      return;
    }

    if (next == LoginNextStep.authLockout) {
      setState(() => _isLoading = false);
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

    if (next != LoginNextStep.verifyCode) {
      final loginState = ref.read(loginControllerProvider);
      setState(() {
        _isLoading = false;
        _phase = _VerifySmsPhase.googleGate;
        _setError(
          message: localizedTripApiError(
            l10n,
            loginState.errorCode,
            fallbackMessage: loginState.errorMessage ?? l10n.verifyCodeSmsFailed,
          ),
        );
      });
      return;
    }

    final loginState = ref.read(loginControllerProvider);
    _linkedGoogleEmail ??= loginState.googleEmail;

    await _startSmsFirebasePhoneFlow();
  }

  Future<void> _startSmsFirebasePhoneFlow() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _clearError();
      _phase = _VerifySmsPhase.sendingSms;
    });

    await PassengerSmsFirebaseAuth.startPhoneVerification(
      phoneE164: _fullPhoneE164,
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _smsWaiting = true;
          _phase = _VerifySmsPhase.codeEntry;
        });
        _codeFocusNode.requestFocus();
      },
      onFailed: (code, message) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _smsWaiting = false;
          _phase = _VerifySmsPhase.googleGate;
          final kind = classifyPassengerFirebaseAuthError(
            code: code,
            rawMessage: message,
          );
          _setError(
            message: localizedPassengerFirebaseAuthError(
              l10n,
              code: code,
              rawMessage: message,
            ),
            kind: kind,
          );
        });
      },
      onAutoVerified: (idToken) async {
        if (!mounted) return;
        await _completeWithFirebaseIdToken(idToken);
      },
    );
  }

  Future<void> _verifyCode() async {
    _codeFocusNode.unfocus();
    TexiUiFeedback.softImpact();
    setState(() {
      _isLoading = true;
      _clearError();
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

    try {
      final idToken = await PassengerSmsFirebaseAuth.confirmSmsCode(codeText);
      if (idToken == null || idToken.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.verifyCodeErrorInvalidCodeInput;
        });
        return;
      }
      await _completeWithFirebaseIdToken(idToken);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.verifyCodeErrorValidateCode;
      });
    }
  }

  Future<void> _completeWithFirebaseIdToken(String idToken) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _clearError();
    });
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
          'firebase_id_token': idToken,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        final map = body is Map<String, dynamic> ? body : null;
        final code = map?['code']?.toString();
        if (!mounted) return;
        if (await showLoginAuthRateLimitIfNeeded(
          context,
          code: code,
          responseData: map,
          countryCode: widget.countryCode,
          phoneNumber: widget.phoneNumber,
        )) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          context.goNamed('login');
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = localizedTripApiError(
            l10n,
            code,
            fallbackMessage:
                map?['message']?.toString() ?? l10n.verifyCodeErrorValidateCode,
          );
        });
        return;
      }
      final rawData = body['data'];
      final reuseDriver = rawData is Map &&
          (rawData['reuse_driver_profile'] == true ||
              rawData['reuse_driver_profile'] == 'true');
      if (reuseDriver) {
        await _completePassengerFromDriver();
        return;
      }
      setState(() => _isLoading = false);
      await AuthService.persistLoginPhoneE164(_fullPhoneE164);
      if (!mounted) return;
      context.goNamed(
        'profile_setup',
        queryParameters: {
          'cc': widget.countryCode,
          'phone': widget.phoneNumber,
        },
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final code = TexiBackendError.codeFromResponse(e.response?.data);
      setState(() {
        _isLoading = false;
        _errorMessage = localizedTripApiError(
          l10n,
          code,
          fallbackMessage: TexiBackendError.messageFromResponse(e.response?.data) ??
              l10n.verifyCodeErrorNetwork,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.verifyCodeErrorUnexpected;
      });
    }
  }

  Future<void> _completePassengerFromDriver() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final clientMeta = await passengerAuthClientMeta();
      final response = await _api.postPublic<Map<String, dynamic>>(
        path: AppConfig.authUsersPath,
        data: <String, dynamic>{
          ...clientMeta,
          'phone_number': _fullPhoneE164,
          'alias_name': '',
          'profile_picture': null,
          'reuse_driver_profile': true,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = body is Map<String, dynamic>
              ? body['message']?.toString() ?? l10n.verifyCodeErrorActivateAccount
              : l10n.verifyCodeErrorActivateAccount;
        });
        return;
      }
      final data = body['data'];
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
      await AuthService.persistLoginPhoneE164(_fullPhoneE164);
      final display = data['display_name']?.toString().trim();
      if (display != null && display.isNotEmpty) {
        await AuthService.savePassengerDisplayName(display);
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.goNamed('trip_request');
    } on DioException catch (e) {
      if (!mounted) return;
      final code = TexiBackendError.codeFromResponse(e.response?.data);
      setState(() {
        _isLoading = false;
        _errorMessage = localizedTripApiError(
          l10n,
          code,
          fallbackMessage: TexiBackendError.messageFromResponse(e.response?.data) ??
              l10n.verifyCodeErrorNetwork,
        );
      });
    }
  }

  InputDecoration _premiumFieldDecoration({
    required String label,
    required String hint,
  }) {
    final muted = AppColors.textSecondary.withValues(alpha: 0.55);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: false,
      border: InputBorder.none,
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: muted, width: 0.8),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.textPrimary.withValues(alpha: 0.85),
          width: 1.2,
        ),
      ),
      labelStyle: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.75),
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: muted, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  Widget _buildGoogleGate(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.verifySmsGoogleTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.verifySmsGoogleSubtitle(_maskedPhone),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.92),
            height: 1.45,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 36),
        if (!_googleConfigured) ...[
          Text(
            l10n.loginGoogleNotConfiguredInApp,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ] else ...[
          TexiScalePress(
            child: Material(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: _isLoading ? null : _continueWithGoogle,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LoginGoogleBrandIcon(size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.verifySmsGoogleButton,
                        style: const TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          l10n.verifySmsGoogleHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.78),
            height: 1.4,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeEntry(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.verifyCodeSmsTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.96),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.verifyCodeSmsSubtitle(_maskedPhone),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            height: 1.4,
            fontSize: 13.5,
          ),
        ),
        if (_linkedGoogleEmail != null && _linkedGoogleEmail!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            l10n.verifySmsLinkedAccount(_linkedGoogleEmail!),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.72),
              fontSize: 12.5,
            ),
          ),
        ],
        if (_smsWaiting) ...[
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  l10n.verifyCodeSmsWaiting,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 28),
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
              fontSize: 28,
              letterSpacing: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: _premiumFieldDecoration(
              label: l10n.verifyCodeFieldLabel,
              hint: l10n.verifyCodeMaskHint,
            ).copyWith(counterText: ''),
            onSubmitted: (_) => _verifyCode(),
          ),
        ),
        const SizedBox(height: 28),
        TexiScalePress(
          child: FilledButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: FilledButton.styleFrom(
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.textPrimary.withValues(alpha: 0.94),
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
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
        const SizedBox(height: 18),
        Text(
          l10n.verifyCodeRetryHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.78),
            height: 1.4,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final showCode = _phase == _VerifySmsPhase.codeEntry ||
        _phase == _VerifySmsPhase.sendingSms && _smsWaiting;

    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isLoading) return;
        _navigateBack(l10n);
      },
      child: PassengerAuthShell(
        loading: _isLoading,
        loadingMessage: l10n.commonLoading,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: _isLoading ? null : () => _navigateBack(l10n),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        ),
        child: PassengerAuthEntrance(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!showCode) _buildGoogleGate(l10n, theme) else _buildCodeEntry(l10n, theme),
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    final presentation = _resolveErrorPresentation(l10n);
                    return PremiumStateView(
                      icon: presentation.icon,
                      title: presentation.title,
                      message: presentation.message,
                      actionLabel: presentation.preferBackToLogin
                          ? l10n.verifySmsBackToLogin
                          : l10n.homeRetry,
                      onAction: () {
                        if (presentation.preferBackToLogin) {
                          context.goNamed('login');
                          return;
                        }
                        setState(_clearError);
                        if (_phase == _VerifySmsPhase.googleGate) {
                          _continueWithGoogle();
                        } else {
                          _verifyCode();
                        }
                      },
                    );
                  },
                ),
                if (!_isFirebaseSetupError(l10n)) ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final presentation = _resolveErrorPresentation(l10n);
                      if (!presentation.suggestWhatsAppAlternative) {
                        return TextButton(
                          onPressed: _isLoading ? null : () => context.goNamed('login'),
                          child: Text(l10n.verifySmsBackToLogin),
                        );
                      }
                      return Column(
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => context.goNamed('login'),
                            child: Text(l10n.verifySmsTryWhatsApp),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : () => context.goNamed('login'),
                            child: Text(l10n.verifySmsBackToLogin),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
