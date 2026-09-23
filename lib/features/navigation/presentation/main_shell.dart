import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/logging/app_logger.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_controller.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointments_screen.dart';
import 'package:careconnect_mobile/features/booking/data/booking_repository.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_repository.dart';
import 'package:careconnect_mobile/features/find_care/presentation/find_care_screen.dart';
import 'package:careconnect_mobile/features/home/presentation/home_screen.dart';
import 'package:careconnect_mobile/features/notifications/data/notifications_repository.dart';
import 'package:careconnect_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:careconnect_mobile/features/profile/data/user_repository.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.user,
    this.onLogout,
    this.onSessionExpired,
    this.onSignInRequired,
    this.accessTokenProvider,
    this.guestFindCareRepository,
    this.useLiveGuestDirectory = true,
    this.initialIndex = 0,
  });

  final CurrentUser? user;
  final Future<void> Function()? onLogout;
  final Future<void> Function()? onSessionExpired;
  final VoidCallback? onSignInRequired;
  final AccessTokenProvider? accessTokenProvider;
  final FindCareDataSource? guestFindCareRepository;
  final bool useLiveGuestDirectory;
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex = widget.initialIndex;
  late final Set<int> _loadedIndexes = {widget.initialIndex};
  ApiClient? _apiClient;
  AppointmentsDataSource? _appointmentsRepository;
  AppointmentsController? _appointmentsController;
  FindCareDataSource? _findCareRepository;
  AppointmentBookingDataSource? _bookingRepository;
  NotificationsRepository? _notificationsRepository;
  UserDataSource? _userRepository;
  late CurrentUser? _user;
  bool _handlingUnauthorized = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    final tokenProvider = widget.accessTokenProvider;
    if (tokenProvider != null) {
      _apiClient = ApiClient(
        accessTokenProvider: tokenProvider,
        onUnauthorized: _handleUnauthorized,
      );
      _appointmentsRepository = AppointmentsRepository(_apiClient!);
      _appointmentsController = AppointmentsController(
        _appointmentsRepository!,
      );
      _findCareRepository = FindCareRepository(_apiClient!);
      _bookingRepository = AppointmentBookingRepository(_apiClient!);
      _notificationsRepository = NotificationsRepository(_apiClient!);
      _userRepository = UserRepository(_apiClient!);
    } else if (widget.useLiveGuestDirectory) {
      _findCareRepository = widget.guestFindCareRepository;
      if (_findCareRepository == null) {
        _apiClient = ApiClient(accessTokenProvider: _noAccessToken);
        _findCareRepository = FindCareRepository(_apiClient!);
      }
    }
  }

  static Future<String?> _noAccessToken() async => null;

  @override
  void dispose() {
    _appointmentsController?.dispose();
    _apiClient?.close();
    super.dispose();
  }

  void _select(int index) {
    if (index == _selectedIndex) return;
    AppLogger.info(
      'NAV',
      'Bottom tab changed',
      details: {'fromIndex': _selectedIndex, 'toIndex': index},
    );
    setState(() {
      _selectedIndex = index;
      _loadedIndexes.add(index);
    });
  }

  void _updateUser(CurrentUser user) => setState(() => _user = user);

  void _appointmentCreated(CareAppointment appointment) {
    _appointmentsController?.upsert(appointment);
  }

  void _viewAppointments() => _select(2);

  Future<void> _handleUnauthorized() async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    AppLogger.warning('AUTH', 'API rejected the current session');
    await widget.onSessionExpired?.call();
  }

  void _openNotifications() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => NotificationsScreen(repository: _notificationsRepository),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final pages = [
      if (_loadedIndexes.contains(0))
        HomeScreen(
          firstName: _user?.firstName,
          appointmentsController: _appointmentsController,
          onFindCare: () => _select(1),
          onAppointments: () => _select(2),
          onProfile: () => _select(3),
          onNotifications: _openNotifications,
        )
      else
        const SizedBox.shrink(),
      if (_loadedIndexes.contains(1))
        FindCareScreen(
          repository: _findCareRepository,
          bookingRepository: _bookingRepository,
          currentUser: _user,
          canLoadAvailability: widget.accessTokenProvider != null,
          onSignInRequired: widget.onSignInRequired,
          onAppointmentCreated: _appointmentCreated,
          onViewAppointments: _viewAppointments,
          onNotifications: _openNotifications,
        )
      else
        const SizedBox.shrink(),
      if (_loadedIndexes.contains(2))
        AppointmentsScreen(
          key: const ValueKey('appointments-page'),
          repository: _appointmentsRepository,
          appointmentsController: _appointmentsController,
        )
      else
        const SizedBox.shrink(),
      if (_loadedIndexes.contains(3))
        ProfileScreen(
          user: _user,
          repository: _userRepository,
          onUserChanged: _updateUser,
          onLogout: widget.onLogout,
          onNotifications: _openNotifications,
        )
      else
        const SizedBox.shrink(),
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
