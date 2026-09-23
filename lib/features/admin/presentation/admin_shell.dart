import 'package:careconnect_mobile/core/logging/app_logger.dart';
import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_management_forms.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_security_screens.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_doctor_operations_screen.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_appointment_screen.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_clinic_operations_screen.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/shared/widgets/careconnect_mark.dart';
import 'package:flutter/material.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    required this.user,
    required this.accessTokenProvider,
    this.onLogout,
    this.onSessionExpired,
    this.repository,
    super.key,
  });

  final CurrentUser user;
  final AccessTokenProvider accessTokenProvider;
  final Future<void> Function()? onLogout;
  final Future<void> Function()? onSessionExpired;
  final AdminDataSource? repository;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late final ApiClient? _client;
  late final AdminDataSource _repository;
  late Future<AdminDashboardSnapshot> _dashboard;
  int _selectedIndex = 0;
  bool _handlingUnauthorized = false;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _client = null;
      _repository = widget.repository!;
    } else {
      final client = ApiClient(
        accessTokenProvider: widget.accessTokenProvider,
        onUnauthorized: _handleUnauthorized,
      );
      _client = client;
      _repository = AdminRepository(client);
    }
    _dashboard = _repository.getDashboard();
    AppLogger.info('ADMIN', 'Admin workspace opened');
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  Future<void> _handleUnauthorized() async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    AppLogger.warning('AUTH', 'Admin API rejected the current session');
    await widget.onSessionExpired?.call();
  }

  Future<void> _refresh() async {
    final request = _repository.getDashboard();
    setState(() => _dashboard = request);
    await request;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('admin-shell'),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<AdminDashboardSnapshot>(
          future: _dashboard,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _AdminError(onRetry: _refresh);
            }
            final data = snapshot.data!;
            return IndexedStack(
              index: _selectedIndex,
              children: [
                _DashboardPage(
                  user: widget.user,
                  data: data,
                  onRefresh: _refresh,
                ),
                _ManagementPage(
                  data: data,
                  repository: _repository,
                  onRefresh: _refresh,
                ),
                _AppointmentsPage(
                  data: data,
                  repository: _repository,
                  onRefresh: _refresh,
                ),
                _AdminAccountPage(
                  user: widget.user,
                  repository: _repository,
                  onLogout: widget.onLogout,
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          AppLogger.info(
            'ADMIN',
            'Admin tab changed',
            details: {'index': index},
          );
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            key: Key('admin-nav-overview'),
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            key: Key('admin-nav-manage'),
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Manage',
          ),
          NavigationDestination(
            key: Key('admin-nav-visits'),
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Visits',
          ),
          NavigationDestination(
            key: Key('admin-nav-account'),
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CareConnectMark(size: 44, showShadow: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.mintSoft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'ADMIN',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.user,
    required this.data,
    required this.onRefresh,
  });

  final CurrentUser user;
  final AdminDashboardSnapshot data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('admin-dashboard'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const _AdminHeader(title: 'CareConnect', subtitle: 'Admin workspace'),
          const SizedBox(height: 28),
          Text(
            'Good day, ${user.firstName}',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 8),
          const Text(
            'Here is what is happening across your care network.',
            style: TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.08,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _MetricCard(
                label: 'Users',
                value: data.totalUsers,
                icon: Icons.people_rounded,
                tint: AppColors.mintSoft,
                color: AppColors.primary,
              ),
              _MetricCard(
                label: 'Doctors',
                value: data.doctorCount,
                icon: Icons.medical_services_rounded,
                tint: AppColors.blueSoft,
                color: const Color(0xFF4169B2),
              ),
              _MetricCard(
                label: 'Clinics',
                value: data.clinicCount,
                icon: Icons.local_hospital_rounded,
                tint: AppColors.lilacSoft,
                color: const Color(0xFF7654B8),
              ),
              _MetricCard(
                label: 'Pending visits',
                value: data.pendingAppointmentCount,
                icon: Icons.pending_actions_rounded,
                tint: const Color(0xFFFFF2D8),
                color: const Color(0xFFAA6B00),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Recent appointments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (data.appointments.isEmpty)
            const _EmptyCard(message: 'No appointments have been created yet.')
          else
            ...data.appointments.take(3).map(_AppointmentCard.new),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color tint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ManagementSection { users, doctors, clinics }

class _ManagementPage extends StatefulWidget {
  const _ManagementPage({
    required this.data,
    required this.repository,
    required this.onRefresh,
  });

  final AdminDashboardSnapshot data;
  final AdminDataSource repository;
  final Future<void> Function() onRefresh;

  @override
  State<_ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<_ManagementPage> {
  _ManagementSection _section = _ManagementSection.users;

  Future<void> _openDoctor([AdminDoctor? doctor]) async {
    final existingUserIds = widget.data.doctors
        .map((item) => item.userId)
        .toSet();
    final users = doctor == null
        ? widget.data.users
              .where((user) => !existingUserIds.contains(user.id))
              .toList(growable: false)
        : widget.data.users;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminDoctorFormScreen(
          repository: widget.repository,
          users: users,
          clinics: widget.data.clinics,
          specialties: widget.data.specialties,
          doctor: doctor,
        ),
      ),
    );
    if (changed == true) await widget.onRefresh();
  }

  Future<void> _openClinic([AdminClinic? clinic]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminClinicFormScreen(
          repository: widget.repository,
          clinic: clinic,
        ),
      ),
    );
    if (changed == true) await widget.onRefresh();
  }

  Future<void> _openClinicOperations(AdminClinic clinic) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AdminClinicOperationsScreen(
          clinic: clinic,
          services: widget.data.services,
          users: widget.data.users,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _openDoctorOperations(AdminDoctor doctor) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AdminDoctorOperationsScreen(
          doctor: doctor,
          clinics: widget.data.clinics,
          specialties: widget.data.specialties,
          repository: widget.repository,
          onChanged: widget.onRefresh,
        ),
      ),
    );
  }

  Future<void> _openUserAccess(AdminUser user) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AdminUserAccessScreen(
          user: user,
          repository: widget.repository,
          onChanged: widget.onRefresh,
        ),
      ),
    );
  }

  Future<void> _toggleClinic(AdminClinic clinic, bool active) async {
    try {
      await widget.repository.updateClinic(
        clinic,
        status: active ? 'ACTIVE' : 'INACTIVE',
      );
      await widget.onRefresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the clinic status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _section != _ManagementSection.users;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        key: const Key('admin-management'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const _AdminHeader(
            title: 'Management',
            subtitle: 'People and care locations',
          ),
          const SizedBox(height: 22),
          SegmentedButton<_ManagementSection>(
            segments: const [
              ButtonSegment(
                value: _ManagementSection.users,
                label: Text('Users'),
              ),
              ButtonSegment(
                value: _ManagementSection.doctors,
                label: Text('Doctors'),
              ),
              ButtonSegment(
                value: _ManagementSection.clinics,
                label: Text('Clinics'),
              ),
            ],
            selected: {_section},
            showSelectedIcon: false,
            onSelectionChanged: (value) =>
                setState(() => _section = value.single),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(switch (_section) {
                  _ManagementSection.users =>
                    '${widget.data.totalUsers} registered users',
                  _ManagementSection.doctors =>
                    '${widget.data.doctorCount} doctor profiles',
                  _ManagementSection.clinics =>
                    '${widget.data.clinicCount} care locations',
                }, style: Theme.of(context).textTheme.titleLarge),
              ),
              if (canAdd)
                IconButton.filled(
                  key: const Key('admin-management-add'),
                  tooltip: _section == _ManagementSection.doctors
                      ? 'Add doctor'
                      : 'Add clinic',
                  onPressed: () => _section == _ManagementSection.doctors
                      ? _openDoctor()
                      : _openClinic(),
                  icon: const Icon(Icons.add_rounded),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...switch (_section) {
            _ManagementSection.users =>
              widget.data.users.isEmpty
                  ? const [_EmptyCard(message: 'No users found.')]
                  : widget.data.users
                        .map(
                          (user) => _UserCard(
                            user,
                            onTap: () => _openUserAccess(user),
                          ),
                        )
                        .toList(),
            _ManagementSection.doctors =>
              widget.data.doctors.isEmpty
                  ? const [_EmptyCard(message: 'No doctor profiles found.')]
                  : widget.data.doctors
                        .map(
                          (doctor) => _DoctorAdminCard(
                            doctor: doctor,
                            onEdit: () => _openDoctor(doctor),
                            onSetup: () => _openDoctorOperations(doctor),
                          ),
                        )
                        .toList(),
            _ManagementSection.clinics =>
              widget.data.clinics.isEmpty
                  ? const [_EmptyCard(message: 'No clinics found.')]
                  : widget.data.clinics
                        .map(
                          (clinic) => _ClinicAdminCard(
                            clinic: clinic,
                            onEdit: () => _openClinic(clinic),
                            onSetup: () => _openClinicOperations(clinic),
                            onStatusChanged: (active) =>
                                _toggleClinic(clinic, active),
                          ),
                        )
                        .toList(),
          },
        ],
      ),
    );
  }
}

