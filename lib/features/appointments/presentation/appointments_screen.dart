import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_preview_data.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_controller.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointment_detail_screen.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointment_ui.dart';
import 'package:flutter/material.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({
    super.key,
    this.repository,
    this.appointmentsController,
    this.isGuest = false,
    this.onSignIn,
    this.onCreateAccount,
  });

  final AppointmentsDataSource? repository;
  final AppointmentsController? appointmentsController;
  final bool isGuest;
  final VoidCallback? onSignIn;
  final VoidCallback? onCreateAccount;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late List<CareAppointment> _appointments;
  bool _showPast = false;
  bool _isLoading = false;
  String? _error;
  AppointmentsController? _controller;
  bool _ownsController = false;

  bool get _isPreview =>
      widget.repository == null && widget.appointmentsController == null;

  @override
  void initState() {
    super.initState();
    _appointments = _isPreview && !widget.isGuest
        ? List.of(AppointmentsPreviewData.appointments)
        : [];
    if (!_isPreview && !widget.isGuest) {
      _controller = widget.appointmentsController;
      if (_controller == null) {
        _controller = AppointmentsController(widget.repository!);
        _ownsController = true;
      }
      _controller!.addListener(_syncAppointments);
      _syncAppointments();
      _controller!.load();
    }
  }

  void _syncAppointments() {
    if (!mounted) return;
    setState(() {
      _appointments = _controller!.appointments;
      _isLoading = _controller!.isLoading;
      _error = _controller!.error == null
          ? null
          : 'We could not load your appointments. Check your connection and try again.';
    });
  }

  Future<void> _loadAppointments() => _controller!.refresh();

  @override
  void dispose() {
    _controller?.removeListener(_syncAppointments);
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  List<CareAppointment> get _visibleAppointments =>
      _appointments
          .where((appointment) => appointment.isPast == _showPast)
          .toList(growable: false)
        ..sort(
          (a, b) => _showPast
              ? b.appointmentDate.compareTo(a.appointmentDate)
              : a.appointmentDate.compareTo(b.appointmentDate),
        );

  void _updateAppointment(CareAppointment updated) {
    if (_controller != null) {
      _controller!.upsert(updated);
      return;
    }
    final index = _appointments.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _appointments[index] = updated);
  }

  void _openAppointment(CareAppointment appointment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppointmentDetailScreen(
          initialAppointment: appointment,
          repository: widget.repository,
          onChanged: _updateAppointment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGuest) {
      return _GuestAppointmentsScreen(
        onSignIn: widget.onSignIn,
        onCreateAccount: widget.onCreateAccount,
      );
    }
    final upcomingCount = _appointments.where((item) => !item.isPast).length;
    final pastCount = _appointments.where((item) => item.isPast).length;
    final visible = _visibleAppointments;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _isPreview
              ? () async =>
                    Future<void>.delayed(const Duration(milliseconds: 250))
              : _loadAppointments,
          child: CustomScrollView(
            key: const Key('appointments-screen'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MY CARE',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                'Your appointments',
                                key: const Key('appointments-title'),
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.blueSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFF5276D8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1EF),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              key: const Key('appointments-upcoming-tab'),
                              label: 'Upcoming',
                              count: upcomingCount,
                              selected: !_showPast,
                              onTap: () => setState(() => _showPast = false),
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              key: const Key('appointments-past-tab'),
                              label: 'Past',
                              count: pastCount,
                              selected: _showPast,
                              onTap: () => setState(() => _showPast = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _showPast ? 'Previous visits' : 'Coming up',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _showPast
                          ? 'A record of your recent appointment requests.'
                          : 'Everything you need for your next visit.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_isLoading)
                      const LinearProgressIndicator(
                        key: Key('appointments-loading'),
                        minHeight: 3,
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _AppointmentsError(
                        message: _error!,
                        onRetry: _loadAppointments,
                      ),
                    ],
                  ],
                ),
              ),
              if (visible.isEmpty && _isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadingAppointments(),
                )
              else if (visible.isEmpty && _error == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyAppointments(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 118),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => AppointmentCard(
                      appointment: visible[index],
                      onTap: () => _openAppointment(visible[index]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestAppointmentsScreen extends StatelessWidget {
  const _GuestAppointmentsScreen({this.onSignIn, this.onCreateAccount});

  final VoidCallback? onSignIn;
  final VoidCallback? onCreateAccount;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('guest-appointments-screen'),
    body: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 44, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MY CARE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Your appointments',
              key: const Key('appointments-title'),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  color: AppColors.mintSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sign in to manage your visits',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 9),
            const Text(
              'View upcoming appointments, reschedule visits and access your check-in code securely.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('guest-appointments-sign-in'),
                onPressed: onSignIn,
                child: const Text('Sign in'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('guest-appointments-create-account'),
                onPressed: onCreateAccount,
                child: const Text('Create account'),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}

class _LoadingAppointments extends StatelessWidget {
  const _LoadingAppointments();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 100),
    child: Center(
      child: Text(
        'Loading your care schedule…',
        style: TextStyle(color: AppColors.muted),
      ),
    ),
  );
}

class _AppointmentsError extends StatelessWidget {
  const _AppointmentsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('appointments-error'),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFB84C4C)),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, height: 1.4),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? Colors.white : Colors.transparent,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.ink : AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? AppColors.mintSoft : Colors.white54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 20, 32, 120),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 94,
          height: 94,
          decoration: const BoxDecoration(
            color: AppColors.blueSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_available_outlined,
            color: Color(0xFF5276D8),
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Nothing here yet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your appointments will appear here when they are available.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
      ],
    ),
  );
}
