class AppConfig {
  const AppConfig._();

  /// Override with:
  /// --dart-define=CARECONNECT_API_BASE_URL=http://host:port
  static const apiBaseUrl = String.fromEnvironment(
    'CARECONNECT_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const auth0Domain = String.fromEnvironment('CARECONNECT_AUTH0_DOMAIN');
  static const auth0ClientId = String.fromEnvironment(
    'CARECONNECT_AUTH0_CLIENT_ID',
  );
  static const auth0Audience = String.fromEnvironment(
    'CARECONNECT_AUTH0_AUDIENCE',
  );
  static const auth0Scheme = 'careconnect';

  static bool get isAuth0Configured =>
      auth0Domain.isNotEmpty &&
      auth0ClientId.isNotEmpty &&
      auth0Audience.isNotEmpty;

  static Uri apiUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$apiBaseUrl$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) return uri;

    return uri.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}
