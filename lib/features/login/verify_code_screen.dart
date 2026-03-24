import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/texi_scale_press.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/widgets/premium_state_view.dart';
import '../../gen_l10n/app_localizations.dart';

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

  Future<void> _verify() async {
    _codeFocusNode.unfocus();
    TexiUiFeedback.softImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final codeText = _codeController.text.trim();
    if (codeText.length != 4 || int.tryParse(codeText) == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ingresa el código de 4 dígitos que recibiste.';
      });
      return;
    }

    final phoneOnlyDigits =
        widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    try {
      final response = await _dio.post(
        '/auth/verify-code',
        data: {
          'brand': 'Texi App',
          'country_code': widget.countryCode,
          'ip': '0.0.0.0',
          'model': _deviceModel(),
          'os': Platform.operatingSystem,
          'phone_number': phoneOnlyDigits,
          'verification_code': int.parse(codeText),
        },
      );

      final body = response.data;
      if (body is! Map || body['success'] != true) {
        final message = (body is Map ? body['message']?.toString() : null) ??
            'No se pudo validar el código.';
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Código válido: continuar con UX de perfil (nombre obligatorio + foto opcional).
      // La obtención de token puede quedar pendiente si el backend todavía devuelve status=pending.
      context.goNamed(
        'profile_setup',
        queryParameters: {
          'cc': widget.countryCode,
          'phone': widget.phoneNumber,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al validar el código.';
      if (data is Map) {
        final backendMsg = data['message']?.toString();
        final detail = (data['error'] as Map?)?['details']?.toString();
        message = detail ?? backendMsg ?? message;
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error inesperado al validar el código.';
      });
    }
  }

  String _deviceModel() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Unknown';
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
                            title: l10n.commonError,
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
                        const SizedBox(height: 16),
                        Text(
                          l10n.verifyCodeRetryHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
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