class _DoctorAdminCard extends StatelessWidget {
  const _DoctorAdminCard({
    required this.doctor,
    required this.onEdit,
    required this.onSetup,
  });

  final AdminDoctor doctor;
  final VoidCallback onEdit;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: doctor.isVerified
              ? AppColors.mintSoft
              : AppColors.blueSoft,
          foregroundColor: AppColors.primary,
          child: Icon(
            doctor.isVerified
                ? Icons.verified_rounded
                : Icons.medical_services_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.displayName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                doctor.specialties.isEmpty
                    ? 'No specialty assigned'
                    : doctor.specialties.map((item) => item.name).join(' · '),
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                doctor.clinics.isEmpty
                    ? 'No clinic assigned'
                    : doctor.clinics.map((item) => item.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          key: Key('admin-doctor-setup-${doctor.id}'),
          tooltip: 'Assignments and schedules',
          onPressed: onSetup,
          icon: const Icon(Icons.event_available_outlined),
        ),
        IconButton(
          tooltip: 'Edit profile',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    ),
  );
}

class _ClinicAdminCard extends StatelessWidget {
  const _ClinicAdminCard({
    required this.clinic,
    required this.onEdit,
    required this.onSetup,
    required this.onStatusChanged,
  });

  final AdminClinic clinic;
  final VoidCallback onEdit;
  final VoidCallback onSetup;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: AppColors.lilacSoft,
          foregroundColor: Color(0xFF7654B8),
          child: Icon(Icons.local_hospital_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clinic.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${clinic.addressLine1}, ${clinic.city}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch.adaptive(value: clinic.isActive, onChanged: onStatusChanged),
        PopupMenuButton<String>(
          key: Key('admin-clinic-setup-${clinic.id}'),
          tooltip: 'Clinic actions',
          onSelected: (value) => value == 'setup' ? onSetup() : onEdit(),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'setup',
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Manage clinic'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _UserCard extends StatelessWidget {
  const _UserCard(this.user, {this.onTap});

  final AdminUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.characters.first.toUpperCase();
    return InkWell(
      key: Key('admin-user-${user.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.mintSoft,
              foregroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.roles.isEmpty
                        ? 'No role assigned'
                        : user.roles.join(' · '),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _StatusDot(active: user.status.toUpperCase() == 'ACTIVE'),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsPage extends StatefulWidget {
  const _AppointmentsPage({
    required this.data,
    required this.repository,
    required this.onRefresh,
  });

  final AdminDashboardSnapshot data;
  final AdminDataSource repository;
  final Future<void> Function() onRefresh;

  @override
  State<_AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<_AppointmentsPage> {
  final _searchController = TextEditingController();
  AppointmentStatus? _status;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CareAppointment> get _filteredAppointments {
    final query = _searchController.text.trim().toLowerCase();
    return widget.data.appointments
        .where((appointment) {
          if (_status != null && appointment.status != _status) return false;
          if (query.isEmpty) return true;
          return appointment.reference.toLowerCase().contains(query) ||
              appointment.patientId.toLowerCase().contains(query) ||
              appointment.doctor.displayName.toLowerCase().contains(query) ||
              appointment.clinic.name.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _openAppointment(CareAppointment appointment) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AdminAppointmentScreen(
          appointment: appointment,
          repository: widget.repository,
          onChanged: widget.onRefresh,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _filteredAppointments;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        key: const Key('admin-appointments'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const _AdminHeader(
            title: 'Appointments',
            subtitle: 'Network-wide visits',
          ),
          const SizedBox(height: 26),
          TextField(
            key: const Key('admin-appointment-search'),
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Reference, patient, doctor or clinic',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AppointmentFilterChip(
                  label: 'All',
                  selected: _status == null,
                  onSelected: () => setState(() => _status = null),
                ),
                for (final status in const [
                  AppointmentStatus.pending,
                  AppointmentStatus.confirmed,
                  AppointmentStatus.completed,
                  AppointmentStatus.cancelled,
                  AppointmentStatus.noShow,
                ]) ...[
                  const SizedBox(width: 8),
                  _AppointmentFilterChip(
                    label: status.label,
                    selected: _status == status,
                    onSelected: () => setState(() => _status = status),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${appointments.length} of ${widget.data.appointments.length} appointments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (appointments.isEmpty)
            const _EmptyCard(message: 'No appointments match these filters.')
          else
            ...appointments.map(
              (appointment) => _AppointmentCard(
                appointment,
                onTap: () => _openAppointment(appointment),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppointmentFilterChip extends StatelessWidget {
  const _AppointmentFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard(this.appointment, {this.onTap});

  final CareAppointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('admin-appointment-${appointment.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.doctor.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _StatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              appointment.service.name,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${appointment.appointmentDate}  ·  ${appointment.startTime}  ·  ${appointment.clinic.name}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              'Patient #${appointment.patientId}  ·  ${appointment.reference}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == AppointmentStatus.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFF2D8) : AppColors.mintSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: isPending ? const Color(0xFF8B5B00) : AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: active ? 'Active' : 'Inactive',
    child: Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.accent : AppColors.coral,
      ),
    ),
  );
}

class _AdminAccountPage extends StatelessWidget {
  const _AdminAccountPage({
    required this.user,
    required this.repository,
    required this.onLogout,
  });

  final CurrentUser user;
  final AdminDataSource repository;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('admin-account'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const _AdminHeader(
          title: 'Administration',
          subtitle: 'Secure admin access',
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(height: 18),
              Text(
                user.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(color: Color(0xFFD6EFEB)),
              ),
              const SizedBox(height: 14),
              Text(
                user.roles.join(' · '),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _AdminMenuTile(
          key: const Key('admin-security-tile'),
          icon: Icons.policy_outlined,
          title: 'Roles and audit',
          subtitle: 'Review role definitions and recent security activity',
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => AdminSecurityScreen(repository: repository),
            ),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const Key('admin-logout'),
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.lilacSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF7654B8)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.muted, height: 1.45),
    ),
  );
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: AppColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load the admin workspace',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check the connection and your admin permissions, then try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
