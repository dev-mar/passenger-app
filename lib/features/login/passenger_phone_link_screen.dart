import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/passenger_app_environment.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/phone/bolivia_local_phone.dart';
import '../../core/theme/app_colors.dart';
import '../../gen_l10n/app_localizations.dart';
import 'login_controller.dart';
import 'utils/login_country_flag.dart';
import 'widgets/login_auth_action_row.dart';
import 'widgets/login_phone_entry_panel.dart';
import 'widgets/login_phone_verification_method_panel.dart';
import 'widgets/login_whatsapp_brand_icon.dart';
import 'widgets/passenger_auth_look.dart';
import 'widgets/passenger_auth_notice.dart';
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

  LoginCountryDial get _country =>
      loginCountryFromDialCode(_countryCodeController.text);

  bool get _phoneValid => isValidPassengerLocalPhone(
        dialCode: _country.dialCode,
        localNumber: _phoneController.text,
      );

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _flashError(String message) {
    showPassengerAuthNotice(context, message: message);
  }

  String _phoneInvalidMessage(AppLocalizations l10n) {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return l10n.loginPhoneRequired;
    if (isBoliviaDialCode(_country.dialCode)) {
      return l10n.loginPhoneInvalidBolivia;
    }
    return l10n.loginPhoneRequired;
  }

  Future<void> _startLinkChallenge(PhoneVerificationMethod method) async {
    if (_isLoading) return;
    if (!_phoneValid) {
      _flashError(_phoneInvalidMessage(AppLocalizations.of(context)!));
      return;
    }
    final phone = _phoneController.text.trim();
    final countryCode = _countryCodeController.text.trim();
    setState(() {
      _isLoading = true;
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
      if (otpChannel == 'whatsapp_inbound' &&
          (loginState.challengeId == null || loginState.challengeId!.isEmpty)) {
        _flashError(
          loginState.errorMessage ??
              AppLocalizations.of(context)!.verifyCodeWaOutboundFailed,
        );
        return;
      }
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
      final message = ref.read(loginControllerProvider).errorMessage;
      if (message != null && message.isNotEmpty) {
        _flashError(message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final outboundEnabled = PassengerAppEnvironment.multichannelAuthEnabled;

    return PassengerAuthShell(
      loading: _isLoading,
      loadingMessage: l10n.commonLoading,
      leading: PassengerAuthBackButton(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PassengerAuthHeadline(
              title: l10n.phoneLinkTitle,
              subtitle: l10n.phoneLinkSubtitle,
            ),
            const SizedBox(height: 22),
            LoginPhoneEntryPanel(
              country: _country,
              phoneController: _phoneController,
              isLoading: _isLoading,
              showHeadline: false,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.loginVerifySectionLabel,
              style: PassengerAuthLook.sectionLabelStyle,
            ),
            const SizedBox(height: 10),
            LoginAuthActionRow(
              enabled: !_isLoading,
              highlighted: true,
              accent: LoginWhatsAppBrandIcon.brandGreen,
              icon: const LoginWhatsAppBrandIcon(size: 26),
              label: l10n.loginVerifyMethodWaInboundShort,
              badge: l10n.loginVerifyMethodRecommendedBadge,
              infoMessage: l10n.loginVerifyMethodWaInboundInfo,
              onTap: () {
                TexiUiFeedback.softImpact();
                _startLinkChallenge(PhoneVerificationMethod.whatsAppInbound);
              },
            ),
            if (outboundEnabled) ...[
              const SizedBox(height: 8),
              LoginAuthActionRow(
                enabled: !_isLoading,
                highlighted: false,
                icon: Icon(
                  Icons.pin_outlined,
                  color: AppColors.textPrimary.withValues(alpha: 0.88),
                  size: 22,
                ),
                label: l10n.loginVerifyMethodCodeShort,
                infoMessage: l10n.loginVerifyMethodCodeInfo,
                onTap: () {
                  TexiUiFeedback.softImpact();
                  _startLinkChallenge(
                    PhoneVerificationMethod.verificationCode,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
