import 'dart:convert';
import 'dart:io';

import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'concurrent unauthorized responses expire a session only once',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) async {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'The access token has expired',
            },
          }),
        );
        await request.response.close();
      });

      var expirationCalls = 0;
      final client = ApiClient(
        accessTokenProvider: () async => 'expired-test-token',
        onUnauthorized: () async {
          expirationCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        },
        apiUriBuilder: (path, queryParameters) => Uri(
          scheme: 'http',
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
          path: path,
          queryParameters: queryParameters?.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        ),
      );
      addTearDown(client.close);

      Future<void> send(String path) async {
        try {
          await client.get(path);
          fail('The request should have returned 401.');
        } on ApiException catch (error) {
          expect(error.statusCode, HttpStatus.unauthorized);
        }
      }

      await Future.wait([send('/one'), send('/two'), send('/three')]);

      expect(expirationCalls, 1);
    },
  );
}
