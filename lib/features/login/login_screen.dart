import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../core/l10n/trip_error_localization.dart';
import 'login_controller.dart';

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
        // Ir a pantalla de verificación de código, pasando el número ingresado.
        context.goNamed(
          'verify_code',
          queryParameters: {
            'cc': countryCode,
            'phone': phone,
          },
        );
        break;
      case LoginNextStep.error:
        setState(() {
          final loginState = ref.read(loginControllerProvider);
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
                  'CLIENT_INVALID_RESPONSE' => l10n.verifyCodeErrorIncompleteResponse,
                  'CLIENT_EMPTY_DATA' => l10n.verifyCodeErrorIncompleteResponse,
                  'CLIENT_TOKEN_MISSING' => l10n.verifyCodeErrorTokenMissing,
                  'CLIENT_UNEXPECTED' => l10n.verifyCodeErrorUnexpected,
                  'PASS_AUTH_PHONE_REGISTERED_AS_DRIVER' =>
                    l10n.loginErrorPhoneRegisteredAsDriver,
                  'PASS_AUTH_PHONE_OTHER_ACCOUNT_TYPE' =>
                    l10n.loginErrorPhoneOtherAccountType,
                  'PASS_AUTH_DUPLICATE_USER' =>
                    l10n.loginErrorPhoneDuplicatePassenger,
                  _ =>
                    loginState.errorMessage ??
                        l10n.loginErrorInvalidCredentials,
                };
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo: imagen con degradado para legibilidad del formulario
          Image.asset(
            AppAssets.loginBackground,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black,
                ],
              ),
            ),
          ),
          SafeArea(
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        AppAssets.logoAmaBlanco,
                        height: 56,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(height: 56),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context)!.loginWelcome,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.loginSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              controller: _countryCodeController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.loginCode,
                                hintText: AppLocalizations.of(context)!.loginCountryCodeHint,
                                fillColor: AppColors.surface,
                              ),
                              keyboardType: TextInputType.phone,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.loginPhone,
                                hintText: AppLocalizations.of(context)!.loginPhoneHint,
                                fillColor: AppColors.surface,
                              ),
                              keyboardType: TextInputType.phone,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        PremiumStateView(
                          icon: Icons.info_outline_rounded,
                          title: AppLocalizations.of(context)!.loginReviewDataTitle,
                          message: _errorMessage!,
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: TexiScalePress(
                          child: FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : Semantics(
                                    button: true,
                                    label: AppLocalizations.of(context)!.loginContinueA11y,
                                    child: Text(AppLocalizations.of(context)!.loginContinue),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.commonLoading,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
