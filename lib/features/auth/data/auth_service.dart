import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:careconnect_mobile/core/config/app_config.dart';
import 'package:careconnect_mobile/features/auth/domain/auth_session.dart';

class AuthConfigurationException implements Exception {
  const AuthConfigurationException();
}

class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

class AuthService {
  AuthService() {
    if (!AppConfig.isAuth0Configured) {
      throw const AuthConfigurationException();
    }
    _auth0 = Auth0(AppConfig.auth0Domain, AppConfig.auth0ClientId);
  }

  late final Auth0 _auth0;

  Future<AuthSession?> restoreSession() async {
    final hasCredentials = await _auth0.credentialsManager.hasValidCredentials(
      minTtl: 60,
    );
    if (!hasCredentials) return null;

    final credentials = await _auth0.credentialsManager.credentials(minTtl: 60);
    return _toSession(credentials);
  }

  Future<AuthSession> login({bool signUp = false}) async {
    try {
      final credentials = await _auth0
          .webAuthentication(scheme: AppConfig.auth0Scheme)
          .login(
            audience: AppConfig.auth0Audience,
            scopes: const {'openid', 'profile', 'email', 'offline_access'},
            parameters: signUp ? const {'screen_hint': 'signup'} : const {},
          );
      return _toSession(credentials);
    } on WebAuthenticationException catch (error) {
      if (error.isUserCancelledException) throw const AuthCancelledException();
      rethrow;
    }
  }

  Future<String?> accessToken() async {
    final hasCredentials = await _auth0.credentialsManager.hasValidCredentials(
      minTtl: 60,
    );
    if (!hasCredentials) return null;
    final credentials = await _auth0.credentialsManager.credentials(minTtl: 60);
    return credentials.accessToken;
  }

  Future<void> logout() =>
      _auth0.webAuthentication(scheme: AppConfig.auth0Scheme).logout();

  AuthSession _toSession(Credentials credentials) => AuthSession(
    email: credentials.user.email,
    displayName: credentials.user.name,
    pictureUrl: credentials.user.pictureUrl,
  );
}
