import 'dart:typed_data';

import '../../core/config/app_config.dart';
import '../../core/network/passenger_api_client.dart';
import 'support_ticket_models.dart';

class PassengerSupportRepository {
  PassengerSupportRepository(this._client);

  final PassengerApiClient _client;

  Future<List<SupportTicketSummary>> fetchRecentTickets({int limit = 6}) async {
    final res = await _client.getAuth<Map<String, dynamic>>(
      path: AppConfig.supportMyTicketsPath,
      queryParameters: <String, dynamic>{'limit': limit},
    );
    final root = res.data;
    if (root == null || root['success'] != true) {
      throw Exception(root?['message']?.toString() ?? 'load_failed');
    }
    final data = root['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => SupportTicketSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    final res = await _client.postAuthWithRetry<Map<String, dynamic>>(
      path: AppConfig.supportTicketsPath,
      flow: 'passenger_support_create',
      data: <String, dynamic>{
        'category': category,
        'subject': subject,
        'message': message,
        'platform': 'flutter_passenger',
      },
    );
    final root = res.data;
    if (root == null || root['success'] != true) {
      throw Exception(root?['message']?.toString() ?? 'create_failed');
    }
  }

  Future<SupportTicketDetail> fetchTicketDetail(String ticketId) async {
    final res = await _client.getAuth<Map<String, dynamic>>(
      path: AppConfig.supportTicketDetailPath(ticketId),
    );
    final root = res.data;
    if (root == null || root['success'] != true) {
      throw Exception(root?['message']?.toString() ?? 'detail_failed');
    }
    final data = root['data'];
    if (data is! Map) {
      throw Exception('detail_failed');
    }
    return SupportTicketDetail.fromJson(Map<String, dynamic>.from(data));
  }

  Future<SupportTicketPresignResult> presignAttachment({
    required String ticketId,
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) async {
    final res = await _client.postAuth<Map<String, dynamic>>(
      path: AppConfig.supportTicketAttachmentPresignPath(ticketId),
      data: <String, dynamic>{
        'file_name': fileName,
        'content_type': contentType,
        'size_bytes': sizeBytes,
      },
    );
    final root = res.data;
    if (root == null || root['success'] != true) {
      throw Exception(root?['message']?.toString() ?? 'presign_failed');
    }
    final data = root['data'];
    if (data is! Map) throw Exception('presign_failed');
    final map = Map<String, dynamic>.from(data);
    final uploadUrl = map['upload_url']?.toString() ?? '';
    final storageKey = map['storage_key']?.toString() ?? '';
    if (uploadUrl.isEmpty || storageKey.isEmpty) {
      throw Exception('presign_invalid');
    }
    return SupportTicketPresignResult(
      uploadUrl: uploadUrl,
      storageKey: storageKey,
    );
  }

  Future<void> uploadAttachmentBytes({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) {
    return _client.uploadToPresignedUrl(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<void> registerAttachment({
    required String ticketId,
    required String storageKey,
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) async {
    final res = await _client.postAuth<Map<String, dynamic>>(
      path: AppConfig.supportTicketAttachmentRegisterPath(ticketId),
      data: <String, dynamic>{
        'storage_key': storageKey,
        'file_name': fileName,
        'content_type': contentType,
        'size_bytes': sizeBytes,
      },
    );
    final root = res.data;
    if (root == null || root['success'] != true) {
      throw Exception(root?['message']?.toString() ?? 'register_failed');
    }
  }
}
