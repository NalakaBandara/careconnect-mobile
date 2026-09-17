class AuthSession {
  const AuthSession({
    required this.email,
    required this.displayName,
    required this.pictureUrl,
  });

  final String? email;
  final String? displayName;
  final Uri? pictureUrl;
}
