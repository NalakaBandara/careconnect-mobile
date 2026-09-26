import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum CareDirectoryMode { online, cached, unavailable }

@immutable
class CareDirectoryStatus {
  const CareDirectoryStatus({required this.mode, this.cachedAt});

  const CareDirectoryStatus.online()
    : mode = CareDirectoryMode.online,
      cachedAt = null;

  final CareDirectoryMode mode;
  final DateTime? cachedAt;

  bool get shouldShowBanner => mode != CareDirectoryMode.online;
}

abstract interface class CareDirectoryStatusSource {
  ValueListenable<CareDirectoryStatus> get directoryStatus;
}

class CareDirectoryCacheEntry {
  const CareDirectoryCacheEntry({required this.cachedAt, required this.data});

  final DateTime cachedAt;
  final Object? data;
}

abstract interface class CareDirectoryCacheStore {
  Future<CareDirectoryCacheEntry?> read(String key);

  Future<void> write(String key, Object? data, DateTime cachedAt);
}

class SecureCareDirectoryCacheStore implements CareDirectoryCacheStore {
  SecureCareDirectoryCacheStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'careconnect_public_directory_v1_';
  final FlutterSecureStorage _storage;

  @override
  Future<CareDirectoryCacheEntry?> read(String key) async {
    final value = await _storage.read(key: '$_prefix$key');
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
      if (cachedAt == null || !decoded.containsKey('data')) return null;
      return CareDirectoryCacheEntry(cachedAt: cachedAt, data: decoded['data']);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? data, DateTime cachedAt) =>
      _storage.write(
        key: '$_prefix$key',
        value: jsonEncode({
          'cachedAt': cachedAt.toUtc().toIso8601String(),
          'data': data,
        }),
      );
}
