import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/auth/data/auth_service.dart';
import 'package:careconnect_mobile/features/auth/domain/auth_session.dart';
import 'package:careconnect_mobile/features/auth/presentation/auth_form_screen.dart';
import 'package:careconnect_mobile/features/navigation/presentation/main_shell.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/shared/widgets/careconnect_mark.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({this.authService, super.key});

  final AuthDataSource? authService;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final AuthDataSource _authService;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() => _busy = true);
    try {
      final session = await _authService.restoreSession();
      if (session != null && mounted) _openHome(session.user);
    } catch (_) {
      // A failed silent restore should leave the user on the sign-in screen.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _authenticate({required bool signUp}) async {
    final session = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        builder: (_) =>
            AuthFormScreen(authService: _authService, signUp: signUp),
      ),
    );
    if (session != null && mounted) _openHome(session.user);
  }

  void _openHome(CurrentUser user) => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (homeContext) => _buildHome(homeContext, user: user),
    ),
  );

  Widget _buildHome(BuildContext homeContext, {required CurrentUser user}) =>
      MainShell(
        user: user,
        accessTokenProvider: _authService.accessToken,
        onLogout: () async {
          await _authService.logout();
          if (!homeContext.mounted) return;
          Navigator.of(homeContext).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => WelcomeScreen(authService: _authService),
            ),
            (_) => false,
          );
        },
      );

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
                const SizedBox(height: 26),
                FilledButton(
                  key: const Key('sign-in-button'),
                  onPressed: _busy ? null : () => _authenticate(signUp: false),
                  child: const Text('Sign in'),
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
                      'Secure access protected by CareConnect',
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
