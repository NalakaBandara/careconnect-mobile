import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/notifications/data/notifications_preview_data.dart';
import 'package:careconnect_mobile/features/notifications/data/notifications_repository.dart';
import 'package:careconnect_mobile/features/notifications/domain/care_notification.dart';
import 'package:flutter/material.dart';

enum _InboxFilter { all, unread }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.repository});

  final NotificationsRepository? repository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<CareNotification> _notifications;
  _InboxFilter _filter = _InboxFilter.all;
  bool _isLoading = false;
  String? _error;

  bool get _isPreview => widget.repository == null;
  int get _unreadCount => _notifications.where((item) => !item.isRead).length;
  List<CareNotification> get _visibleNotifications =>
      _filter == _InboxFilter.all
      ? _notifications
      : _notifications.where((item) => !item.isRead).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _notifications = _isPreview
        ? List.of(NotificationsPreviewData.notifications)
        : <CareNotification>[];
    if (!_isPreview) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notifications = await widget.repository!.getNotifications();
      if (!mounted) return;
      setState(() => _notifications = notifications);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'We could not load your notifications. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(CareNotification notification) async {
    if (notification.isRead) return;
    final index = _notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index == -1) return;

    final previous = _notifications[index];
    setState(() {
      _notifications[index] = previous.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    });

    if (_isPreview) return;
    try {
      final updated = await widget.repository!.setRead(
        notification.id,
        isRead: true,
      );
      if (!mounted) return;
      final currentIndex = _notifications.indexWhere(
        (item) => item.id == notification.id,
      );
      if (currentIndex != -1) {
        setState(() => _notifications[currentIndex] = updated);
      }
    } catch (_) {
      if (!mounted) return;
      final currentIndex = _notifications.indexWhere(
        (item) => item.id == notification.id,
      );
      if (currentIndex != -1) {
        setState(() => _notifications[currentIndex] = previous);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this notification.')),
      );
    }
  }

  Future<void> _openNotification(CareNotification notification) async {
    await _markRead(notification);
    if (!mounted) return;
    final current = _notifications.firstWhere(
      (item) => item.id == notification.id,
      orElse: () => notification,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(notification: current),
      ),
    );
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((item) => !item.isRead).toList();
    for (final notification in unread) {
      await _markRead(notification);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        if (_unreadCount > 0)
          TextButton(
            key: const Key('mark-all-notifications-read'),
            onPressed: _markAllRead,
            child: const Text('Mark all read'),
          ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your care updates',
                  key: const Key('notifications-title'),
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 7),
                Text(
                  _unreadCount == 0
                      ? 'You are all caught up.'
                      : '$_unreadCount ${_unreadCount == 1 ? 'update' : 'updates'} waiting for you.',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    _FilterChip(
                      key: const Key('notifications-all-filter'),
                      label: 'All',
                      selected: _filter == _InboxFilter.all,
                      onTap: () => setState(() => _filter = _InboxFilter.all),
                    ),
                    const SizedBox(width: 9),
                    _FilterChip(
                      key: const Key('notifications-unread-filter'),
                      label: 'Unread $_unreadCount',
                      selected: _filter == _InboxFilter.unread,
                      onTap: () =>
                          setState(() => _filter = _InboxFilter.unread),
                    ),
                    if (_isPreview) ...[const Spacer(), const _PreviewBadge()],
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    ),
  );

  Widget _buildContent() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _notifications.isEmpty) {
      return _InboxMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Updates are taking a break',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_visibleNotifications.isEmpty) {
      return _InboxMessage(
        icon: _filter == _InboxFilter.unread
            ? Icons.done_all_rounded
            : Icons.notifications_none_rounded,
        title: _filter == _InboxFilter.unread
            ? 'Everything is read'
            : 'No notifications yet',
        message: _filter == _InboxFilter.unread
            ? 'New care updates will appear here when they arrive.'
            : 'Appointment confirmations and reminders will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _isPreview
          ? () async => Future<void>.delayed(const Duration(milliseconds: 250))
          : _load,
      child: ListView.separated(
        key: const Key('notifications-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 34),
        itemCount: _visibleNotifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 11),
        itemBuilder: (_, index) {
          final notification = _visibleNotifications[index];
          return _NotificationCard(
            key: ValueKey('notification-${notification.id}'),
            notification: notification,
            onTap: () => _openNotification(notification),
          );
        },
      ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notification});

  final CareNotification notification;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(notification.type);
    return Scaffold(
      appBar: AppBar(title: const Text('Notification detail')),
      body: ListView(
        key: const Key('notification-detail-screen'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(style.icon, color: style.color, size: 29),
          ),
          const SizedBox(height: 25),
          Text(
            notification.title,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 31),
          ),
          const SizedBox(height: 10),
          Text(
            _fullDate(notification.createdAt),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              notification.message,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'You can manage related visits from the Appointments tab.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final CareNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(notification.type);
    return Material(
      color: notification.isRead ? Colors.white : const Color(0xFFF0FAF7),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border
                  : AppColors.accent.withValues(alpha: 0.55),
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            key: ValueKey('unread-${notification.id}'),
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5, left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _relativeDate(notification.createdAt),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.primary : Colors.white,
    borderRadius: BorderRadius.circular(99),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.lilacSoft,
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      'PREVIEW',
      style: TextStyle(
        color: Color(0xFF7957C8),
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    ),
  );
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.mintSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

({IconData icon, Color color, Color background}) _styleFor(
  CareNotificationType type,
) => switch (type) {
  CareNotificationType.appointment => (
    icon: Icons.event_available_rounded,
    color: AppColors.primary,
    background: AppColors.mintSoft,
  ),
  CareNotificationType.reminder => (
    icon: Icons.alarm_rounded,
    color: const Color(0xFF9A6810),
    background: const Color(0xFFFFF1D2),
  ),
  CareNotificationType.cancellation => (
    icon: Icons.event_busy_rounded,
    color: const Color(0xFFB84C4C),
    background: const Color(0xFFFFE8E3),
  ),
  CareNotificationType.checkIn => (
    icon: Icons.qr_code_rounded,
    color: const Color(0xFF5276D8),
    background: AppColors.blueSoft,
  ),
  CareNotificationType.general => (
    icon: Icons.favorite_outline_rounded,
    color: const Color(0xFF7957C8),
    background: AppColors.lilacSoft,
  ),
};

String _relativeDate(DateTime date) {
  final current = DateTime.now();
  final now = DateTime(current.year, current.month, current.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = now.difference(day).inDays;
  final time = _time(date);
  if (difference == 0) return 'Today · $time';
  if (difference == 1) return 'Yesterday · $time';
  return '${date.day} ${_months[date.month - 1]} · $time';
}

String _fullDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year} · ${_time(date)}';

String _time(DateTime date) {
  final hour = date.hour == 0
      ? 12
      : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
