import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/feedback/texi_ui_feedback.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_ui_tokens.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../core/l10n/trip_error_localization.dart';

enum _ProfileErr { noSession, empty, badFormat }

/// Error con código de negocio del backend (`code` en JSON).
class _ProfileApiException implements Exception {
  _ProfileApiException(this.apiCode, this.message);

  final String? apiCode;
  final String message;

  @override
  String toString() => message;
}

class _PassengerVm {
  const _PassengerVm({
    required this.displayName,
    required this.phone,
    this.email,
    required this.hasProfilePhoto,
    this.profilePhotoUrl,
    required this.isVerified,
    this.accountStatus,
    required this.biometricsEnabled,
    this.lastAccessAt,
  });

  final String displayName;
  final String phone;
  final String? email;
  final bool hasProfilePhoto;
  final String? profilePhotoUrl;
  final bool isVerified;
  final String? accountStatus;
  final bool biometricsEnabled;
  final DateTime? lastAccessAt;

  factory _PassengerVm.fromJson(Map<String, dynamic> j) {
    return _PassengerVm(
      displayName: j['display_name']?.toString().trim() ?? '',
      phone: j['phone_number']?.toString().trim() ?? '',
      email: () {
        final e = j['email']?.toString().trim();
        if (e == null || e.isEmpty) return null;
        return e;
      }(),
      hasProfilePhoto: j['has_profile_photo'] == true,
      profilePhotoUrl: () {
        final u = j['profile_picture_url']?.toString().trim();
        if (u == null || u.isEmpty) return null;
        return u;
      }(),
      isVerified: j['is_verified'] == true,
      accountStatus: j['account_status']?.toString().trim(),
      biometricsEnabled: j['biometrics_enabled'] == true,
      lastAccessAt: () {
        final raw = j['last_access_at']?.toString().trim();
        if (raw == null || raw.isEmpty) return null;
        return DateTime.tryParse(raw)?.toLocal();
      }(),
    );
  }
}

/// Perfil pasajero: `GET /api/v2/auth/me` (foto firmada si aplica).
class PassengerProfilePreviewScreen extends StatefulWidget {
  const PassengerProfilePreviewScreen({super.key});

  @override
  State<PassengerProfilePreviewScreen> createState() =>
      _PassengerProfilePreviewScreenState();
}

