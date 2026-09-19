import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointments_screen.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_repository.dart';
import 'package:careconnect_mobile/features/find_care/presentation/find_care_screen.dart';
import 'package:careconnect_mobile/features/home/presentation/home_screen.dart';
import 'package:careconnect_mobile/features/notifications/data/notifications_repository.dart';
import 'package:careconnect_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.user,
    this.onLogout,
    this.accessTokenProvider,
    this.initialIndex = 0,
  });

  final CurrentUser? user;
  final Future<void> Function()? onLogout;
  final AccessTokenProvider? accessTokenProvider;
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex = widget.initialIndex;
  ApiClient? _apiClient;
  AppointmentsDataSource? _appointmentsRepository;
  FindCareDataSource? _findCareRepository;
  NotificationsRepository? _notificationsRepository;

  @override
  void initState() {
    super.initState();
    final tokenProvider = widget.accessTokenProvider;
    if (tokenProvider != null) {
      _apiClient = ApiClient(accessTokenProvider: tokenProvider);
      _appointmentsRepository = AppointmentsRepository(_apiClient!);
      _findCareRepository = FindCareRepository(_apiClient!);
      _notificationsRepository = NotificationsRepository(_apiClient!);
    }
  }

  @override
  void dispose() {
    _apiClient?.close();
    super.dispose();
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  void _openNotifications() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => NotificationsScreen(repository: _notificationsRepository),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        firstName: widget.user?.firstName,
        onFindCare: () => _select(1),
        onAppointments: () => _select(2),
        onProfile: () => _select(3),
        onNotifications: _openNotifications,
      ),
      FindCareScreen(
        repository: _findCareRepository,
        onNotifications: _openNotifications,
      ),
      AppointmentsScreen(
        key: const ValueKey('appointments-page'),
        repository: _appointmentsRepository,
      ),
      ProfileScreen(
        user: widget.user,
        onLogout: widget.onLogout,
        onNotifications: _openNotifications,
      ),
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
