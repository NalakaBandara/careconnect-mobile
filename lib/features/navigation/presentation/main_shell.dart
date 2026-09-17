import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointments_screen.dart';
import 'package:careconnect_mobile/features/find_care/presentation/find_care_screen.dart';
import 'package:careconnect_mobile/features/home/presentation/home_screen.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.user, this.onLogout, this.initialIndex = 0});

  final CurrentUser? user;
  final Future<void> Function()? onLogout;
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex = widget.initialIndex;

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        firstName: widget.user?.firstName,
        onFindCare: () => _select(1),
        onAppointments: () => _select(2),
        onProfile: () => _select(3),
      ),
      const FindCareScreen(),
      const AppointmentsScreen(key: ValueKey('appointments-page')),
      _ProfilePreviewPage(user: widget.user, onLogout: widget.onLogout),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16063F3C),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 68,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _select,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.mintSoft,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                key: Key('nav-home'),
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                key: Key('nav-find-care'),
                icon: Icon(Icons.search_rounded),
                selectedIcon: Icon(Icons.manage_search_rounded),
                label: 'Find Care',
              ),
              NavigationDestination(
                key: Key('nav-appointments'),
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Visits',
              ),
              NavigationDestination(
                key: Key('nav-profile'),
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePreviewPage extends StatelessWidget {
  const _ProfilePreviewPage({required this.user, required this.onLogout});

  final CurrentUser? user;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : 'Guest preview';
    final email = user?.email ?? 'Sign in later to sync your care';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 110),
          children: [
            Text(
              'Your profile',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.lilacSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF7957C8),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(email, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _ProfileTile(
              icon: Icons.person_outline_rounded,
              title: 'Personal details',
              caption: 'Name, phone and address',
            ),
            const SizedBox(height: 10),
            const _ProfileTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              caption: 'Reminders and updates',
            ),
            const SizedBox(height: 10),
            const _ProfileTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & support',
              caption: 'FAQs and contact',
            ),
            if (onLogout != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  caption,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
