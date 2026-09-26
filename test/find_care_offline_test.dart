import 'dart:io';

import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/find_care/data/care_directory_cache.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_repository.dart';
import 'package:careconnect_mobile/features/find_care/presentation/care_directory_status_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses saved public directory data when the API is offline', () async {
    final cache = _MemoryDirectoryCacheStore();
    final onlineClient = _DirectoryApiClient(isOnline: true);
    final onlineRepository = FindCareRepository(
      onlineClient,
      cacheStore: cache,
    );

    final specialties = await onlineRepository.getSpecialties();
    final doctors = await onlineRepository.getDoctors();

    expect(specialties.single.name, 'Cardiology');
    expect(doctors.single.displayName, 'Dr. Nadeesha Fernando');
    expect(cache.entries.keys, {'specialties', 'doctors_and_clinics'});
    expect(
      onlineRepository.directoryStatus.value.mode,
      CareDirectoryMode.online,
    );

    onlineRepository.dispose();
    onlineClient.close();

    final offlineClient = _DirectoryApiClient(isOnline: false);
    final offlineRepository = FindCareRepository(
      offlineClient,
      cacheStore: cache,
    );

    final cachedSpecialties = await offlineRepository.getSpecialties();
    final cachedDoctors = await offlineRepository.getDoctors(specialtyId: '12');

    expect(cachedSpecialties.single.name, 'Cardiology');
    expect(cachedDoctors.single.primaryClinic, 'Harbour Medical Centre');
    expect(
      offlineRepository.directoryStatus.value.mode,
      CareDirectoryMode.cached,
    );
    expect(offlineRepository.directoryStatus.value.cachedAt, isNotNull);

    offlineRepository.dispose();
    offlineClient.close();
  });

  test('reports unavailable when offline without saved data', () async {
    final client = _DirectoryApiClient(isOnline: false);
    final repository = FindCareRepository(
      client,
      cacheStore: _MemoryDirectoryCacheStore(),
    );

    await expectLater(
      repository.getSpecialties(),
      throwsA(isA<SocketException>()),
    );
    expect(
      repository.directoryStatus.value.mode,
      CareDirectoryMode.unavailable,
    );

    repository.dispose();
    client.close();
  });

  testWidgets('explains when saved directory content is shown', (tester) async {
    final source = _DirectoryStatusSource(
      CareDirectoryStatus(
        mode: CareDirectoryMode.cached,
        cachedAt: DateTime(2026, 9, 26, 20, 30),
      ),
    );
    addTearDown(source.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: CareDirectoryStatusBanner(source: source)),
      ),
    );

    expect(
      find.byKey(const Key('care-directory-offline-banner')),
      findsOneWidget,
    );
    expect(find.text('Offline directory'), findsOneWidget);
    expect(
      find.textContaining('Live availability and booking'),
      findsOneWidget,
    );
  });
}

class _DirectoryApiClient extends ApiClient {
  _DirectoryApiClient({required this.isOnline})
    : super(accessTokenProvider: _noToken);

  final bool isOnline;

  static Future<String?> _noToken() async => null;

  @override
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!isOnline) throw const SocketException('Offline test');
    if (path == ApiEndpoints.specialties) {
      return {
        'data': [
          {'id': '12', 'name': 'Cardiology', 'description': 'Heart care'},
        ],
      };
    }
    if (path == ApiEndpoints.doctors) {
      return {
        'data': [
          {
            'id': '22',
            'firstName': 'Nadeesha',
            'lastName': 'Fernando',
            'isVerified': true,
            'specialties': [
              {'id': '12', 'name': 'Cardiology'},
            ],
            'clinics': [
              {'id': '7', 'name': 'Harbour Medical Centre'},
            ],
          },
        ],
      };
    }
    if (path == ApiEndpoints.clinics) {
      return {
        'data': [
          {'id': '7', 'name': 'Harbour Medical Centre', 'city': 'Colombo'},
        ],
      };
    }
    throw StateError('Unexpected test path: $path');
  }
}

class _MemoryDirectoryCacheStore implements CareDirectoryCacheStore {
  final Map<String, CareDirectoryCacheEntry> entries = {};

  @override
  Future<CareDirectoryCacheEntry?> read(String key) async => entries[key];

  @override
  Future<void> write(String key, Object? data, DateTime cachedAt) async {
    entries[key] = CareDirectoryCacheEntry(cachedAt: cachedAt, data: data);
  }
}

class _DirectoryStatusSource implements CareDirectoryStatusSource {
  _DirectoryStatusSource(CareDirectoryStatus status)
    : _status = ValueNotifier(status);

  final ValueNotifier<CareDirectoryStatus> _status;

  @override
  ValueListenable<CareDirectoryStatus> get directoryStatus => _status;

  void dispose() => _status.dispose();
}
