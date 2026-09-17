import 'dart:convert';
import 'dart:io';

import 'package:careconnect_mobile/core/config/app_config.dart';
import 'package:careconnect_mobile/core/network/api_exception.dart';

typedef AccessTokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({
    required AccessTokenProvider accessTokenProvider,
    HttpClient? httpClient,
  }) : _accessTokenProvider = accessTokenProvider,
       _httpClient = httpClient ?? HttpClient();

  final AccessTokenProvider _accessTokenProvider;
  final HttpClient _httpClient;

  Future<Object?> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _send('GET', path, queryParameters: queryParameters);

  Future<Object?> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Object?> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<Object?> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    try {
      final request = await _httpClient.openUrl(
        method,
        AppConfig.apiUri(path, queryParameters),
      );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      final accessToken = await _accessTokenProvider();
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $accessToken',
        );
      }
      if (body != null) request.write(jsonEncode(body));

      final response = await request.close();
      final responseText = await utf8.decoder.bind(response).join();
      final decodedBody = responseText.isEmpty
          ? null
          : jsonDecode(responseText);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _errorMessage(decodedBody),
          statusCode: response.statusCode,
          responseBody: decodedBody,
        );
      }
      return decodedBody;
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException(
        message: 'Unable to reach CareConnect: ${error.message}',
      );
    } on FormatException {
      throw const ApiException(
        message: 'The server returned an invalid response.',
      );
    }
  }

  String _errorMessage(Object? body) {
    if (body case {'message': final String message}) return message;
    if (body case {'error': final String error}) return error;
    if (body case {'error': {'message': final String message}}) return message;
    return 'The request could not be completed.';
  }

  void close() => _httpClient.close(force: true);
}
