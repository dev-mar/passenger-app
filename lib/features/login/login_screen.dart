import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../core/compliance/passenger_login_legal_footer.dart';
import '../../features/profile/widgets/passenger_profile_legal_section.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../core/l10n/trip_error_localization.dart';
import 'login_controller.dart';
import 'widgets/passenger_auth_shell.dart';

/// Pantalla Login: teléfono (código Bolivia) y botón para obtener JWT.
/// Contrato de API según PASAJERO-APP-SETUP.md § 4.1.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryCodeController = TextEditingController(text: '+591');
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    TexiUiFeedback.softImpact();

    final phone = _phoneController.text.trim();
    final countryCode = _countryCodeController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = l10n.loginPhoneRequired;
        _isLoading = false;
      });
      return;
    }

    final fullPhone = countryCode.replaceAll(RegExp(r'[^\d+]'), '') +
        phone.replaceAll(RegExp(r'[^\d]'), '');

    final nextStep = await ref.read(loginControllerProvider.notifier).login(
          countryCode: countryCode,
          phoneNumber: phone,
          fullPhone: fullPhone,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

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
      case LoginNextStep.error:
        final loginState = ref.read(loginControllerProvider);
        if (loginState.errorCode == 'ACCOUNT_DELETION_PENDING') {
          await _showAccountDeletionPendingDialog(
            countryCode: countryCode,
            phoneNumber: phone,
            fullPhone: fullPhone,
            accountDeletion: loginState.accountDeletion,
          );
          break;
        }
        setState(() {
          final code = loginState.errorCode;
          const authReviewDataCodes = <String>{
            'PASS_AUTH_VALIDATION',
            'PASS_AUTH_RATE_LIMIT',
            'PASS_AUTH_OTP_RATE_LIMIT',
            'PASS_AUTH_OTP_INVALID',
            'PASS_AUTH_NOT_VERIFIED',
            'PASS_AUTH_INVALID',
            'PASS_AUTH_FORBIDDEN',
            'PASS_AUTH_DB'
          };
          _errorMessage = (code != null && code.startsWith('RBAC_'))
              ? localizedTripApiError(l10n, code,
                  fallbackMessage: loginState.errorMessage)
              : (code != null && authReviewDataCodes.contains(code))
                  ? l10n.loginErrorInvalidCredentials
                  : switch (code) {
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
                      'SESSION_SUPERSEDED' => l10n.loginErrorSessionSuperseded,
                      'TRIP_OPERATIONAL_LOCK' =>
                        l10n.loginErrorTripOperationalLock,
                      _ =>
                        loginState.errorMessage ??
                            l10n.loginErrorInvalidCredentials,
                    };
        });
        break;
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PassengerAuthShell(
      loading: _isLoading,
      loadingMessage: l10n.commonLoading,
      child: PassengerAuthEntrance(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Image.asset(
                  AppAssets.logoAmaBlanco,
                  width: 88,
                  height: 88,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 88),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.loginWelcome,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                      height: 1.4,
                      fontSize: 13.5,
                    ),
              ),
              const SizedBox(height: 22),
              PassengerAuthGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 88,
                          child: TextFormField(
                            controller: _countryCodeController,
                            decoration: passengerAuthFieldDecoration(
                              label: l10n.loginCode,
                              hint: l10n.loginCountryCodeHint,
                            ),
                            keyboardType: TextInputType.phone,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: passengerAuthFieldDecoration(
                              label: l10n.loginPhone,
                              hint: l10n.loginPhoneHint,
                            ),
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.xxx),
                      PremiumStateView(
                        icon: Icons.info_outline_rounded,
                        title: l10n.loginReviewDataTitle,
                        message: _errorMessage!,
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: TexiScalePress(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.lg),
                            ),
                          ),
                          child: Semantics(
                            button: true,
                            label: l10n.loginContinueA11y,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.loginContinue,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
}
