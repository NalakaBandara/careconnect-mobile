import 'dart:convert';
import 'dart:io';

import 'package:careconnect_mobile/core/config/app_config.dart';
import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/network/api_logger.dart';

typedef AccessTokenProvider = Future<String?> Function();
typedef UnauthorizedHandler = Future<void> Function();
typedef ApiUriBuilder =
    Uri Function(String path, Map<String, dynamic>? queryParameters);

class ApiClient {
  ApiClient({
    required AccessTokenProvider accessTokenProvider,
    UnauthorizedHandler? onUnauthorized,
    ApiUriBuilder? apiUriBuilder,
    HttpClient? httpClient,
  }) : _accessTokenProvider = accessTokenProvider,
       _onUnauthorized = onUnauthorized,
       _apiUriBuilder = apiUriBuilder ?? AppConfig.apiUri,
       _httpClient = httpClient ?? HttpClient();

  final AccessTokenProvider _accessTokenProvider;
  final UnauthorizedHandler? _onUnauthorized;
  final ApiUriBuilder _apiUriBuilder;
  final HttpClient _httpClient;
  bool _didNotifyUnauthorized = false;

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
    final uri = _apiUriBuilder(path, queryParameters);
    final stopwatch = Stopwatch()..start();
    ApiLogger.request(method: method, uri: uri, body: body);

    try {
      final request = await _httpClient.openUrl(method, uri);
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

      ApiLogger.response(
        method: method,
        uri: uri,
        statusCode: response.statusCode,
        elapsed: stopwatch.elapsed,
        body: decodedBody,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == HttpStatus.unauthorized &&
            !_didNotifyUnauthorized) {
          _didNotifyUnauthorized = true;
          try {
            await _onUnauthorized?.call();
          } catch (_) {
            // Session cleanup must not hide the original API failure.
          }
        }
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
      ApiLogger.failure(
        method: method,
        uri: uri,
        elapsed: stopwatch.elapsed,
        error: error,
        safeMessage: error.message,
      );
      throw ApiException(
        message: 'Unable to reach CareConnect: ${error.message}',
      );
    } on FormatException catch (error) {
      ApiLogger.failure(
        method: method,
        uri: uri,
        elapsed: stopwatch.elapsed,
        error: error,
        safeMessage: 'Invalid JSON response',
      );
      throw const ApiException(
        message: 'The server returned an invalid response.',
      );
    } catch (error) {
      ApiLogger.failure(
        method: method,
        uri: uri,
        elapsed: stopwatch.elapsed,
        error: error,
      );
      rethrow;
    } finally {
      stopwatch.stop();
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
