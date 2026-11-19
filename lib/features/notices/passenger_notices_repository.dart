import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/passenger_api_client.dart';
import '../../core/network/passenger_api_providers.dart';

class PassengerNoticeItem {
  const PassengerNoticeItem({
    required this.id,
    required this.title,
    required this.body,
    this.sentAt,
    this.readAt,
    this.unread = true,
    this.deepLink,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? sentAt;
  final DateTime? readAt;
  final bool unread;
  final String? deepLink;

  PassengerNoticeItem copyWith({DateTime? readAt, bool? unread}) {
    return PassengerNoticeItem(
      id: id,
      title: title,
      body: body,
      sentAt: sentAt,
      readAt: readAt ?? this.readAt,
      unread: unread ?? this.unread,
      deepLink: deepLink,
    );
  }

  static PassengerNoticeItem fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(Object? raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString())?.toLocal();
    }

    return PassengerNoticeItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      sentAt: parseTs(json['sentAt'] ?? json['sent_at']),
      readAt: parseTs(json['readAt'] ?? json['read_at']),
      unread: json['unread'] == true,
      deepLink: json['deepLink']?.toString() ?? json['deep_link']?.toString(),
    );
  }
}

class PassengerNoticesSnapshot {
  const PassengerNoticesSnapshot({
    this.items = const [],
    this.unreadCount = 0,
  });

  final List<PassengerNoticeItem> items;
  final int unreadCount;
}

final passengerNoticesRepositoryProvider = Provider<PassengerNoticesRepository>(
  (ref) => PassengerNoticesRepository(ref.watch(passengerApiClientProvider)),
);

class PassengerNoticesRepository {
  PassengerNoticesRepository(this._client);

  final PassengerApiClient _client;

  Future<PassengerNoticesSnapshot> fetchInbox() async {
    try {
      final res = await _client.getAuthWithRetry<Map<String, dynamic>>(
        path: '/auth/notices',
        flow: 'passenger_notices',
      );
      final data = PassengerApiClient.parseSuccessData(res.data);
      final raw = data['items'];
      final items = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => PassengerNoticeItem.fromJson(Map<String, dynamic>.from(e)))
                .where((e) => e.id.isNotEmpty)
                .toList()
          : const <PassengerNoticeItem>[];
      final unread = data['unreadCount'];
      return PassengerNoticesSnapshot(
        items: items,
        unreadCount: unread is num
            ? unread.toInt()
            : items.where((e) => e.unread).length,
      );
    } catch (_) {
      return const PassengerNoticesSnapshot();
    }
  }

  Future<void> markRead(String campaignId) async {
    if (campaignId.trim().isEmpty) return;
    try {
      await _client.postAuthWithRetry<Map<String, dynamic>>(
        path: '/auth/notices/${campaignId.trim()}/read',
        flow: 'passenger_notices_read',
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _client.postAuthWithRetry<Map<String, dynamic>>(
        path: '/auth/notices/read-all',
        flow: 'passenger_notices_read_all',
      );
    } catch (_) {}
  }
}

final passengerNoticesUnreadProvider = FutureProvider<int>((ref) async {
  final snap = await ref.read(passengerNoticesRepositoryProvider).fetchInbox();
  return snap.unreadCount;
});
