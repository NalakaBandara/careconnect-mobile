import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/auth/presentation/welcome_screen.dart';
import 'package:careconnect_mobile/shared/widgets/careconnect_mark.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({this.authBuilder, super.key});

  final WidgetBuilder? authBuilder;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingData(
      eyebrow: 'CARE, YOUR WAY',
      title: 'The right care,\nwithout the guesswork.',
      description:
          'Explore trusted clinics, specialists, and services built around what matters to you.',
      icon: Icons.travel_explore_rounded,
      accent: AppColors.accent,
      background: AppColors.mintSoft,
      floatingIcons: [Icons.local_hospital_rounded, Icons.favorite_rounded],
    ),
    _OnboardingData(
      eyebrow: 'YOUR TIME MATTERS',
      title: 'Book a time that\nactually works.',
      description:
          'Compare availability, choose your slot, and keep every detail together in a few taps.',
      icon: Icons.calendar_month_rounded,
      accent: Color(0xFF5276D8),
      background: AppColors.blueSoft,
      floatingIcons: [Icons.schedule_rounded, Icons.event_available_rounded],
    ),
    _OnboardingData(
      eyebrow: 'READY WHEN YOU ARE',
      title: 'Stay one step ahead\nof every visit.',
      description:
          'Get helpful reminders, manage appointments, and check in with confidence when you arrive.',
      icon: Icons.shield_outlined,
      accent: Color(0xFF7957C8),
      background: AppColors.lilacSoft,
      floatingIcons: [
        Icons.notifications_active_rounded,
        Icons.qr_code_2_rounded,
      ],
    ),
  ];

  final _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: widget.authBuilder ?? (_) => const WelcomeScreen(),
      ),
    );
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: Column(
            children: [
              Row(
                children: [
                  const CareConnectMark(size: 42),
                  const SizedBox(width: 11),
                  const Text(
                    'CareConnect',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('skip-onboarding'),
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (value) =>
                      setState(() => _currentPage = value),
                  itemCount: _pages.length,
                  itemBuilder: (_, index) =>
                      _OnboardingPage(data: _pages[index]),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var index = 0; index < _pages.length; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      width: index == _currentPage ? 30 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 148,
                    child: FilledButton(
                      key: const Key('onboarding-next'),
                      onPressed: _next,
                      child: Text(_isLastPage ? 'Get started' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final artworkHeight = (constraints.maxHeight * 0.44).clamp(
          210.0,
          340.0,
        );
        return ListView(
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            SizedBox(
              height: artworkHeight,
              width: double.infinity,
              child: _CareArtwork(data: data),
            ),
            const SizedBox(height: 28),
            Text(
              data.eyebrow,
              style: TextStyle(
                color: data.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.25,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              data.title,
              key: ValueKey(data.title),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: constraints.maxHeight < 620 ? 30 : 36,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              data.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        );
      },
    );
  }
}

class _CareArtwork extends StatelessWidget {
  const _CareArtwork({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: ColoredBox(
        color: data.background,
        child: Stack(
          children: [
            Positioned(
              top: -45,
              right: -30,
              child: _Circle(
                size: 150,
                color: data.accent.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              bottom: -38,
              left: -20,
              child: _Circle(
                size: 125,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            Center(
              child: Container(
                width: 132,
                height: 156,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: data.accent.withValues(alpha: 0.18),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: data.accent, size: 56),
              ),
            ),
            Positioned(
              left: 26,
              top: 38,
              child: _FloatingIcon(
                icon: data.floatingIcons.first,
                color: data.accent,
              ),
            ),
            Positioned(
              right: 25,
              bottom: 35,
              child: _FloatingIcon(
                icon: data.floatingIcons.last,
                color: data.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

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

class _OnboardingData {
  const _OnboardingData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.background,
    required this.floatingIcons,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color background;
  final List<IconData> floatingIcons;
}
