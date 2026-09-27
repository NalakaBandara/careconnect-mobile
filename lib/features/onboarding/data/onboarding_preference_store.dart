import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class OnboardingPreferenceStore {
  Future<bool> hasCompleted();

  Future<void> markCompleted();
}

class SecureOnboardingPreferenceStore implements OnboardingPreferenceStore {
  SecureOnboardingPreferenceStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _completedKey = 'careconnect_onboarding_completed';
  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasCompleted() async =>
      await _storage.read(key: _completedKey) == 'true';

  @override
  Future<void> markCompleted() =>
      _storage.write(key: _completedKey, value: 'true');
}
