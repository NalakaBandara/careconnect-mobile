# CareConnect Mobile

Flutter mobile client for the personal CareConnect project.

## Local configuration

No credentials or environment-specific values are committed to this project.
Use CareConnect-specific values only.

```bash
flutter run \
  --dart-define=CARECONNECT_API_BASE_URL=http://10.0.2.2:3000
```

Without an override, the app uses the CareConnect Render API at
`https://careconnect-api-sb5u.onrender.com`. Use the command above only when a
CareConnect backend is running locally on port 3000.

Authentication uses the CareConnect API email/password endpoints. The signed
access token is stored using the platform's encrypted secure storage. Never add
a server JWT secret, password, or access token to this repository or to a
`--dart-define` value.

## Live appointment journey

The opt-in live test verifies the complete deployed API journey: patient
booking, admin confirmation, backend QR generation, reception check-in,
patient check-in visibility, completion, and status history. It creates and
completes a real appointment, so use CareConnect test accounts only.

Keep credentials outside source control. Export these values in the current
terminal without adding them to a file in this repository:

```bash
export CARECONNECT_PATIENT_EMAIL='...'
export CARECONNECT_PATIENT_PASSWORD='...'
export CARECONNECT_ADMIN_EMAIL='...'
export CARECONNECT_ADMIN_PASSWORD='...'
export CARECONNECT_RUN_LIVE_E2E=true
flutter test test/live_api_journey_test.dart
```

Normal `flutter test` runs skip this mutation-enabled test unless the explicit
flag and credentials are present. If a run fails after creating an
appointment, the test attempts to cancel that appointment before exiting.

## Debug API logs

API requests are printed automatically in debug builds:

```text
[CareConnect API] → GET http://10.0.2.2:3000/api/v1/users/me
[CareConnect API] ✓ 200 GET http://10.0.2.2:3000/api/v1/users/me (142ms)
```

Request and response payloads are sanitized before printing. Authentication
tokens, passwords, and personal or health-related fields are redacted. API
logging is disabled automatically in profile and release builds.

## Offline public directory

The latest successfully loaded public specialties, doctors, and clinics are
stored locally for read-only access when the API cannot be reached. Home and
Find Care display an offline banner with the cache timestamp. Live availability,
booking, appointments, patient profiles, and health-related information are not
cached and continue to require a backend connection.

## Mobile application identity

- Application name: `CareConnect`
- Android application ID: `com.chamindu.careconnect`
- iOS bundle identifier: `com.chamindu.careconnect`

The checked-in app icons and native launch screens use the CareConnect brand
mark. Store-distribution signing credentials are intentionally not committed;
configure them locally with a personal Apple/Google developer account.

For a physical iPhone, keep `DEVELOPMENT_TEAM` out of the committed Xcode
project and run `flutter config --select-ios-signing-settings` to select a
personal Apple Development identity before `flutter run`. If the wrong identity
was previously saved, clear it first with
`flutter config --clear-ios-signing-settings`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
