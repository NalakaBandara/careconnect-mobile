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

## Debug API logs

API requests are printed automatically in debug builds:

```text
[CareConnect API] → GET http://10.0.2.2:3000/api/v1/users/me
[CareConnect API] ✓ 200 GET http://10.0.2.2:3000/api/v1/users/me (142ms)
```

Request and response payloads are sanitized before printing. Authentication
tokens, passwords, and personal or health-related fields are redacted. API
logging is disabled automatically in profile and release builds.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
