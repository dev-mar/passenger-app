import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/passenger_client_meta.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_safe_scrolling.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../core/network/texi_backend_error.dart';
import '../../core/l10n/trip_error_localization.dart';

/// Pantalla para ingresar el código de 4 dígitos enviado por SMS y activar al pasajero.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
  });

  final String countryCode;
  final String phoneNumber;

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrlAuth,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  @override
  void dispose() {
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
      final response = await _dio.post(
        AppConfig.authUsersPath,
        data: <String, dynamic>{
          ...passengerAuthClientMeta(),
          'phone_number': fullPhone,
          'alias_name': '',
          'profile_picture': null,
          'reuse_driver_profile': true,
        },
      );

      final body = response.data;
      if (body is! Map || body['success'] != true) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = body is Map
              ? (body['message']?.toString() ??
                  l10n.verifyCodeErrorActivateAccount)
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
    if (codeText.length != 4 || int.tryParse(codeText) == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.verifyCodeErrorInvalidCodeInput;
      });
      return;
    }

    final phoneOnlyDigits =
        widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    try {
      final response = await _dio.post(
        AppConfig.authVerifyCodePath,
        data: <String, dynamic>{
          ...passengerAuthClientMeta(),
          'country_code': widget.countryCode,
          'phone_number': phoneOnlyDigits,
          'verification_code': codeText,
        },
      );

      final body = response.data;
      if (body is! Map || body['success'] != true) {
        final message = (body is Map ? body['message']?.toString() : null) ??
            l10n.verifyCodeErrorValidateCode;
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
        return;
      }

      if (!mounted) return;

      final rawData = body['data'];
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
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.verifyCodeErrorNetwork;
        });
        return;
      }
      if (e.type == DioExceptionType.connectionError) {
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
          : (fallback ?? l10n.verifyCodeErrorValidateCode);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          l10n.verifyCodeTitle,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.verifyCodeSubtitle(maskedPhone),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Semantics(
                              label: l10n.verifyCodeFieldLabel,
                              child: SizedBox(
                                width: 180,
                                child: TextField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: l10n.verifyCodeMaskHint,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                        onSubmitted: (_) => _verify(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          PremiumStateView(
                            icon: Icons.sms_failed_rounded,
                            title: l10n.loginReviewDataTitle,
                            message: _errorMessage!,
                            actionLabel: l10n.homeRetry,
                            onAction: _verify,
                          ),
                        ],
                        const Spacer(),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: TexiScalePress(
                            child: FilledButton(
                              onPressed: _isLoading ? null : _verify,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(l10n.verifyCodeConfirm),
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: _isLoading
                              ? Padding(
                                  key: const ValueKey('verify-loading'),
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface.withValues(alpha: 0.72),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l10n.commonLoading,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('verify-loading-empty'),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.verifyCodeRetryHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: 16 + AppSafeScrolling.systemNavBottom(context),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

