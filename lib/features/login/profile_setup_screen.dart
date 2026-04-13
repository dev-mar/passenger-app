import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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

/// Tercera pantalla del onboarding:
/// - Nombre obligatorio
/// - Foto opcional (se envía en Base64 al endpoint del backend)
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
  });

  final String countryCode;
  final String phoneNumber;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _saving = false;
  Uint8List? _profileImageBytes;
  String? _profileImageBase64;
  String? _errorMessage;

  final Dio _dio = Dio(
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

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 40,
        maxWidth: 256,
      );
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      // Limitar tamaño para evitar 502 por payload muy grande (Base64).
      // 350KB binario aprox → ~470KB base64.
      if (bytes.lengthInBytes > 350 * 1024) {
        if (!mounted) return;
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.profilePhotoTooLarge;
        });
        return;
      }
      final base64 = base64Encode(bytes);
      setState(() {
        _profileImageBytes = bytes;
        _profileImageBase64 = base64;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = AppLocalizations.of(context)!.profilePhotoPickFailed);
    }
  }

  Future<void> _save() async {
    _nameFocusNode.unfocus();
    if (!_formKey.currentState!.validate()) return;
    TexiUiFeedback.softImpact();
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    final phoneDigits = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
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
          'alias_name': name,
          // Foto opcional: si no hay imagen, enviamos null explícito.
          'profile_picture': _profileImageBase64,
        },
      );

      final body = response.data;
      if (body is! Map || body['success'] != true) {
        setState(() => _saving = false);
        if (!mounted) return;
        final msg =
            body is Map ? body['message']?.toString() : null;
        setState(() => _errorMessage = msg ?? l10n.profileSetupErrorCompleteRegistration);
        context.goNamed('login');
        return;
      }

      final data = body['data'];
      if (data is! Map) {
        setState(() => _saving = false);
        if (!mounted) return;
        context.goNamed('login');
        return;
      }

      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        setState(() => _saving = false);
        if (!mounted) return;
        context.goNamed('login');
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
      await AuthService.savePassengerDisplayName(name);

      if (!mounted) return;
      setState(() => _saving = false);
      context.goNamed('trip_request');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        setState(() {
          _errorMessage =
              l10n.profileSetupErrorNetwork;
        });
        return;
      }
      if (e.type == DioExceptionType.connectionError) {
        setState(() {
          _errorMessage = l10n.profileSetupErrorConnection;
        });
        return;
      }
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final code = TexiBackendError.codeFromResponse(data);
      final backendMsg = (data is Map)
          ? (data['message']?.toString() ??
              (data['error'] as Map?)?['details']?.toString())
          : null;
      final msg = (code != null && code.startsWith('RBAC_'))
          ? localizedTripApiError(l10n, code, fallbackMessage: backendMsg)
          : (backendMsg ??
              (status != null
                  ? l10n.profileSetupErrorRegisterStatus(status.toString())
                  : l10n.profileSetupErrorCompleteRegistration));
      setState(() {
        _errorMessage = msg;
      });
      context.goNamed('login');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      context.goNamed('login');
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  l10n.profileSetupTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.profileSetupSubtitle(maskedPhone),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        backgroundImage: _profileImageBytes != null
                            ? MemoryImage(_profileImageBytes!)
                            : null,
                        child: _profileImageBytes == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 44,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () {
                            TexiUiFeedback.lightTap();
                            showModalBottomSheet<void>(
                              context: context,
                              backgroundColor: AppColors.surface,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading:
                                          const Icon(Icons.camera_alt_rounded),
                                      title: Text(l10n.profilePhotoTake),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _pickProfilePhoto(ImageSource.camera);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library_rounded),
                                      title: Text(l10n.profilePhotoGallery),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _pickProfilePhoto(ImageSource.gallery);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  PremiumStateView(
                    icon: Icons.warning_amber_rounded,
                    title: l10n.loginReviewDataTitle,
                    message: _errorMessage!,
                    actionLabel: l10n.profileAcknowledge,
                    onAction: () => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.profileSetupNameLabel,
                    hintText: l10n.profileSetupNameHint,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return l10n.profileSetupNameRequired;
                    if (value.length < 2) return l10n.profileSetupNameTooShort;
                    return null;
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                const Spacer(),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: TexiScalePress(
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () {
                              TexiUiFeedback.lightTap();
                              _save();
                            },
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.profileSetupContinue),
                    ),
                  ),
                ),
                SizedBox(
                  height: 16 + AppSafeScrolling.systemNavBottom(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

