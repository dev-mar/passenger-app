class SupportTicketSummary {
  const SupportTicketSummary({
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

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) {
    return SupportTicketSummary(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? 'SUP-NA',
      category: json['category']?.toString() ?? 'general',
      subject: json['subject']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
    );
  }
}

class SupportTicketDetail {
  const SupportTicketDetail({
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
  final List<SupportTicketEvent> events;
  final List<SupportTicketAttachment> attachments;

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final eventsRaw = json['events'];
    final atRaw = json['attachments'];
    return SupportTicketDetail(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? 'SUP-NA',
      category: json['category']?.toString() ?? 'general',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'normal',
      events: eventsRaw is List
          ? eventsRaw
                .whereType<Map>()
                .map(
                  (e) => SupportTicketEvent.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
      attachments: atRaw is List
          ? atRaw
                .whereType<Map>()
                .map(
                  (e) => SupportTicketAttachment.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class SupportTicketEvent {
  const SupportTicketEvent({
    required this.actorType,
    required this.eventType,
    required this.message,
  });

  final String actorType;
  final String eventType;
  final String message;

  factory SupportTicketEvent.fromJson(Map<String, dynamic> json) {
    return SupportTicketEvent(
      actorType: json['actor_type']?.toString() ?? 'system',
      eventType: json['event_type']?.toString() ?? 'event',
      message: json['message']?.toString() ?? '',
    );
  }
}

class SupportTicketAttachment {
  const SupportTicketAttachment({
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.previewUrl,
  });

  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String previewUrl;

  factory SupportTicketAttachment.fromJson(Map<String, dynamic> json) {
    return SupportTicketAttachment(
      fileName: json['file_name']?.toString() ?? 'archivo',
      contentType:
          json['content_type']?.toString() ?? 'application/octet-stream',
      sizeBytes: int.tryParse('${json['size_bytes']}') ?? 0,
      previewUrl: json['preview_url']?.toString() ?? '',
    );
  }
}

class SupportTicketPresignResult {
  const SupportTicketPresignResult({
    required this.uploadUrl,
    required this.storageKey,
  });

  final String uploadUrl;
  final String storageKey;
}
