import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/features/auth/domain/auth_session.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> delete();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? FlutterSecureStorage();

  static const _accessTokenKey = 'careconnect_access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _accessTokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _accessTokenKey);
}

abstract interface class AuthDataSource {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  });

  Future<String?> accessToken();

  Future<void> logout();
}

class AuthService implements AuthDataSource {
  AuthService({TokenStore? tokenStore, ApiClient? publicClient})
    : _tokenStore = tokenStore ?? SecureTokenStore(),
      _publicClient =
          publicClient ?? ApiClient(accessTokenProvider: _noAccessToken) {
    _protectedClient = ApiClient(accessTokenProvider: _tokenStore.read);
  }

  final TokenStore _tokenStore;
  final ApiClient _publicClient;
  late final ApiClient _protectedClient;

  static Future<String?> _noAccessToken() async => null;

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _protectedClient.get(ApiEndpoints.currentUser);
      if (response case {'data': final Map<String, dynamic> data}) {
        return AuthSession(
          user: CurrentUser.fromJson(data),
          accessToken: token,
        );
      }
      throw const FormatException('Missing user data');
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 404) {
        await _tokenStore.delete();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _authenticate(
    ApiEndpoints.login,
    body: {'email': email.trim().toLowerCase(), 'password': password},
  );

  @override
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) => _authenticate(
    ApiEndpoints.register,
    body: {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    },
  );

  Future<AuthSession> _authenticate(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _publicClient.post(endpoint, body: body);
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid authentication response');
    }
    final session = AuthSession.fromJson(response);
    await _tokenStore.write(session.accessToken);
    return session;
  }

  @override
  Future<String?> accessToken() => _tokenStore.read();

  @override
  Future<void> logout() => _tokenStore.delete();
}