class _PassengerProfilePreviewScreenState
    extends State<PassengerProfilePreviewScreen> {
  late Future<_PassengerVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PassengerVm> _load() async {
    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) {
      throw _ProfileErr.noSession;
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrlAuth,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        validateStatus: (s) => s != null && s < 600,
      ),
    );
    try {
      final res = await dio.get<Map<String, dynamic>>(AppConfig.authMePath);
      final root = res.data;
      if (root == null) throw _ProfileErr.empty;

      final success = root['success'];
      final isOk = success == true || success == 'true';
      if (!isOk) {
        final code = root['code']?.toString();
        final msg = root['message']?.toString() ?? '';
        throw _ProfileApiException(
          code,
          msg.isEmpty ? 'profile' : msg,
        );
      }

      if (res.statusCode != null &&
          res.statusCode! >= 400 &&
          res.statusCode! < 600) {
        final code = root['code']?.toString();
        final msg = root['message']?.toString() ?? '';
        throw _ProfileApiException(
          code,
          msg.isEmpty ? 'http ${res.statusCode}' : msg,
        );
      }

      final data = root['data'];
      if (data is! Map) throw _ProfileErr.badFormat;
      return _PassengerVm.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      if (body is Map) {
        final m = Map<String, dynamic>.from(body);
        final apiCode = m['code']?.toString();
        final msg = m['message']?.toString();
        if (code == 401) {
          throw _ProfileApiException(apiCode, msg ?? '');
        }
        if (msg != null && msg.isNotEmpty) {
          throw _ProfileApiException(apiCode, msg);
        }
      }
      if (code == 401) throw _ProfileErr.noSession;
      final msg = e.message ?? 'network';
      throw Exception(msg);
    }
  }

  Future<void> _reload() async {
    TexiUiFeedback.lightTap();
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openEditProfile(_PassengerVm profile) async {
    final nameCtrl = TextEditingController(text: profile.displayName);
    final emailCtrl = TextEditingController(text: profile.email ?? '');
    Uint8List? selectedPhotoBytes;
    String? selectedPhotoB64;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Editar información',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.surface,
                          backgroundImage: selectedPhotoBytes != null
                              ? MemoryImage(selectedPhotoBytes!)
                              : (profile.profilePhotoUrl != null &&
                                      profile.profilePhotoUrl!.isNotEmpty)
                                  ? NetworkImage(profile.profilePhotoUrl!)
                                  : null,
                          child: selectedPhotoBytes == null &&
                                  (profile.profilePhotoUrl == null ||
                                      profile.profilePhotoUrl!.isEmpty)
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 36,
                                  color: AppColors.textSecondary,
                                )
                              : null,
                        ),
                        Material(
                          color: AppColors.surface,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final pick = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 45,
                                      maxWidth: 720,
                                    );
                                    if (pick == null) return;
                                    final bytes = await pick.readAsBytes();
                                    if (!ctx.mounted) return;
                                    if (bytes.lengthInBytes > 600 * 1024) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text('La imagen es muy grande. Elige una más liviana.'),
                                        ),
                                      );
                                      return;
                                    }
                                    setSheetState(() {
                                      selectedPhotoBytes = bytes;
                                      selectedPhotoB64 = base64Encode(bytes);
                                    });
                                  },
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nombre visible',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final token = await AuthService.getValidToken();
                            if (token == null || token.isEmpty) return;
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            if (name.length < 2) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Ingresa un nombre válido')),
                                );
                              }
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              final dio = Dio(
                                BaseOptions(
                                  baseUrl: AppConfig.baseUrlAuth,
                                  connectTimeout: const Duration(seconds: 15),
                                  receiveTimeout: const Duration(seconds: 20),
                                  headers: <String, String>{
                                    'Accept': 'application/json',
                                    'Authorization': 'Bearer $token',
                                  },
                                ),
                              );
                              final res = await dio.patch<Map<String, dynamic>>(
                                AppConfig.authMePath,
                                data: <String, dynamic>{
                                  'display_name': name,
                                  if (email.isNotEmpty) 'email': email,
                                  'profile_picture': selectedPhotoB64,
                                },
                              );
                              final root = res.data;
                              final ok = root != null && root['success'] == true;
                              if (!ok) {
                                throw Exception(root?['message']?.toString() ?? 'No se pudo guardar');
                              }
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pop();
                              await _reload();
                            } catch (e) {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''))),
                              );
                            } finally {
                              if (ctx.mounted) setSheetState(() => saving = false);
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(saving ? 'Guardando...' : 'Guardar cambios'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openSupportCenter(_PassengerVm profile) async {
    final token = await AuthService.getValidToken();
    if (!mounted || token == null || token.isEmpty) return;
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    var category = 'general';
    var loading = true;
    var sending = false;
    var recent = <_SupportTicketVm>[];
    final lastStatusById = <String, String>{};
    Timer? poller;

    Future<void> loadRecent(StateSetter setSheetState, {BuildContext? notifyCtx, bool notifyChanges = false}) async {
      setSheetState(() => loading = true);
      try {
        final dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrlAuth,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
        );
        final res = await dio.get<Map<String, dynamic>>('${AppConfig.supportMyTicketsPath}?limit=6');
        final root = res.data;
        if (root == null || root['success'] != true) {
          throw Exception(root?['message']?.toString() ?? 'No se pudo cargar tickets');
        }
        final data = root['data'];
        final parsed = <_SupportTicketVm>[];
        if (data is List) {
          for (final item in data) {
            if (item is Map) {
              parsed.add(_SupportTicketVm.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
        if (notifyChanges && notifyCtx != null && notifyCtx.mounted) {
          for (final t in parsed) {
            final prev = lastStatusById[t.id];
            if (prev != null && prev != t.status) {
              ScaffoldMessenger.of(notifyCtx).showSnackBar(
                SnackBar(content: Text('Ticket ${t.ticketNumber} cambió a ${t.status}')),
              );
            }
          }
        }
        lastStatusById
          ..clear()
          ..addEntries(parsed.map((e) => MapEntry(e.id, e.status)));
        setSheetState(() => recent = parsed);
      } catch (_) {
        setSheetState(() => recent = const []);
      } finally {
        setSheetState(() => loading = false);
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (loading && recent.isEmpty) {
              loadRecent(setSheetState, notifyCtx: ctx);
            }
            poller ??= Timer.periodic(const Duration(seconds: 25), (_) {
              if (!ctx.mounted || sending) return;
              loadRecent(setSheetState, notifyCtx: ctx, notifyChanges: true);
            });
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Centro de soporte',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('General')),
                        DropdownMenuItem(value: 'trip', child: Text('Viaje')),
                        DropdownMenuItem(value: 'payment', child: Text('Pago')),
                        DropdownMenuItem(value: 'account', child: Text('Cuenta')),
                        DropdownMenuItem(value: 'safety', child: Text('Seguridad')),
                        DropdownMenuItem(value: 'technical', child: Text('Técnico')),
                      ],
                      onChanged: sending
                          ? null
                          : (v) {
                              if (v != null) setSheetState(() => category = v);
                            },
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Asunto',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: messageCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Detalle',
                        prefixIcon: Icon(Icons.message_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: sending
                          ? null
                          : () async {
                              final subject = subjectCtrl.text.trim();
                              final message = messageCtrl.text.trim();
                              if (subject.length < 3 || message.length < 10) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Completa asunto y detalle (mín. 3/10 caracteres).')),
                                );
                                return;
                              }
                              setSheetState(() => sending = true);
                              try {
                                final dio = Dio(
                                  BaseOptions(
                                    baseUrl: AppConfig.baseUrlAuth,
                                    connectTimeout: const Duration(seconds: 15),
                                    receiveTimeout: const Duration(seconds: 20),
                                    headers: <String, String>{
                                      'Accept': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                  ),
                                );
                                final res = await dio.post<Map<String, dynamic>>(
                                  AppConfig.supportTicketsPath,
                                  data: <String, dynamic>{
                                    'category': category,
                                    'subject': subject,
                                    'message': message,
                                    'platform': 'flutter_passenger',
                                  },
                                );
                                final root = res.data;
                                if (root == null || root['success'] != true) {
                                  throw Exception(root?['message']?.toString() ?? 'No se pudo crear ticket');
                                }
                                subjectCtrl.clear();
                                messageCtrl.clear();
                                await loadRecent(setSheetState);
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Ticket enviado correctamente')),
                                );
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(e.toString().replaceFirst(RegExp(r'^Exception:\\s*'), ''))),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) setSheetState(() => sending = false);
                              }
                            },
                      icon: sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(sending ? 'Enviando...' : 'Enviar ticket'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mis tickets recientes',
                            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: sending ? null : () => loadRecent(setSheetState, notifyCtx: ctx),
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Actualizar',
                        ),
                      ],
                    ),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Aún no tienes tickets registrados.'),
                      )
                    else
                      ...recent.map(
                        (t) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            final dio = Dio(
                              BaseOptions(
                                baseUrl: AppConfig.baseUrlAuth,
                                connectTimeout: const Duration(seconds: 20),
                                receiveTimeout: const Duration(seconds: 30),
                                headers: <String, String>{
                                  'Accept': 'application/json',
                                  'Authorization': 'Bearer $token',
                                },
                              ),
                            );
                            final detailRes = await dio.get<Map<String, dynamic>>(
                              AppConfig.supportTicketDetailPath(t.id),
                            );
                            final detailRoot = detailRes.data;
                            if (detailRoot == null || detailRoot['success'] != true) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(detailRoot?['message']?.toString() ?? 'No se pudo cargar detalle')),
                                );
                              }
                              return;
                            }
                            final detailData = detailRoot['data'];
                            if (detailData is! Map) return;
                            final detail = _SupportTicketDetailVm.fromJson(Map<String, dynamic>.from(detailData));
                            if (!ctx.mounted) return;
                            var uploading = false;
                            await showModalBottomSheet<void>(
                              context: ctx,
                              isScrollControlled: true,
                              backgroundColor: AppColors.surface,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (detailCtx) {
                                return StatefulBuilder(
                                  builder: (detailCtx, setDetailState) {
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              '${detail.ticketNumber} · ${detail.subject}',
                                              style: Theme.of(detailCtx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 6),
                                            Text('${detail.category} · ${detail.status} · ${detail.priority}'),
                                            const SizedBox(height: 12),
                                            Text(detail.message),
                                            const SizedBox(height: 14),
                                            FilledButton.icon(
                                              onPressed: uploading
                                                  ? null
                                                  : () async {
                                                      final picker = ImagePicker();
                                                      final file = await picker.pickImage(
                                                        source: ImageSource.gallery,
                                                        imageQuality: 85,
                                                        maxWidth: 1600,
                                                      );
                                                      if (file == null) return;
                                                      final bytes = await file.readAsBytes();
                                                      if (bytes.isEmpty) return;
                                                      setDetailState(() => uploading = true);
                                                      try {
                                                        final ext = file.name.toLowerCase();
                                                        final ct = ext.endsWith('.png')
                                                            ? 'image/png'
                                                            : ext.endsWith('.webp')
                                                                ? 'image/webp'
                                                                : 'image/jpeg';
                                                        final pre = await dio.post<Map<String, dynamic>>(
                                                          AppConfig.supportTicketAttachmentPresignPath(detail.id),
                                                          data: <String, dynamic>{
                                                            'file_name': file.name,
                                                            'content_type': ct,
                                                            'size_bytes': bytes.length,
                                                          },
                                                        );
                                                        final preRoot = pre.data;
                                                        if (preRoot == null || preRoot['success'] != true) {
                                                          throw Exception(preRoot?['message']?.toString() ?? 'No se pudo preparar adjunto');
                                                        }
                                                        final preData = preRoot['data'] as Map<String, dynamic>;
                                                        final uploadUrl = preData['upload_url']?.toString() ?? '';
                                                        final storageKey = preData['storage_key']?.toString() ?? '';
                                                        if (uploadUrl.isEmpty || storageKey.isEmpty) {
                                                          throw Exception('Respuesta de presign inválida');
                                                        }
                                                        await Dio().put(
                                                          uploadUrl,
                                                          data: bytes,
                                                          options: Options(
                                                            headers: <String, String>{'Content-Type': ct},
                                                            contentType: ct,
                                                          ),
                                                        );
                                                        final reg = await dio.post<Map<String, dynamic>>(
                                                          AppConfig.supportTicketAttachmentRegisterPath(detail.id),
                                                          data: <String, dynamic>{
                                                            'storage_key': storageKey,
                                                            'file_name': file.name,
                                                            'content_type': ct,
                                                            'size_bytes': bytes.length,
                                                          },
                                                        );
                                                        final regRoot = reg.data;
                                                        if (regRoot == null || regRoot['success'] != true) {
                                                          throw Exception(regRoot?['message']?.toString() ?? 'No se pudo registrar adjunto');
                                                        }
                                                        if (detailCtx.mounted) {
                                                          ScaffoldMessenger.of(detailCtx).showSnackBar(
                                                            const SnackBar(content: Text('Adjunto subido correctamente')),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (detailCtx.mounted) {
                                                          ScaffoldMessenger.of(detailCtx).showSnackBar(
                                                            SnackBar(content: Text(e.toString().replaceFirst(RegExp(r'^Exception:\\s*'), ''))),
                                                          );
                                                        }
                                                      } finally {
                                                        if (detailCtx.mounted) setDetailState(() => uploading = false);
                                                      }
                                                    },
                                              icon: uploading
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                                                    )
                                                  : const Icon(Icons.attachment_rounded),
                                              label: Text(uploading ? 'Subiendo...' : 'Adjuntar imagen'),
                                            ),
                                            const SizedBox(height: 10),
                                            Text('Timeline', style: Theme.of(detailCtx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                            const SizedBox(height: 8),
                                            ...detail.events.map(
                                              (e) => ListTile(
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                leading: const Icon(Icons.timeline_rounded, color: AppColors.primary),
                                                title: Text(e.message),
                                                subtitle: Text('${e.actorType} · ${e.eventType}'),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text('Adjuntos', style: Theme.of(detailCtx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                            const SizedBox(height: 8),
                                            if (detail.attachments.isEmpty)
                                              const Text('Sin adjuntos')
                                            else
                                              ...detail.attachments.map(
                                                (a) => ListTile(
                                                  dense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                  onTap: a.previewUrl.isEmpty
                                                      ? null
                                                      : () {
                                                          showDialog<void>(
                                                            context: detailCtx,
                                                            builder: (_) => Dialog(
                                                              insetPadding: const EdgeInsets.all(12),
                                                              child: InteractiveViewer(
                                                                minScale: 1,
                                                                maxScale: 4,
                                                                child: Image.network(
                                                                  a.previewUrl,
                                                                  fit: BoxFit.contain,
                                                                  errorBuilder: (context, error, stackTrace) => const Padding(
                                                                    padding: EdgeInsets.all(24),
                                                                    child: Icon(Icons.broken_image_outlined),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                  leading: const Icon(Icons.image_outlined, color: AppColors.primary),
                                                  title: Text(a.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  subtitle: Text('${a.contentType} · ${a.sizeBytes} bytes'),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                            if (!ctx.mounted) return;
                            await loadRecent(setSheetState, notifyCtx: ctx);
                          },
                          leading: Icon(
                            t.status == 'open' ? Icons.mark_email_unread_outlined : Icons.check_circle_outline,
                            color: t.status == 'open' ? AppColors.primary : AppColors.success,
                          ),
                          title: Text('${t.ticketNumber} · ${t.subject}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${t.category} · ${t.status}'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    poller?.cancel();
    poller = null;
  }

  void _close() {
    TexiUiFeedback.lightTap();
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRouter.home);
    }
  }

  String _errMsg(Object? e, AppLocalizations l10n) {
    if (e == _ProfileErr.noSession) return l10n.profileErrorNoSession;
    if (e == _ProfileErr.empty || e == _ProfileErr.badFormat) {
      return l10n.profileErrorBody;
    }
    if (e is _ProfileApiException) {
      final ac = e.apiCode;
      if (ac != null && ac.startsWith('RBAC_')) {
        return localizedTripApiError(
          l10n,
          ac,
          fallbackMessage:
              e.message.isNotEmpty && e.message != 'profile' ? e.message : null,
        );
      }
      switch (e.apiCode) {
        case 'PASS_AUTH_FORBIDDEN':
        case 'FORBIDDEN':
          return l10n.profileErrorForbidden;
        case 'PASS_USER_NOT_FOUND':
        case 'NOT_FOUND':
          return l10n.profileErrorNotFound;
        case 'PASS_AUTH_INVALID':
        case 'UNAUTHORIZED':
          return l10n.profileErrorNoSession;
      }
      if (e.message.isNotEmpty && e.message != 'profile') {
        return e.message;
      }
    }
    return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_PassengerVm>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _LoadingState(onClose: _close);
          }
          if (snap.hasError) {
            return _ErrorState(
              message: _errMsg(snap.error, l10n),
              onRetry: _reload,
              onClose: _close,
              l10n: l10n,
            );
          }
          return _ProfileBody(
            profile: snap.data!,
            l10n: l10n,
            onRefresh: _reload,
            onEditInfo: () => _openEditProfile(snap.data!),
            onSupport: () => _openSupportCenter(snap.data!),
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onClose,
    required this.l10n,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IconButton(
              alignment: Alignment.centerLeft,
              onPressed: onClose,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: AppColors.primary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: AppSpacing.sheetV),
                  Text(
                    l10n.profileErrorTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  FilledButton.icon(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.homeRetry),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.l10n,
    required this.onRefresh,
    required this.onEditInfo,
    required this.onSupport,
  });

  final _PassengerVm profile;
  final AppLocalizations l10n;
  final Future<void> Function() onRefresh;
  final VoidCallback onEditInfo;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(
              profile: profile,
              l10n: l10n,
              onRefresh: onRefresh,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxx,
              0,
              AppSpacing.xxx,
              AppSpacing.sheetBodyV,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHighlights(profile: profile, l10n: l10n),
                  const SizedBox(height: AppSpacing.section),
                  _QuickActionsPanel(
                    l10n: l10n,
                    onEditInfo: onEditInfo,
                    onSupport: onSupport,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _ModernSectionTitle(label: l10n.profileSectionBasics),
                  const SizedBox(height: AppSpacing.xl),
                  _GlassCard(
                    child: Column(
                      children: [
                        _DataRow(
                          icon: Icons.badge_outlined,
                          label: l10n.profileFieldFullName,
                          value: profile.displayName.isEmpty ? '—' : profile.displayName,
                        ),
                        const Divider(height: 1),
                        _DataRow(
                          icon: Icons.smartphone_rounded,
                          label: l10n.profileFieldPhone,
                          value: profile.phone.isEmpty ? '—' : profile.phone,
                        ),
                        if (profile.email != null && profile.email!.isNotEmpty) ...[
                          const Divider(height: 1),
                          _DataRow(
                            icon: Icons.alternate_email_rounded,
                            label: l10n.profileFieldEmail,
                            value: profile.email!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _ModernSectionTitle(label: l10n.profilePhotoFromServer),
                  const SizedBox(height: AppSpacing.xl),
                  _PhotoBlock(profile: profile),
                  const SizedBox(height: AppSpacing.section),
                  _ModernSectionTitle(label: l10n.profileSectionPreferences),
                  const SizedBox(height: AppSpacing.xl),
                  _PreferencesCard(l10n: l10n),
                  const SizedBox(height: AppSpacing.section),
                  _ModernSectionTitle(label: l10n.profileSectionSecurity),
                  const SizedBox(height: AppSpacing.xl),
                  _SecurityCard(
                    l10n: l10n,
                    profile: profile,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.l10n,
    required this.onRefresh,
  });

  final _PassengerVm profile;
  final AppLocalizations l10n;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName.isEmpty ? profile.phone : profile.displayName;
    final subtitle = profile.displayName.isEmpty ? l10n.profileTaglinePassenger : profile.phone;
    final hasEmail = profile.email != null && profile.email!.trim().isNotEmpty;
    final photoReady = profile.profilePhotoUrl != null && profile.profilePhotoUrl!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          height: 176,
          child: Container(
            padding: const EdgeInsets.only(bottom: 36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  AppColors.surface.withValues(alpha: 0.82),
                  AppColors.background.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.62, 1.0],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        TexiUiFeedback.lightTap();
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed(AppRouter.home);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.onPrimary,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.22),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: l10n.profileRefreshTooltip,
                      onPressed: () async {
                        TexiUiFeedback.lightTap();
                        await onRefresh();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppColors.onPrimary,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeroAvatar(profile: profile, l10n: l10n),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
                child: Column(
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        _ChipPill(
                          icon: profile.isVerified
                              ? Icons.verified_rounded
                              : Icons.info_outline_rounded,
                          label: profile.isVerified
                              ? l10n.profileVerifiedBadge
                              : l10n.profileSectionSecurity,
                          foreground: profile.isVerified
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        if (hasEmail)
                          _ChipPill(
                            icon: Icons.alternate_email_rounded,
                            label: profile.email ?? '',
                            foreground: AppColors.textSecondary,
                          ),
                        _ChipPill(
                          icon: photoReady
                              ? Icons.image_rounded
                              : Icons.image_not_supported_outlined,
                          label: photoReady
                              ? l10n.profilePhotoFromServer
                              : l10n.profileNoServerPhoto,
                          foreground: photoReady
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        if (profile.accountStatus != null &&
                            profile.accountStatus!.isNotEmpty)
                          _ChipPill(
                            icon: Icons.shield_outlined,
                            label:
                                '${l10n.profileAccountLabel}: ${profile.accountStatus}',
                            foreground: AppColors.textSecondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.profile, required this.l10n});

  final _PassengerVm profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    final url = profile.profilePhotoUrl;
    final showNet = url != null && url.isNotEmpty;

    final Widget child = showNet
        ? ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheWidth: 360,
              loadingBuilder: (context, child, prog) {
                if (prog == null) return child;
                return Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary.withValues(alpha: 0.9),
                    ),
                  ),
                );
              },
              errorBuilder: (context, _, _) => _initials(context, size),
            ),
          )
        : _initials(context, size);

    return Semantics(
      label: l10n.profileAvatarSemantics,
      child: Container(
        width: size + 8,
        height: size + 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.55),
              AppColors.border.withValues(alpha: 0.6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _initials(BuildContext context, double diameter) {
    final name = profile.displayName.trim();
    final parts =
        name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    String ini = '?';
    if (parts.isNotEmpty) {
      ini = parts.length == 1
          ? (parts[0].length >= 2
                  ? parts[0].substring(0, 2)
                  : parts[0])
              .toUpperCase()
          : '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (profile.phone.isNotEmpty) {
      var d = profile.phone.replaceAll(RegExp(r'[^\d]'), '');
      if (d.length > 2) d = d.substring(d.length - 2);
      ini = d;
    }
    return CircleAvatar(
      radius: diameter / 2 - 3,
      backgroundColor: AppColors.surface,
      child: Text(
        ini,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: diameter * 0.28,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSectionTitle extends StatelessWidget {
  const _ModernSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadii.xs),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadii.lg + 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: child,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxx,
        vertical: AppSpacing.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primary.withValues(alpha: 0.9)),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoBlock extends StatelessWidget {
  const _PhotoBlock({required this.profile});

  final _PassengerVm profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final url = profile.profilePhotoUrl;
    final showNet = url != null && url.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.section,
        vertical: AppSpacing.section,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadii.lg + 4),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.background,
            backgroundImage: showNet ? NetworkImage(url) : null,
            child: !showNet
                ? Icon(
                    Icons.person_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    size: 52,
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            showNet ? l10n.profilePhotoFromServer : l10n.profileNoServerPhoto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHighlights extends StatelessWidget {
  const _ProfileHighlights({
    required this.profile,
    required this.l10n,
  });

  final _PassengerVm profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hasName = profile.displayName.trim().isNotEmpty;
    final hasPhone = profile.phone.trim().isNotEmpty;
    final hasEmail = profile.email != null && profile.email!.trim().isNotEmpty;
    final hasPhoto = profile.profilePhotoUrl != null && profile.profilePhotoUrl!.trim().isNotEmpty;
    final completed = [hasName, hasPhone, hasEmail, hasPhoto].where((e) => e).length;
    final completion = ((completed / 4) * 100).round();

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profileSectionBasics,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                Text(
                  '$completion%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: completion / 100,
                color: AppColors.primary,
                backgroundColor: AppColors.border.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.verified_user_outlined,
                    label: l10n.profileAccountLabel,
                    value: profile.isVerified ? 'OK' : '—',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatItem(
                    icon: Icons.contact_page_outlined,
                    label: l10n.profileFieldFullName,
                    value: hasName ? 'OK' : '—',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatItem(
                    icon: Icons.image_outlined,
                    label: l10n.profilePhotoFromServer,
                    value: hasPhoto ? 'OK' : '—',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({
    required this.l10n,
    required this.onEditInfo,
    required this.onSupport,
  });

  final AppLocalizations l10n;
  final VoidCallback onEditInfo;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones rápidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.edit_outlined,
                    label: l10n.profileActionEditInfo,
                    onTap: onEditInfo,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.support_agent_rounded,
                    label: l10n.profileActionSupport,
                    onTap: onSupport,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatefulWidget {
  const _PreferencesCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<_PreferencesCard> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await AuthService.getPassengerPreferences();
    if (!mounted) return;
    setState(() {
      _notifications = prefs.notificationsEnabled;
      _darkMode = prefs.darkModeEnabled;
      _loaded = true;
    });
  }

  Future<void> _persist() async {
    await AuthService.savePassengerPreferences(
      notificationsEnabled: _notifications,
      darkModeEnabled: _darkMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const _GlassCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxx),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    return _GlassCard(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: _notifications,
            onChanged: (v) {
              TexiUiFeedback.lightTap();
              setState(() => _notifications = v);
              _persist();
            },
            title: Text(widget.l10n.profileFieldNotifications),
            subtitle: Text(widget.l10n.profileFieldNotificationsDesc),
            secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            value: _darkMode,
            onChanged: (v) {
              TexiUiFeedback.lightTap();
              setState(() => _darkMode = v);
              _persist();
            },
            title: Text(widget.l10n.profileFieldDarkMode),
            subtitle: Text(widget.l10n.profileFieldDarkModeDesc),
            secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxx),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.l10n,
    required this.profile,
  });

  final AppLocalizations l10n;
  final _PassengerVm profile;

  String _formatLastAccess() {
    final dt = profile.lastAccessAt;
    if (dt == null) return l10n.profileSecurityNotAvailable;
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          _DataRow(
            icon: Icons.fingerprint_rounded,
            label: l10n.profileFieldBiometrics,
            value: profile.biometricsEnabled
                ? l10n.commonEnabled
                : l10n.commonDisabled,
          ),
          const Divider(height: 1),
          _DataRow(
            icon: Icons.schedule_rounded,
            label: l10n.profileFieldLastAccess,
            value: _formatLastAccess(),
          ),
        ],
      ),
    );
  }
}

class _SupportTicketVm {
  const _SupportTicketVm({
    required this.id,
    required this.ticketNumber,
    required this.category,
    required this.subject,
    required this.status,
  });

  final String id;
  final String ticketNumber;
  final String category;
  final String subject;
  final String status;

  factory _SupportTicketVm.fromJson(Map<String, dynamic> json) {
    return _SupportTicketVm(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? 'SUP-NA',
      category: json['category']?.toString() ?? 'general',
      subject: json['subject']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
    );
  }
}

class _SupportTicketDetailVm {
  const _SupportTicketDetailVm({
    required this.id,
    required this.ticketNumber,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.events,
    required this.attachments,
  });

  final String id;
  final String ticketNumber;
  final String category;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final List<_SupportTicketEventVm> events;
  final List<_SupportTicketAttachmentVm> attachments;

  factory _SupportTicketDetailVm.fromJson(Map<String, dynamic> json) {
    final eventsRaw = json['events'];
    final atRaw = json['attachments'];
    return _SupportTicketDetailVm(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? 'SUP-NA',
      category: json['category']?.toString() ?? 'general',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'normal',
      events: eventsRaw is List
          ? eventsRaw.whereType<Map>().map((e) => _SupportTicketEventVm.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
      attachments: atRaw is List
          ? atRaw.whereType<Map>().map((e) => _SupportTicketAttachmentVm.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
    );
  }
}

class _SupportTicketEventVm {
  const _SupportTicketEventVm({
    required this.actorType,
    required this.eventType,
    required this.message,
  });
  final String actorType;
  final String eventType;
  final String message;

  factory _SupportTicketEventVm.fromJson(Map<String, dynamic> json) {
    return _SupportTicketEventVm(
      actorType: json['actor_type']?.toString() ?? 'system',
      eventType: json['event_type']?.toString() ?? 'event',
      message: json['message']?.toString() ?? '',
    );
  }
}

class _SupportTicketAttachmentVm {
  const _SupportTicketAttachmentVm({
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.previewUrl,
  });
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String previewUrl;

  factory _SupportTicketAttachmentVm.fromJson(Map<String, dynamic> json) {
    return _SupportTicketAttachmentVm(
      fileName: json['file_name']?.toString() ?? 'archivo',
      contentType: json['content_type']?.toString() ?? 'application/octet-stream',
      sizeBytes: int.tryParse('${json['size_bytes']}') ?? 0,
      previewUrl: json['preview_url']?.toString() ?? '',
    );
  }
}
