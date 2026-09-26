import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointment_ui.dart';
import 'package:careconnect_mobile/features/appointments/presentation/cancel_appointment_screen.dart';
import 'package:careconnect_mobile/features/appointments/presentation/check_in_screen.dart';
import 'package:careconnect_mobile/features/appointments/presentation/reschedule_appointment_screen.dart';
import 'package:flutter/material.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({
    super.key,
    required this.initialAppointment,
    required this.onChanged,
    this.repository,
  });

  final CareAppointment initialAppointment;
  final ValueChanged<CareAppointment> onChanged;
  final AppointmentsDataSource? repository;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late CareAppointment _appointment = widget.initialAppointment;
  Future<List<AppointmentStatusHistoryEntry>>? _history;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _history = widget.repository!.getAppointmentStatusHistory(
        _appointment.id,
      );
      _refreshAppointment();
    }
  }

  void _refreshHistory() {
    if (widget.repository == null) return;
    setState(() {
      _history = widget.repository!.getAppointmentStatusHistory(
        _appointment.id,
      );
    });
  }

  Future<void> _refreshAppointment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final appointment = await widget.repository!.getAppointment(
        _appointment.id,
      );
      if (!mounted) return;
      setState(() => _appointment = appointment);
      widget.onChanged(appointment);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'The latest appointment details could not be loaded.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reschedule() async {
    final updated = await Navigator.of(context).push<CareAppointment>(
      MaterialPageRoute(
        builder: (_) => RescheduleAppointmentScreen(
          appointment: _appointment,
          repository: widget.repository,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _appointment = updated);
    widget.onChanged(updated);
    _refreshHistory();
  }

  Future<void> _cancel() async {
    final updated = await Navigator.of(context).push<CareAppointment>(
      MaterialPageRoute(
        builder: (_) => CancelAppointmentScreen(
          appointment: _appointment,
          repository: widget.repository,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _appointment = updated);
    widget.onChanged(updated);
    _refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointment;
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment details')),
      body: ListView(
        key: const Key('appointment-detail-screen'),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
        children: [
          _AppointmentHero(appointment: appointment),
          if (_isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _DetailError(message: _error!, onRetry: _refreshAppointment),
          ],
          const SizedBox(height: 18),
          _InformationCard(appointment: appointment),
          if (appointment.reason?.isNotEmpty ?? false) ...[
            const SizedBox(height: 14),
            _ReasonCard(reason: appointment.reason!),
          ],
          if (_history != null) ...[
            const SizedBox(height: 22),
            _StatusHistorySection(history: _history!, onRetry: _refreshHistory),
          ],
          if (appointment.status == AppointmentStatus.confirmed) ...[
            const SizedBox(height: 14),
            _CheckInCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CheckInScreen(
                    appointment: appointment,
                    repository: widget.repository,
                  ),
                ),
              ),
            ),
          ],
          if (appointment.canChange) ...[
            const SizedBox(height: 26),
            FilledButton.icon(
              key: const Key('reschedule-appointment-button'),
              onPressed: _reschedule,
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Choose another time'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('cancel-appointment-button'),
              onPressed: _cancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel appointment'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusHistorySection extends StatelessWidget {
  const _StatusHistorySection({required this.history, required this.onRetry});

  final Future<List<AppointmentStatusHistoryEntry>> history;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('patient-appointment-status-history'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Appointment journey',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 5),
      const Text(
        'Follow each update from your clinic.',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<AppointmentStatusHistoryEntry>>(
        future: history,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _HistoryLoading();
          }
          if (snapshot.hasError) {
            return _HistoryMessage(
              key: const Key('patient-status-history-error'),
              icon: Icons.sync_problem_rounded,
              title: 'Journey unavailable',
              message: 'We could not load the latest appointment updates.',
              actionLabel: 'Retry',
              onAction: onRetry,
            );
          }
          final entries = snapshot.data ?? const [];
          if (entries.isEmpty) {
            return const _HistoryMessage(
              key: Key('patient-status-history-empty'),
              icon: Icons.history_toggle_off_rounded,
              title: 'No updates yet',
              message: 'Clinic status changes will appear here.',
            );
          }
          return Container(
            key: const Key('patient-status-history-list'),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++)
                  _PatientHistoryRow(
                    entry: entries[index],
                    isLast: index == entries.length - 1,
                  ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _PatientHistoryRow extends StatelessWidget {
  const _PatientHistoryRow({required this.entry, required this.isLast});

  final AppointmentStatusHistoryEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _historyColor(entry.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 10 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.status.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _historyDateLabel(entry.createdAt),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  if (entry.reason?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.reason!.trim(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('patient-status-history-loading'),
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(
      color: AppColors.mintSoft,
      borderRadius: BorderRadius.all(Radius.circular(22)),
    ),
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.mintSoft,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                message,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}

Color _historyColor(AppointmentStatus status) => switch (status) {
  AppointmentStatus.cancelled ||
  AppointmentStatus.noShow => const Color(0xFFB84C4C),
  AppointmentStatus.completed => const Color(0xFF3567C8),
  _ => AppColors.primary,
};

String _historyDateLabel(DateTime? value) {
  if (value == null) return 'Time unavailable';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} · '
      '${two(local.hour)}:${two(local.minute)}';
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        const Icon(Icons.sync_problem_rounded, color: Color(0xFFB84C4C)),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _AppointmentHero extends StatelessWidget {
  const _AppointmentHero({required this.appointment});
  final CareAppointment appointment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryDark, AppColors.primary],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppointmentStatusPill(status: appointment.status),
        const SizedBox(height: 22),
        Row(
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Text(
                appointment.doctor.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctor.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.service.name,
                    style: const TextStyle(
                      color: Color(0xFFD8F3EC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.appointment});
  final CareAppointment appointment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        _InformationRow(
          icon: Icons.calendar_today_outlined,
          label: 'Date',
          value: appointmentDateLabel(appointment.appointmentDate),
        ),
        _InformationRow(
          icon: Icons.schedule_outlined,
          label: 'Time',
          value: '${appointment.startTime} – ${appointment.endTime}',
        ),
        _InformationRow(
          icon: Icons.location_on_outlined,
          label: 'Clinic',
          value: appointment.clinic.name,
        ),
        _InformationRow(
          icon: Icons.confirmation_number_outlined,
          label: 'Reference',
          value: appointment.reference,
          showDivider: false,
        ),
      ],
    ),
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.mintSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (showDivider) const Divider(height: 1),
    ],
  );
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason});
  final String reason;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason for visit',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(reason, style: const TextStyle(color: AppColors.muted)),
      ],
    ),
  );
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.mintSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 34),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready for your visit?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text(
                'Open secure check-in on arrival.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('open-check-in-button'),
          onPressed: onTap,
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ],
    ),
  );
}
