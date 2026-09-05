class TripCancelReasonItem {
  const TripCancelReasonItem({
    required this.code,
    required this.label,
    required this.confirmText,
    required this.requiresNote,
    this.sortOrder = 0,
  });

  final String code;
  final String label;
  final String confirmText;
  final bool requiresNote;
  final int sortOrder;

  factory TripCancelReasonItem.fromJson(Map<String, dynamic> json) {
    return TripCancelReasonItem(
      code: json['code']?.toString().trim() ?? '',
      label: json['label']?.toString().trim() ?? '',
      confirmText: json['confirmText']?.toString().trim() ??
          json['confirm_text']?.toString().trim() ??
          '',
      requiresNote: json['requiresNote'] == true || json['requires_note'] == true,
      sortOrder: json['sortOrder'] is num
          ? (json['sortOrder'] as num).toInt()
          : (json['sort_order'] is num ? (json['sort_order'] as num).toInt() : 0),
    );
  }
}

class TripCancelReasonChoice {
  const TripCancelReasonChoice({required this.code, this.note});

  final String code;
  final String? note;
}

bool passengerTripCanCancelAssigned(String? status) {
  final s = status?.toLowerCase();
  return s == 'accepted' ||
      s == 'arrived' ||
      s == 'started' ||
      s == 'in_trip';
}
