enum CareNotificationType {
  appointment,
  reminder,
  cancellation,
  checkIn,
  general;

  static CareNotificationType fromApi(String value) {
    final normalized = value.toUpperCase();
    if (normalized.contains('CANCEL')) return cancellation;
    if (normalized.contains('REMINDER')) return reminder;
    if (normalized.contains('CHECK_IN') || normalized.contains('CHECKIN')) {
      return checkIn;
    }
    if (normalized.contains('APPOINTMENT') ||
        normalized.contains('BOOKING') ||
        normalized.contains('CONFIRM')) {
      return appointment;
    }
    return general;
  }
}

class CareNotification {
  const CareNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory CareNotification.fromJson(Map<String, dynamic> json) =>
      CareNotification(
        id: json['id'].toString(),
        type: CareNotificationType.fromApi(json['type'] as String? ?? ''),
        title: json['title'] as String? ?? 'CareConnect update',
        message: json['message'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String).toLocal(),
      );

  final String id;
  final CareNotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  CareNotification copyWith({bool? isRead, DateTime? readAt}) =>
      CareNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );
}
