import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_assets.dart';
import '../../core/config/passenger_app_environment.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/compliance/passenger_login_legal_footer.dart';
import '../../features/profile/widgets/passenger_profile_legal_section.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../core/l10n/trip_error_localization.dart';
import 'login_controller.dart';
import 'utils/login_country_flag.dart';
import 'widgets/login_captcha_gate_panel.dart';
import 'widgets/login_method_choice_panel.dart';
import 'widgets/login_phone_entry_panel.dart';
import 'widgets/login_phone_verification_method_panel.dart';
import 'widgets/passenger_auth_shell.dart';
import 'widgets/passenger_turnstile_widget.dart';

enum LoginWizardStep {
  methodChoice,
  phoneEntry,
  phoneCaptcha,
  phoneVerificationMethod,
  googleCaptcha,
}

/// Pantalla Login pasajero: método → teléfono → captcha (1ª vez) → método WA → auth.
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
  final _turnstileKey = GlobalKey<PassengerTurnstileWidgetState>();

  bool _isLoading = false;
  String? _errorMessage;
  LoginWizardStep _wizardStep = LoginWizardStep.methodChoice;
  bool _phoneCaptchaPassed = false;
  bool _googleCaptchaPassed = false;
  String? _entryCaptchaToken;
  bool _captchaReady = false;

  LoginCountryDial get _country =>
      loginCountryFromDialCode(_countryCodeController.text);

  bool get _captchaGateRequired =>
      PassengerAppEnvironment.turnstileSiteKey.trim().isNotEmpty ||
      PassengerAppEnvironment.isDev;

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
      _wizardStep = LoginWizardStep.phoneEntry;
    }
    if (widget.stepUpCompleted) {
      _phoneCaptchaPassed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.stepUpCompleteContinueLogin),
          ),
        );
        _startPhoneLoginAfterMethod(PhoneVerificationMethod.whatsAppInbound);
      });
    }
  }

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final countryCode = _countryCodeController.text.trim();
    final phone = _phoneController.text.trim();
    return countryCode.replaceAll(RegExp(r'[^\d+]'), '') +
        phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  String _maskedPhone() {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length <= 4) return digits;
    final tail = digits.substring(digits.length - 4);
    return '••• ${tail.substring(0, 2)} ${tail.substring(2)}';
  }

  void _resetCaptchaGate() {
    _entryCaptchaToken = null;
    _captchaReady = false;
  }

  void _onMethodSelected(LoginEntryMethod method) {
    final l10n = AppLocalizations.of(context)!;
    if (method == LoginEntryMethod.google) {
      if (!ref.read(loginControllerProvider.notifier).isGoogleAuthConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.loginGoogleComingSoon),
          ),
        );
        return;
      }
      if (_googleCaptchaPassed) {
        _submitGoogleLogin();
        return;
      }
      _resetCaptchaGate();
      setState(() {
        _errorMessage = null;
        _wizardStep = LoginWizardStep.googleCaptcha;
      });
      return;
    }
    setState(() {
      _wizardStep = LoginWizardStep.phoneEntry;
      _errorMessage = null;
    });
  }

  void _onPhoneEntryContinue() {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = l10n.loginPhoneRequired);
      return;
    }
    setState(() => _errorMessage = null);
    TexiUiFeedback.softImpact();
    if (_phoneCaptchaPassed || !_captchaGateRequired) {
      setState(() => _wizardStep = LoginWizardStep.phoneVerificationMethod);
      return;
    }
    _resetCaptchaGate();
    setState(() => _wizardStep = LoginWizardStep.phoneCaptcha);
  }

  void _onPhoneCaptchaContinue() {
    if (!_captchaReady && _captchaGateRequired) return;
    setState(() {
      _phoneCaptchaPassed = true;
      _wizardStep = LoginWizardStep.phoneVerificationMethod;
    });
  }

  void _onCaptchaToken(String token) {
    setState(() {
      _entryCaptchaToken = token;
      _captchaReady = true;
    });
  }

  void _onVerificationMethodSelected(PhoneVerificationMethod method) {
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

  Future<void> _submitGoogleLogin() async {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    final next = await ref
        .read(loginControllerProvider.notifier)
        .loginWithGoogle(entryCaptchaToken: _entryCaptchaToken);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (next == LoginNextStep.tripRequest) {
      context.goNamed('trip_request');
      return;
    }
    if (next == LoginNextStep.phoneRequired) {
      setState(() {
        _wizardStep = LoginWizardStep.phoneEntry;
        _errorMessage = null;
      });
      return;
    }
    if (next == LoginNextStep.error) {
      final msg = ref.read(loginControllerProvider).errorMessage;
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  void _onGoogleCaptchaContinue() {
    if (!_captchaReady && _captchaGateRequired) return;
    setState(() => _googleCaptchaPassed = true);
    _submitGoogleLogin();
  }

  void _handleLoginNextStep(
    LoginNextStep nextStep, {
    required String countryCode,
    required String phone,
  }) {
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
      case LoginNextStep.stepUp:
        context.goNamed(
          'auth_step_up',
          queryParameters: {
            'cc': countryCode,
            'phone': phone,
          },
        );
        break;
      case LoginNextStep.phoneRequired:
        setState(() => _wizardStep = LoginWizardStep.phoneEntry);
        break;
      case LoginNextStep.error:
        _applyLoginError(countryCode: countryCode, phone: phone);
        break;
    }
  }

  Future<void> _applyLoginError({
    required String countryCode,
    required String phone,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final loginState = ref.read(loginControllerProvider);
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
      _wizardStep = LoginWizardStep.phoneVerificationMethod;
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
      switch (_wizardStep) {
        case LoginWizardStep.methodChoice:
          break;
        case LoginWizardStep.phoneEntry:
          _wizardStep = LoginWizardStep.methodChoice;
          _phoneCaptchaPassed = false;
          _resetCaptchaGate();
          break;
        case LoginWizardStep.phoneCaptcha:
          _wizardStep = LoginWizardStep.phoneEntry;
          break;
        case LoginWizardStep.phoneVerificationMethod:
          _wizardStep = LoginWizardStep.phoneEntry;
          break;
        case LoginWizardStep.googleCaptcha:
          _resetCaptchaGate();
          _wizardStep = LoginWizardStep.methodChoice;
          break;
      }
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

  String? _loadingMessageForStep(AppLocalizations l10n) {
    if (!_isLoading) return null;
    return switch (_wizardStep) {
      LoginWizardStep.phoneVerificationMethod => l10n.loginVerifyMethodLoadingWa,
      LoginWizardStep.googleCaptcha => l10n.commonLoading,
      _ => l10n.commonLoading,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginState = ref.watch(loginControllerProvider);
    final googleEnabled =
        ref.read(loginControllerProvider.notifier).isGoogleAuthConfigured;
    final showBack = _wizardStep != LoginWizardStep.methodChoice;
    final compactLogo = _wizardStep != LoginWizardStep.methodChoice;

    return PassengerAuthShell(
      loading: _isLoading,
      loadingMessage: _loadingMessageForStep(l10n),
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
                  width: compactLogo ? 72 : 88,
                  height: compactLogo ? 72 : 88,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      SizedBox(height: compactLogo ? 72 : 88),
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
                child: _buildWizardStep(
                  l10n: l10n,
                  loginState: loginState,
                  googleEnabled: googleEnabled,
                ),
              ),
              const SizedBox(height: 18),
              PassengerLoginLegalFooter(
                textColor: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWizardStep({
    required AppLocalizations l10n,
    required LoginState loginState,
    required bool googleEnabled,
  }) {
    switch (_wizardStep) {
      case LoginWizardStep.methodChoice:
        return LoginMethodChoicePanel(
          key: const ValueKey('method_step'),
          onMethodSelected: _onMethodSelected,
          googleAuthEnabled: googleEnabled,
        );
      case LoginWizardStep.phoneEntry:
        return LoginPhoneEntryPanel(
          key: const ValueKey('phone_step'),
          country: _country,
          phoneController: _phoneController,
          errorMessage: _errorMessage,
          isLoading: _isLoading,
          onSubmit: _onPhoneEntryContinue,
          linkedGoogleEmail: loginState.googleEmail,
        );
      case LoginWizardStep.phoneCaptcha:
        return LoginCaptchaGatePanel(
          key: const ValueKey('phone_captcha'),
          turnstileKey: _turnstileKey,
          captchaReady: _captchaReady,
          onCaptchaToken: _onCaptchaToken,
          onContinue: _onPhoneCaptchaContinue,
          isLoading: _isLoading,
        );
      case LoginWizardStep.phoneVerificationMethod:
        return Column(
          key: const ValueKey('verify_method'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LoginPhoneVerificationMethodPanel(
              phoneMasked: _maskedPhone(),
              outboundEnabled: true,
              onMethodSelected: _onVerificationMethodSelected,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              PremiumStateView(
                icon: Icons.info_outline_rounded,
                title: l10n.loginReviewDataTitle,
                message: _errorMessage!,
              ),
            ],
          ],
        );
      case LoginWizardStep.googleCaptcha:
        return LoginCaptchaGatePanel(
          key: const ValueKey('google_captcha'),
          turnstileKey: _turnstileKey,
          captchaReady: _captchaReady,
          forGoogle: true,
          onCaptchaToken: _onCaptchaToken,
          onContinue: _onGoogleCaptchaContinue,
          isLoading: _isLoading,
        );
    }
  }
}
