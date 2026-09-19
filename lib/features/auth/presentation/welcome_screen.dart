import 'package:careconnect_mobile/core/config/app_config.dart';
import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/auth/data/auth_service.dart';
import 'package:careconnect_mobile/features/auth/domain/auth_session.dart';
import 'package:careconnect_mobile/features/navigation/presentation/main_shell.dart';
import 'package:careconnect_mobile/features/profile/data/user_repository.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/features/profile/presentation/profile_setup_screen.dart';
import 'package:careconnect_mobile/shared/widgets/careconnect_mark.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  AuthService? _authService;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (AppConfig.isAuth0Configured) {
      _authService = AuthService();
      _restoreSession();
    }
  }

  Future<void> _restoreSession() async {
    final service = _authService;
    if (service == null) return;
    setState(() => _busy = true);
    try {
      final session = await service.restoreSession();
      if (session != null) await _loadCareConnectProfile(service, session);
    } catch (_) {
      // A failed silent restore should leave the user on the sign-in screen.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _authenticate({required bool signUp}) async {
    if (!AppConfig.isAuth0Configured) {
      _showConfigurationSheet();
      return;
    }

    final service = _authService ??= AuthService();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final session = await service.login(signUp: signUp);
      await _loadCareConnectProfile(service, session);
    } on AuthCancelledException {
      // Cancelling the system browser is a normal user action.
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'We could not sign you in. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadCareConnectProfile(
    AuthService service,
    AuthSession session,
  ) async {
    final apiClient = ApiClient(accessTokenProvider: service.accessToken);
    try {
      final user = await UserRepository(apiClient).getCurrentUser();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (homeContext) =>
              _buildHome(homeContext, service: service, user: user),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 404) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ProfileSetupScreen(
              email: session.email,
              displayName: session.displayName,
              onCreate: (request) async {
                final createClient = ApiClient(
                  accessTokenProvider: service.accessToken,
                );
                try {
                  return await UserRepository(
                    createClient,
                  ).createCurrentUser(request);
                } finally {
                  createClient.close();
                }
              },
              homeBuilder: (homeContext, user) =>
                  _buildHome(homeContext, service: service, user: user),
              onExit: (setupContext) async {
                await service.logout();
                if (!setupContext.mounted) return;
                Navigator.of(setupContext).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const WelcomeScreen(),
                  ),
                  (_) => false,
                );
              },
            ),
          ),
        );
        return;
      }
      rethrow;
    } finally {
      apiClient.close();
    }
  }

  Widget _buildHome(
    BuildContext homeContext, {
    required AuthService service,
    required CurrentUser user,
  }) => MainShell(
    user: user,
    accessTokenProvider: service.accessToken,
    onLogout: () async {
      await service.logout();
      if (!homeContext.mounted) return;
      Navigator.of(homeContext).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    },
  );

  void _showConfigurationSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CareConnect setup required',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Add the CareConnect Auth0 domain, client ID, and API audience using the documented environment configuration. No company credentials should be used.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              children: [
                const Row(
                  children: [
                    CareConnectMark(size: 42),
                    SizedBox(width: 11),
                    Text(
                      'CareConnect',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _AuthHero(),
                const SizedBox(height: 30),
                Text(
                  'Your care starts here.',
                  key: const Key('auth-title'),
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in securely to book appointments, manage visits, and keep your health journey organized.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  _ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 26),
                FilledButton(
                  key: const Key('sign-in-button'),
                  onPressed: _busy ? null : () => _authenticate(signUp: false),
                  child: const Text('Continue securely'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const Key('create-account-button'),
                  onPressed: _busy ? null : () => _authenticate(signUp: true),
                  child: const Text('Create an account'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  key: const Key('browse-as-guest-button'),
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const MainShell(),
                          ),
                        ),
                  icon: const Icon(Icons.explore_outlined, size: 19),
                  label: const Text('Explore as guest'),
                ),
                const SizedBox(height: 20),
                const Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    Text(
                      'Private sign-in powered by Auth0',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66F7FAF9),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -55,
            right: -45,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: 24,
            top: 26,
            child: _TrustChip(
              icon: Icons.shield_outlined,
              label: 'Secure by design',
            ),
          ),
          const Positioned(
            right: 24,
            bottom: 26,
            child: _TrustChip(
              icon: Icons.favorite_outline_rounded,
              label: 'Built around you',
            ),
          ),
          const Center(
            child: Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 72,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC34B3E)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.ink, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
