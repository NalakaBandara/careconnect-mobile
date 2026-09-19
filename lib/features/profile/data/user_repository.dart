import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';

class UserRepository {
  const UserRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CurrentUser> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.currentUser);
    if (response case {'data': final Map<String, dynamic> data}) {
      return CurrentUser.fromJson(data);
    }
    throw const FormatException('Missing user data');
  }

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
