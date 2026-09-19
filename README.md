# CareConnect Mobile

Flutter mobile client for the personal CareConnect project.

## Local configuration

No credentials or environment-specific values are committed to this project.
Use CareConnect-specific values only.

```bash
CARECONNECT_AUTH0_DOMAIN=your-careconnect-domain.auth0.com \
flutter run \
  --dart-define=CARECONNECT_AUTH0_DOMAIN=your-careconnect-domain.auth0.com \
  --dart-define=CARECONNECT_AUTH0_CLIENT_ID=your-careconnect-client-id \
  --dart-define=CARECONNECT_AUTH0_AUDIENCE=your-careconnect-api-audience \
  --dart-define=CARECONNECT_API_BASE_URL=http://10.0.2.2:3000
```

Configure this Android callback in the CareConnect Auth0 Native application:

```text
careconnect://YOUR_CARECONNECT_AUTH0_DOMAIN/android/com.example.careconnect_mobile/callback
```

Add the same URL to **Allowed Callback URLs** and **Allowed Logout URLs**.

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
