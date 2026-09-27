import 'dart:convert';

import 'package:flutter/foundation.dart';

abstract final class ApiLogger {
  static const _redactedValue = '<redacted>';
  static const _maxPayloadLength = 4000;

  static const _sensitiveKeys = {
    'authorization',
    'accesstoken',
    'refreshtoken',
    'idtoken',
    'token',
    'password',
    'confirmpassword',
    'currentpassword',
    'newpassword',
    'email',
    'phone',
    'phonenumber',
    'dateofbirth',
    'firstname',
    'lastname',
    'fullname',
    'address',
    'profilephoto',
    'reason',
    'notes',
    'message',
    'userid',
    'patientid',
    'subject',
    'sub',
  };

  static void request({
    required String method,
    required Uri uri,
    Object? body,
  }) {
    if (!kDebugMode) return;
    debugPrint('[CareConnect API] → $method ${_safeUri(uri)}');
    if (body != null) {
      debugPrint('[CareConnect API]   request: ${formatPayload(body)}');
    }
  }

  static void response({
    required String method,
    required Uri uri,
    required int statusCode,
    required Duration elapsed,
    Object? body,
  }) {
    if (!kDebugMode) return;
    final result = statusCode >= 200 && statusCode < 300 ? '✓' : '✕';
    debugPrint(
      '[CareConnect API] $result $statusCode $method ${_safeUri(uri)} '
      '(${elapsed.inMilliseconds}ms)',
    );
    if (body != null) {
      debugPrint(
        '[CareConnect API]   response:\n${formatPayload(body, pretty: true)}',
      );
    }
  }

  static void failure({
    required String method,
    required Uri uri,
    required Duration elapsed,
    required Object error,
    String? safeMessage,
  }) {
    if (!kDebugMode) return;
    final detail = safeMessage == null ? '' : ' · $safeMessage';
    debugPrint(
      '[CareConnect API] ✕ $method ${_safeUri(uri)} '
      '(${elapsed.inMilliseconds}ms) ${error.runtimeType}$detail',
    );
  }

  @visibleForTesting
  static Object? sanitize(Object? value, {String? key}) {
    if (key != null && _isSensitive(key)) return _redactedValue;
    if (value is Map) {
      return value.map<String, Object?>((rawKey, rawValue) {
        final field = rawKey.toString();
        return MapEntry(field, sanitize(rawValue, key: field));
      });
    }
    if (value is Iterable) {
      return value.map((item) => sanitize(item)).toList(growable: false);
    }
    return value;
  }

  static String formatPayload(Object? payload, {bool pretty = false}) {
    final sanitized = sanitize(payload);
    final formatted = pretty
        ? const JsonEncoder.withIndent('  ').convert(sanitized)
        : jsonEncode(sanitized);
    if (formatted.length <= _maxPayloadLength) return formatted;
    return '${formatted.substring(0, _maxPayloadLength)}…<truncated>';
  }

  static String _safeUri(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri.toString();
    final safeQuery = uri.queryParameters.map(
      (key, value) => MapEntry(key, _isSensitive(key) ? _redactedValue : value),
    );
    return uri.replace(queryParameters: safeQuery).toString();
  }

  static bool _isSensitive(String key) {
    final normalized = key.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toLowerCase();
    return _sensitiveKeys.contains(normalized) ||
        normalized.endsWith('token') ||
        normalized.contains('password');
  }
}
