class AppConfig {
  const AppConfig._();

  /// Override with:
  /// --dart-define=CARECONNECT_API_BASE_URL=http://host:port
  static const apiBaseUrl = String.fromEnvironment(
    'CARECONNECT_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

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
