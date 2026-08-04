import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/passenger_app_environment.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';
import 'login_controller.dart';
import 'utils/login_country_flag.dart';
import 'widgets/login_auth_action_row.dart';
import 'widgets/login_phone_entry_panel.dart';
import 'widgets/login_phone_verification_method_panel.dart';
import 'widgets/login_whatsapp_brand_icon.dart';
import 'widgets/passenger_auth_shell.dart';

/// Vincular teléfono verificado a sesión limitada (email/Google) — Fase 7.
class PassengerPhoneLinkScreen extends ConsumerStatefulWidget {
  const PassengerPhoneLinkScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<PassengerPhoneLinkScreen> createState() =>
      _PassengerPhoneLinkScreenState();
}

class _PassengerPhoneLinkScreenState
    extends ConsumerState<PassengerPhoneLinkScreen> {
  final _countryCodeController = TextEditingController(text: '+591');
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showVerifyMethods = false;

  LoginCountryDial get _country =>
      loginCountryFromDialCode(_countryCodeController.text);

  bool get _phoneValid => _phoneController.text.trim().length >= 6;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final show = _phoneValid;
    if (show != _showVerifyMethods) {
      setState(() => _showVerifyMethods = show);
    }
  }

  Future<void> _startLinkChallenge(PhoneVerificationMethod method) async {
    if (!_phoneValid || _isLoading) return;
    final phone = _phoneController.text.trim();
    final countryCode = _countryCodeController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final otpChannel = method == PhoneVerificationMethod.verificationCode
        ? 'whatsapp_outbound'
        : 'whatsapp_inbound';

    final next = await ref.read(loginControllerProvider.notifier).linkPhoneChallenge(
          countryCode: countryCode,
          phoneNumber: phone,
          otpChannel: otpChannel,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (next == LoginNextStep.verifyCode) {
      final loginState = ref.read(loginControllerProvider);
      context.pushNamed(
        'verify_code',
        queryParameters: {
          'cc': countryCode,
          'phone': phone,
          'link': '1',
          if (widget.returnTo != null && widget.returnTo!.isNotEmpty)
            'return_to': widget.returnTo!,
          if (loginState.verificationChannel != null)
            'channel': loginState.verificationChannel!,
          if (loginState.challengeId != null)
            'challenge_id': loginState.challengeId!,
          if (loginState.waDeepLink != null) 'wa_deep_link': loginState.waDeepLink!,
        },
      );
      return;
    }

    if (next == LoginNextStep.error) {
      setState(() {
        _errorMessage = ref.read(loginControllerProvider).errorMessage;
      });
    }
  }

  void _openSmsVerifyScreen() {
    if (!_phoneValid || _isLoading) return;
    context.pushNamed(
      'verify_sms',
      queryParameters: {
        'cc': _countryCodeController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (widget.returnTo != null && widget.returnTo!.isNotEmpty)
          'return_to': widget.returnTo!,
        'link': '1',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final outboundEnabled = PassengerAppEnvironment.multichannelAuthEnabled;

    return PassengerAuthShell(
      loading: _isLoading,
      loadingMessage: l10n.commonLoading,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: _isLoading
            ? null
            : () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed('trip_request');
                }
              },
      ),
      child: PassengerAuthEntrance(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumStateView(
                icon: Icons.phone_android_rounded,
                title: l10n.phoneLinkTitle,
                message: l10n.phoneLinkSubtitle,
              ),
              const SizedBox(height: 24),
              LoginPhoneEntryPanel(
                country: _country,
                phoneController: _phoneController,
                errorMessage: null,
                isLoading: _isLoading,
                onSubmit: _phoneValid && !_isLoading
                    ? () => _startLinkChallenge(
                          PhoneVerificationMethod.whatsAppInbound,
                        )
                    : () {},
              ),
              if (_showVerifyMethods) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.loginVerifySectionLabel,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                LoginAuthActionRow(
                  enabled: !_isLoading,
                  highlighted: true,
                  accent: LoginWhatsAppBrandIcon.brandGreen,
                  icon: const LoginWhatsAppBrandIcon(size: 28),
                  label: l10n.loginVerifyMethodWaInboundShort,
                  badge: l10n.loginVerifyMethodRecommendedBadge,
                  infoMessage: l10n.loginVerifyMethodWaInboundInfo,
                  onTap: () {
                    TexiUiFeedback.softImpact();
                    _startLinkChallenge(PhoneVerificationMethod.whatsAppInbound);
                  },
                ),
                const SizedBox(height: 10),
                LoginAuthActionRow(
                  enabled: outboundEnabled && !_isLoading,
                  highlighted: false,
                  icon: Icon(
                    Icons.pin_outlined,
                    color: AppColors.textPrimary.withValues(alpha: 0.88),
                    size: 22,
                  ),
                  label: l10n.loginVerifyMethodCodeShort,
                  infoMessage: l10n.loginVerifyMethodCodeInfo,
                  onTap: outboundEnabled
                      ? () {
                          TexiUiFeedback.softImpact();
                          _startLinkChallenge(
                            PhoneVerificationMethod.verificationCode,
                          );
                        }
                      : () {},
                ),
                const SizedBox(height: 10),
                LoginAuthActionRow(
                  enabled: !_isLoading,
                  highlighted: false,
                  icon: Icon(
                    Icons.sms_outlined,
                    color: AppColors.textPrimary.withValues(alpha: 0.88),
                    size: 22,
                  ),
                  label: l10n.verifyCodeWaRequestSms,
                  infoMessage: l10n.verifySmsGoogleHint,
                  onTap: _openSmsVerifyScreen,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                PremiumStateView(
                  icon: Icons.info_outline_rounded,
                  title: l10n.loginReviewDataTitle,
                  message: _errorMessage!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
