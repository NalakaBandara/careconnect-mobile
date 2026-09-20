import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';

abstract interface class UserDataSource {
  Future<CurrentUser> getCurrentUser();

  Future<CurrentUser> updateCurrentUser(CurrentUser user);
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
}
