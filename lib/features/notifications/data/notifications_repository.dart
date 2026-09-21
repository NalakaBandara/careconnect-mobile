import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/notifications/domain/care_notification.dart';

abstract interface class NotificationsDataSource {
  Future<List<CareNotification>> getNotifications({bool? isRead});

  Future<CareNotification> setRead(String id, {required bool isRead});
}

class NotificationsRepository implements NotificationsDataSource {
  const NotificationsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<CareNotification>> getNotifications({bool? isRead}) async {
    final response = await _client.get(
      ApiEndpoints.notifications,
      queryParameters: {'isRead': ?isRead},
    );
    final body = response as Map<String, dynamic>;
    return (body['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CareNotification.fromJson)
        .toList(growable: false);
  }

  @override
  Future<CareNotification> setRead(String id, {required bool isRead}) async {
    final response = await _client.patch(
      ApiEndpoints.notificationRead(id),
      body: {'isRead': isRead},
    );
    if (response case {'data': final Map<String, dynamic> data}) {
      return CareNotification.fromJson(data);
    }
    return CareNotification.fromJson(response as Map<String, dynamic>);
  }
}
