import 'package:careconnect_mobile/features/profile/domain/current_user.dart';

class AuthSession {
  const AuthSession({required this.user, required this.accessToken});

  final CurrentUser user;
  final String accessToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final token = json['accessToken'];
    if (data is! Map<String, dynamic> || token is! String || token.isEmpty) {
      throw const FormatException('Invalid authentication response');
    }
    return AuthSession(user: CurrentUser.fromJson(data), accessToken: token);
  }
}
