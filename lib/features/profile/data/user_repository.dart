import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';

abstract interface class UserDataSource {
  Future<CurrentUser> getCurrentUser();

  Future<CurrentUser> updateCurrentUser(CurrentUser user);

  Future<void> anonymiseUser(String userId);
}

class UserRepository implements UserDataSource {
  const UserRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CurrentUser> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.currentUser);
    if (response case {'data': final Map<String, dynamic> data}) {
      return CurrentUser.fromJson(data);
    }
    throw const FormatException('Missing user data');
  }

  @override
  Future<CurrentUser> updateCurrentUser(CurrentUser user) async {
    final response = await _apiClient.put(
      ApiEndpoints.currentUser,
      body: user.toUpdateJson(),
    );
    if (response case {'data': final Map<String, dynamic> data}) {
      return CurrentUser.fromJson(data);
    }
    throw const FormatException('Missing user data');
  }

  @override
  Future<void> anonymiseUser(String userId) async {
    final response = await _apiClient.patch(ApiEndpoints.anonymiseUser(userId));
    if (response case {
      'data': {'status': final String status},
    } when status.toUpperCase() == 'ANONYMISED') {
      return;
    }
    throw const FormatException('Missing anonymisation confirmation');
  }
}
