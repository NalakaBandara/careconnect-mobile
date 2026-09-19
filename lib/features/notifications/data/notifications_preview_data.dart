import 'package:careconnect_mobile/features/notifications/domain/care_notification.dart';

abstract final class NotificationsPreviewData {
  static final notifications = <CareNotification>[
    CareNotification(
      id: 'notification-1',
      type: CareNotificationType.appointment,
      title: 'Appointment confirmed',
      message:
          'Your visit with Dr. Arun Mehta is confirmed for Monday at 9:30 AM.',
      isRead: false,
      createdAt: DateTime(2026, 9, 19, 8, 45),
    ),
    CareNotification(
      id: 'notification-2',
      type: CareNotificationType.reminder,
      title: 'A reminder for your visit',
      message:
          'Your appointment is tomorrow. Arrive 10 minutes early for a smooth check-in.',
      isRead: false,
      createdAt: DateTime(2026, 9, 18, 17, 30),
    ),
    CareNotification(
      id: 'notification-3',
      type: CareNotificationType.checkIn,
      title: 'Check-in is ready',
      message:
          'Your secure check-in option will be available from your appointment details.',
      isRead: true,
      createdAt: DateTime(2026, 9, 17, 10, 15),
      readAt: DateTime(2026, 9, 17, 10, 30),
    ),
    CareNotification(
      id: 'notification-4',
      type: CareNotificationType.general,
      title: 'Welcome to CareConnect',
      message:
          'Your profile is ready. You can now discover professionals and manage visits in one place.',
      isRead: true,
      createdAt: DateTime(2026, 9, 15, 14, 0),
      readAt: DateTime(2026, 9, 15, 14, 5),
    ),
  ];
}
