import 'dart:async';

import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/auth/presentation/welcome_screen.dart';
import 'package:careconnect_mobile/features/onboarding/data/onboarding_preference_store.dart';
import 'package:careconnect_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:careconnect_mobile/shared/widgets/careconnect_mark.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({this.preferenceStore, this.completedBuilder, super.key});

  final OnboardingPreferenceStore? preferenceStore;
  final WidgetBuilder? completedBuilder;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final OnboardingPreferenceStore _preferenceStore;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _preferenceStore =
        widget.preferenceStore ?? SecureOnboardingPreferenceStore();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _navigationTimer = Timer(
      const Duration(milliseconds: 1700),
      _continueFromSplash,
    );
  }

  Future<void> _continueFromSplash() async {
    var hasCompletedOnboarding = false;
    try {
      hasCompletedOnboarding = await _preferenceStore.hasCompleted();
    } catch (_) {
      // If device storage is unavailable, showing onboarding is the safe path.
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => hasCompletedOnboarding
            ? (widget.completedBuilder?.call(context) ?? const WelcomeScreen())
            : OnboardingScreen(preferenceStore: _preferenceStore),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const Positioned(
            top: -100,
            right: -90,
            child: _GlowOrb(size: 280, color: AppColors.mintSoft),
          ),
          const Positioned(
            bottom: -130,
            left: -80,
            child: _GlowOrb(size: 300, color: AppColors.blueSoft),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: Tween(begin: 0.88, end: 1.0).animate(_fade),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: CareConnectLogo(
                        key: Key('splash-title'),
                        width: 286,
                        showShadow: true,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Care, made beautifully simple.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
