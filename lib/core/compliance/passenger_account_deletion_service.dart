import 'package:dio/dio.dart';

import '../network/passenger_api_client.dart';
import '../network/texi_backend_error.dart';

class PassengerAccountDeletionStatus {
  const PassengerAccountDeletionStatus({
    required this.pending,
    this.graceDays,
    this.deletionRequestedAt,
    this.deletionEffectiveAt,
    this.daysRemaining,
  });

  final bool pending;
  final int? graceDays;
  final String? deletionRequestedAt;
  final String? deletionEffectiveAt;
  final int? daysRemaining;

  factory PassengerAccountDeletionStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const PassengerAccountDeletionStatus(pending: false);
    }
    return PassengerAccountDeletionStatus(
      pending: json['pending'] == true,
      graceDays: _asInt(json['grace_days']),
      deletionRequestedAt: json['deletion_requested_at']?.toString(),
      deletionEffectiveAt: json['deletion_effective_at']?.toString(),
      daysRemaining: _asInt(json['days_remaining']),
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

sealed class PassengerAccountDeletionResult {
  const PassengerAccountDeletionResult();
}

class PassengerAccountDeletionScheduled extends PassengerAccountDeletionResult {
  const PassengerAccountDeletionScheduled(
    this.status, {
    this.message,
  });

  final PassengerAccountDeletionStatus status;
  final String? message;
}

class PassengerAccountDeletionCancelled extends PassengerAccountDeletionResult {
  const PassengerAccountDeletionCancelled({this.message});
  final String? message;
}

class PassengerAccountDeletionFailure extends PassengerAccountDeletionResult {
  const PassengerAccountDeletionFailure(this.message, {this.code});

  final String message;
  final String? code;
}

/// Self-service DELETE `/api/v2/auth/me` (Play Store User Data).
class PassengerAccountDeletionService {
  PassengerAccountDeletionService({PassengerApiClient? apiClient})
      : _apiClient = apiClient ?? PassengerApiClient();

  final PassengerApiClient _apiClient;

  Future<PassengerAccountDeletionResult> deleteAccount() async {
    try {
      final response = await _apiClient.deleteAuth<Map<String, dynamic>>(
        path: '/auth/me',
        data: const {'confirm': true},
        flow: 'account_delete',
      );
      final data = PassengerApiClient.parseSuccessData(response.data);
      final deletion = PassengerAccountDeletionStatus.fromJson(
        data['account_deletion'] as Map<String, dynamic>?,
      );
      return PassengerAccountDeletionScheduled(
        deletion,
        message: data['message']?.toString(),
      );
    } on PassengerApiSessionException {
      return const PassengerAccountDeletionFailure(
        'Sesión expirada. Inicia sesión e intenta de nuevo.',
        code: 'SESSION_EXPIRED',
      );
    } on DioException catch (e) {
      final message = TexiBackendError.messageFromResponse(e.response?.data) ??
          e.message ??
          'No se pudo programar la eliminación.';
      return PassengerAccountDeletionFailure(
        message,
        code: TexiBackendError.codeFromResponse(e.response?.data),
      );
    } catch (_) {
      return const PassengerAccountDeletionFailure(
        'No se pudo programar la eliminación.',
      );
    }
  }

  Future<PassengerAccountDeletionResult> cancelAccountDeletion() async {
    try {
      final response = await _apiClient.postAuthWithRetry<Map<String, dynamic>>(
        path: '/auth/me/deletion/cancel',
        flow: 'account_delete_cancel',
      );
      final data = PassengerApiClient.parseSuccessData(response.data);
      return PassengerAccountDeletionCancelled(
        message: data['message']?.toString(),
      );
    } on PassengerApiSessionException {
      return const PassengerAccountDeletionFailure(
        'Sesión expirada. Inicia sesión e intenta de nuevo.',
        code: 'SESSION_EXPIRED',
      );
    } on DioException catch (e) {
      final message = TexiBackendError.messageFromResponse(e.response?.data) ??
          e.message ??
          'No se pudo cancelar la eliminación.';
      return PassengerAccountDeletionFailure(
        message,
        code: TexiBackendError.codeFromResponse(e.response?.data),
      );
    } catch (_) {
      return const PassengerAccountDeletionFailure(
        'No se pudo cancelar la eliminación.',
      );
    }
  }
}
