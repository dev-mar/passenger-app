import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/passenger_app_environment.dart';
import '../../core/constants/app_assets.dart';
import '../../core/compliance/passenger_login_legal_footer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/trip_error_localization.dart';
import '../../features/profile/widgets/passenger_profile_legal_section.dart';
import '../../gen_l10n/app_localizations.dart';
import 'login_controller.dart';
import 'utils/login_auth_rate_limit.dart';
import 'utils/login_attempts_limit_dialog.dart';
import 'utils/login_country_flag.dart';
import 'widgets/login_google_unified_panel.dart';
import 'widgets/login_method_choice_panel.dart';
import 'widgets/login_phone_unified_panel.dart';
import 'widgets/login_phone_verification_method_panel.dart';
import 'widgets/passenger_auth_shell.dart';
import 'widgets/passenger_turnstile_widget.dart';

enum LoginScreenStep {
  methodChoice,
  phoneUnified,
  googleUnified,
}

/// Login pasajero unificado: una pantalla por método (teléfono o Google).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.initialCountryCode,
    this.initialPhone,
    this.stepUpCompleted = false,
  });

  final String? initialCountryCode;
  final String? initialPhone;
  final bool stepUpCompleted;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryCodeController = TextEditingController(text: '+591');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _turnstileKey = GlobalKey<PassengerTurnstileWidgetState>();

  bool _isLoading = false;
  String? _errorMessage;
  LoginScreenStep _step = LoginScreenStep.methodChoice;
  String? _entryCaptchaToken;
  bool _captchaReady = false;

  LoginCountryDial get _country =>
      loginCountryFromDialCode(_countryCodeController.text);

  bool get _captchaGateRequired =>
      PassengerAppEnvironment.turnstileSiteKey.trim().isNotEmpty ||
      PassengerAppEnvironment.isDev;

  bool get _phoneValid => _phoneController.text.trim().length >= 6;

  bool get _showPhoneCaptcha => _phoneValid;

  bool get _showPhoneVerifyActions =>
      _phoneValid && (_captchaReady || !_captchaGateRequired);

  bool get _isUnifiedStep =>
      _step == LoginScreenStep.phoneUnified ||
      _step == LoginScreenStep.googleUnified;

  @override
  void initState() {
    super.initState();
    final cc = widget.initialCountryCode?.trim();
    final phone = widget.initialPhone?.trim();
    if (cc != null && cc.isNotEmpty) {
      _countryCodeController.text = cc;
    }
    if (phone != null && phone.isNotEmpty) {
      _phoneController.text = phone;
      _step = LoginScreenStep.phoneUnified;
    }
    _phoneController.addListener(_onPhoneChanged);
    if (widget.stepUpCompleted) {
      _step = LoginScreenStep.phoneUnified;
      if (!_captchaGateRequired) _captchaReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.stepUpCompleteContinueLogin),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _countryCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    if (!_phoneValid && (_captchaReady || _entryCaptchaToken != null)) {
      _resetCaptchaGate();
      _turnstileKey.currentState?.resetWidget();
    }
    setState(() {});
  }

  String get _fullPhone {
    final countryCode = _countryCodeController.text.trim();
    final phone = _phoneController.text.trim();
    return countryCode.replaceAll(RegExp(r'[^\d+]'), '') +
        phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  void _resetCaptchaGate() {
    _entryCaptchaToken = null;
    _captchaReady = false;
  }

  void _onMethodSelected(LoginEntryMethod method) {
    final l10n = AppLocalizations.of(context)!;
    if (method == LoginEntryMethod.google) {
      if (!AppConfig.googleAuthEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.loginGoogleNotConfiguredInApp),
          ),
        );
        return;
      }
      _resetCaptchaGate();
      setState(() {
        _errorMessage = null;
        _step = LoginScreenStep.googleUnified;
      });
      return;
    }
    _resetCaptchaGate();
    setState(() {
      _errorMessage = null;
      _step = LoginScreenStep.phoneUnified;
    });
  }

  void _onCaptchaToken(String token) {
    setState(() {
      _entryCaptchaToken = token;
      _captchaReady = true;
    });
  }

  void _onVerificationMethodSelected(PhoneVerificationMethod method) {
    if (!_phoneValid) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.loginPhoneRequired);
      return;
    }
    if (_captchaGateRequired && !_captchaReady) return;
    _startPhoneLoginAfterMethod(method);
  }

  Future<void> _startPhoneLoginAfterMethod(
    PhoneVerificationMethod method,
  ) async {
    if (_isLoading) return;
    final countryCode = _countryCodeController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final LoginNextStep nextStep;
    if (method == PhoneVerificationMethod.verificationCode) {
      nextStep = await ref
          .read(loginControllerProvider.notifier)
          .requestWhatsAppOutbound(
            countryCode: countryCode,
            phoneNumber: phone,
            fullPhone: _fullPhone,
            entryCaptchaToken: _entryCaptchaToken,
          );
    } else {
      nextStep = await ref.read(loginControllerProvider.notifier).login(
            countryCode: countryCode,
            phoneNumber: phone,
            fullPhone: _fullPhone,
            otpChannel: 'whatsapp_inbound',
            entryCaptchaToken: _entryCaptchaToken,
          );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _handleLoginNextStep(nextStep, countryCode: countryCode, phone: phone);
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    if (_captchaGateRequired && !_captchaReady) return;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    final next = await ref
        .read(loginControllerProvider.notifier)
        .loginWithGoogle(entryCaptchaToken: _entryCaptchaToken);
    if (!mounted) return;
    setState(() => _isLoading = false);
    _handleGoogleLoginNextStep(next);
  }

  Future<void> _continueWithManualEmail() async {
    if (_isLoading) return;
    if (_captchaGateRequired && !_captchaReady) return;
    final email = _emailController.text.trim();
    if (!email.contains('@') || email.length <= 5) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    final next = await ref
        .read(loginControllerProvider.notifier)
        .requestEmailLoginChallenge(
          email: email,
          entryCaptchaToken: _entryCaptchaToken,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    _handleEmailLoginNextStep(next, email: email);
  }

  void _handleGoogleLoginNextStep(LoginNextStep next) {
    if (next == LoginNextStep.tripRequest) {
      context.goNamed('trip_request');
      return;
    }
    if (next == LoginNextStep.attemptsLimitReached) {
      _resetToMethodChoice();
      showLoginAttemptsLimitDialog(
        context,
        navigateToLoginOnDismiss: false,
      );
      return;
    }
    if (next == LoginNextStep.profileRequired) {
      final loginState = ref.read(loginControllerProvider);
      context.goNamed(
        'profile_setup',
        queryParameters: {
          if (loginState.loginEmail != null &&
              loginState.loginEmail!.isNotEmpty)
            'email': loginState.loginEmail!,
        },
      );
      return;
    }
    if (next == LoginNextStep.error) {
      final loginState = ref.read(loginControllerProvider);
      showLoginAuthRateLimitIfNeeded(
        context,
        code: loginState.errorCode,
        navigateToLoginOnDismiss: false,
      ).then((blocked) {
        if (!mounted) return;
        if (blocked) {
          _resetToMethodChoice();
          return;
        }
        setState(() => _errorMessage = loginState.errorMessage);
      });
    }
  }

  void _handleEmailLoginNextStep(LoginNextStep next, {required String email}) {
    if (next == LoginNextStep.verifyEmailCode) {
      context.goNamed(
        'verify_code',
        queryParameters: {
          'email': email,
          'channel': 'email',
        },
      );
      return;
    }
    if (next == LoginNextStep.attemptsLimitReached) {
      _resetToMethodChoice();
      showLoginAttemptsLimitDialog(
        context,
        navigateToLoginOnDismiss: false,
      );
      return;
    }
    if (next == LoginNextStep.error) {
      final loginState = ref.read(loginControllerProvider);
      showLoginAuthRateLimitIfNeeded(
        context,
        code: loginState.errorCode,
        navigateToLoginOnDismiss: false,
      ).then((blocked) {
        if (!mounted) return;
        if (blocked) {
          _resetToMethodChoice();
          return;
        }
        setState(() => _errorMessage = loginState.errorMessage);
      });
    }
  }

  void _handleLoginNextStep(
    LoginNextStep nextStep, {
    required String countryCode,
    required String phone,
  }) async {
    switch (nextStep) {
      case LoginNextStep.tripRequest:
        context.goNamed('trip_request');
        break;
      case LoginNextStep.verifyCode:
        final loginState = ref.read(loginControllerProvider);
        context.goNamed(
          'verify_code',
          queryParameters: {
            'cc': countryCode,
            'phone': phone,
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
        break;
      case LoginNextStep.verifyEmailCode:
      case LoginNextStep.profileRequired:
        break;
      case LoginNextStep.stepUp:
      case LoginNextStep.attemptsLimitReached:
        _resetToMethodChoice();
        await showLoginAttemptsLimitDialog(
          context,
          navigateToLoginOnDismiss: false,
        );
        break;
      case LoginNextStep.authLockout:
        _resetToMethodChoice();
        final lockout = ref.read(loginControllerProvider).authLockout;
        if (lockout != null) {
          await navigateToPassengerAuthLockout(
            context,
            lockout: lockout,
            countryCode: countryCode,
            phoneNumber: phone,
          );
        } else {
          await showLoginAttemptsLimitDialog(
            context,
            navigateToLoginOnDismiss: false,
          );
        }
        break;
      case LoginNextStep.phoneRequired:
        setState(() => _step = LoginScreenStep.phoneUnified);
        break;
      case LoginNextStep.error:
        _applyLoginError(countryCode: countryCode, phone: phone);
        break;
    }
  }

  void _resetToMethodChoice() {
    _resetCaptchaGate();
    _errorMessage = null;
    _step = LoginScreenStep.methodChoice;
    _phoneController.clear();
    _emailController.clear();
  }

  Future<void> _applyLoginError({
    required String countryCode,
    required String phone,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final loginState = ref.read(loginControllerProvider);
    if (await showLoginAuthRateLimitIfNeeded(
      context,
      code: loginState.errorCode,
      responseData: loginState.authLockout?.toJson(),
      message: loginState.errorMessage,
      countryCode: countryCode,
      phoneNumber: phone,
      navigateToLoginOnDismiss: false,
    )) {
      _resetToMethodChoice();
      return;
    }
    if (loginState.errorCode == 'ACCOUNT_DELETION_PENDING') {
      await _showAccountDeletionPendingDialog(
        countryCode: countryCode,
        phoneNumber: phone,
        fullPhone: _fullPhone,
        accountDeletion: loginState.accountDeletion,
      );
      return;
    }
    setState(() {
      _step = LoginScreenStep.phoneUnified;
      final code = loginState.errorCode;
      const authReviewDataCodes = <String>{
        'PASS_AUTH_VALIDATION',
        'PASS_AUTH_RATE_LIMIT',
        'PASS_AUTH_OTP_INVALID',
        'PASS_AUTH_NOT_VERIFIED',
        'PASS_AUTH_INVALID',
        'PASS_AUTH_FORBIDDEN',
        'PASS_AUTH_DB',
      };
      _errorMessage = (code != null && code.startsWith('RBAC_'))
          ? localizedTripApiError(l10n, code,
              fallbackMessage: loginState.errorMessage)
          : (code != null && authReviewDataCodes.contains(code))
              ? l10n.loginErrorInvalidCredentials
              : switch (code) {
                  'PASS_AUTH_OTP_RATE_LIMIT' => l10n.loginErrorOtpRateLimit,
                  'NETWORK_TIMEOUT' => l10n.verifyCodeErrorNetwork,
                  'NETWORK_CONNECTION' => l10n.verifyCodeErrorConnection,
                  'NETWORK_REQUEST_FAILED' => l10n.verifyCodeErrorNetwork,
                  'BACKEND_UNAVAILABLE' => l10n.loginErrorBackendUnavailable,
                  'CLIENT_INVALID_RESPONSE' =>
                    l10n.verifyCodeErrorIncompleteResponse,
                  'CLIENT_EMPTY_DATA' =>
                    l10n.verifyCodeErrorIncompleteResponse,
                  'CLIENT_TOKEN_MISSING' => l10n.verifyCodeErrorTokenMissing,
                  'CLIENT_UNEXPECTED' => l10n.verifyCodeErrorUnexpected,
                  'PASS_AUTH_PHONE_REGISTERED_AS_DRIVER' =>
                    l10n.loginErrorPhoneRegisteredAsDriver,
                  'PASS_AUTH_PHONE_OTHER_ACCOUNT_TYPE' =>
                    l10n.loginErrorPhoneOtherAccountType,
                  'PASS_AUTH_DUPLICATE_USER' =>
                    l10n.loginErrorPhoneDuplicatePassenger,
                  'PASS_AUTH_OTP_STORE' =>
                    l10n.loginErrorVerificationServiceUnavailable,
                  'PASS_AUTH_WA_NOT_CONFIGURED' =>
                    l10n.loginErrorWhatsAppVerificationUnavailable,
                  'PASS_AUTH_WA_OUTBOUND_RATE_LIMIT' =>
                    l10n.loginErrorWaOutboundRateLimit,
                  'PASS_AUTH_WA_OUTBOUND_NOT_CONFIGURED' =>
                    l10n.loginErrorWhatsAppVerificationUnavailable,
                  'PASS_AUTH_WA_OUTBOUND_SEND_FAILED' =>
                    l10n.verifyCodeWaOutboundFailed,
                  'SESSION_SUPERSEDED' => l10n.loginErrorSessionSuperseded,
                  'TRIP_OPERATIONAL_LOCK' =>
                    l10n.loginErrorTripOperationalLock,
                  _ =>
                    loginState.errorMessage ??
                        l10n.loginErrorInvalidCredentials,
                };
    });
  }

  void _handleBack() {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      _resetCaptchaGate();
      _step = LoginScreenStep.methodChoice;
    });
  }

  Future<void> _showAccountDeletionPendingDialog({
    required String countryCode,
    required String phoneNumber,
    required String fullPhone,
    Map<String, dynamic>? accountDeletion,
  }) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final effectiveRaw = accountDeletion?['deletion_effective_at']?.toString();
    final effectiveDate = formatPassengerAccountDeletionDate(
          context,
          effectiveRaw,
        ) ??
        l10n.passengerLoginAccountDeletionPendingDateFallback;

    final recover = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(Icons.schedule_send_outlined, color: AppColors.primary),
          title: Text(l10n.passengerLoginAccountDeletionPendingTitle),
          content: Text(
            l10n.passengerLoginAccountDeletionPendingBody(effectiveDate),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.passengerLoginAccountDeletionDismiss),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.passengerLoginAccountDeletionRecover),
            ),
          ],
        );
      },
    );

    if (recover != true || !mounted) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final recovered = await ref
        .read(loginControllerProvider.notifier)
        .recoverAccountFromPendingDeletion(
          countryCode: countryCode,
          phoneNumber: phoneNumber,
          fullPhone: fullPhone,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (recovered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passengerLoginAccountDeletionRecoverSuccess),
        ),
      );
      context.goNamed('trip_request');
      return;
    }

    final loginState = ref.read(loginControllerProvider);
    setState(() {
      _errorMessage =
          loginState.errorMessage ?? l10n.loginErrorInvalidCredentials;
    });
  }

  String? _loadingMessage(AppLocalizations l10n) {
    if (!_isLoading) return null;
    return _step == LoginScreenStep.phoneUnified
        ? l10n.loginVerifyMethodLoadingWa
        : l10n.commonLoading;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginState = ref.watch(loginControllerProvider);
    final googleEnabled = PassengerAppEnvironment.multichannelAuthEnabled &&
        AppConfig.googleAuthEnabled;
    final authChannelsEnabled = PassengerAppEnvironment.multichannelAuthEnabled;
    final showBack = _step != LoginScreenStep.methodChoice;

    return PassengerAuthShell(
      loading: _isLoading,
      loadingMessage: _loadingMessage(l10n),
      maxContentWidth: _isUnifiedStep ? 560 : 420,
      horizontalPadding: _isUnifiedStep ? 12 : 24,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _handleBack,
                  tooltip: l10n.loginBackToMethods,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.textPrimary,
                ),
              ),
            )
          : null,
      child: PassengerAuthEntrance(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Image.asset(
                  AppAssets.logoAmaBlanco,
                  width: showBack ? 72 : 88,
                  height: showBack ? 72 : 88,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      SizedBox(height: showBack ? 72 : 88),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: _buildStep(
                  l10n: l10n,
                  loginState: loginState,
                  googleEnabled: googleEnabled,
                  outboundEnabled: authChannelsEnabled,
                ),
              ),
              const SizedBox(height: 18),
              if (_step == LoginScreenStep.methodChoice)
                PassengerLoginLegalFooter(
                  tone: PassengerLegalNoticeTone.methodChoice,
                  textColor: AppColors.textSecondary.withValues(alpha: 0.85),
                )
              else if (_isUnifiedStep)
                PassengerLoginLegalFooter(
                  tone: PassengerLegalNoticeTone.authContinue,
                  textColor: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required AppLocalizations l10n,
    required LoginState loginState,
    required bool googleEnabled,
    required bool outboundEnabled,
  }) {
    switch (_step) {
      case LoginScreenStep.methodChoice:
        return LoginMethodChoicePanel(
          key: const ValueKey('method_choice'),
          onMethodSelected: _onMethodSelected,
          googleAuthEnabled: googleEnabled,
        );
      case LoginScreenStep.phoneUnified:
        return LoginPhoneUnifiedPanel(
          key: const ValueKey('phone_unified'),
          country: _country,
          phoneController: _phoneController,
          turnstileKey: _turnstileKey,
          phoneValid: _phoneValid,
          showCaptcha: _showPhoneCaptcha,
          captchaReady: _captchaReady,
          showVerifyActions: _showPhoneVerifyActions,
          onCaptchaToken: _onCaptchaToken,
          onMethodSelected: _onVerificationMethodSelected,
          isLoading: _isLoading,
          outboundEnabled: outboundEnabled,
          errorMessage: _errorMessage,
          linkedGoogleEmail: loginState.googleEmail,
        );
      case LoginScreenStep.googleUnified:
        return LoginGoogleUnifiedPanel(
          key: const ValueKey('google_unified'),
          emailController: _emailController,
          turnstileKey: _turnstileKey,
          captchaReady: _captchaReady,
          onCaptchaToken: _onCaptchaToken,
          onContinueManualEmail: _continueWithManualEmail,
          onSignInWithGoogle: _signInWithGoogle,
          googleAuthEnabled: googleEnabled,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
        );
    }
  }
}
