import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:flutter/material.dart';

class AdminAppointmentScreen extends StatefulWidget {
  const AdminAppointmentScreen({
    required this.appointment,
    required this.repository,
    required this.onChanged,
    super.key,
  });

  final CareAppointment appointment;
  final AdminDataSource repository;
  final Future<void> Function() onChanged;

  @override
  State<AdminAppointmentScreen> createState() => _AdminAppointmentScreenState();
}

class _AdminAppointmentScreenState extends State<AdminAppointmentScreen> {
  late CareAppointment _appointment;
  late Future<List<AdminAppointmentStatusEntry>> _history;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    _history = widget.repository.getAppointmentStatusHistory(_appointment.id);
  }

  List<AppointmentStatus> get _availableActions =>
      switch (_appointment.status) {
        AppointmentStatus.pending => const [
          AppointmentStatus.confirmed,
          AppointmentStatus.cancelled,
        ],
        AppointmentStatus.confirmed => const [
          AppointmentStatus.completed,
          AppointmentStatus.noShow,
          AppointmentStatus.cancelled,
        ],
        AppointmentStatus.completed ||
        AppointmentStatus.cancelled ||
        AppointmentStatus.noShow ||
        AppointmentStatus.unknown => const [],
      };

  Future<void> _requestStatus(AppointmentStatus status) async {
    final reasonController = TextEditingController();
    final destructive =
        status == AppointmentStatus.cancelled ||
        status == AppointmentStatus.noShow;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_actionTitle(status)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This changes appointment ${_appointment.reference} to ${status.label.toLowerCase()}.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('admin-appointment-reason'),
              controller: reasonController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason or note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep current status'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm change'),
          ),
        ],
      ),
    );
    final reason = reasonController.text;
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      final updated = await widget.repository.updateAppointmentStatus(
        _appointment.id,
        status,
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _appointment = updated;
        _history = widget.repository.getAppointmentStatusHistory(
          _appointment.id,
        );
      });
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment marked ${status.label.toLowerCase()}.'),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('The appointment status could not be changed.');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment review')),
      body: SafeArea(
        child: ListView(
          key: const Key('admin-appointment-detail'),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _appointment.service.name,
                        style: Theme.of(
                          context,
                        ).textTheme.displaySmall?.copyWith(fontSize: 29),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _appointment.reference,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _AppointmentStatusBadge(status: _appointment.status),
              ],
            ),
            const SizedBox(height: 24),
            _DetailsCard(appointment: _appointment),
            if (_appointment.reason?.trim().isNotEmpty == true ||
                _appointment.notes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _TextCard(
                title: 'Visit information',
                body: [
                  if (_appointment.reason?.trim().isNotEmpty == true)
                    'Reason: ${_appointment.reason}',
                  if (_appointment.notes?.trim().isNotEmpty == true)
                    'Notes: ${_appointment.notes}',
                ].join('\n\n'),
              ),
            ],
            const SizedBox(height: 26),
            Text(
              'Status actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            const Text(
              'Only valid workflow actions are shown for the current status.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (_updating)
              const Center(child: CircularProgressIndicator())
            else if (_availableActions.isEmpty)
              const _TextCard(
                title: 'No further action',
                body: 'This appointment has reached a final status.',
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _availableActions
                    .map(
                      (status) =>
                          status == AppointmentStatus.cancelled ||
                              status == AppointmentStatus.noShow
                          ? OutlinedButton.icon(
                              key: Key('admin-status-${status.apiValue}'),
                              onPressed: () => _requestStatus(status),
                              icon: Icon(_statusIcon(status)),
                              label: Text(_actionTitle(status)),
                            )
                          : FilledButton.icon(
                              key: Key('admin-status-${status.apiValue}'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: () => _requestStatus(status),
                              icon: Icon(_statusIcon(status)),
                              label: Text(_actionTitle(status)),
                            ),
                    )
                    .toList(growable: false),
              ),
            const SizedBox(height: 28),
            Text(
              'Status history',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AdminAppointmentStatusEntry>>(
              future: _history,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _TextCard(
                    title: 'History unavailable',
                    body: 'Pull back and reopen this appointment to try again.',
                  );
                }
                final history = snapshot.data ?? const [];
                if (history.isEmpty) {
                  return const _TextCard(
                    title: 'No history yet',
                    body: 'Status changes will appear here.',
                  );
                }
                return Column(
                  children: history
                      .map((entry) => _HistoryRow(entry: entry))
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.appointment});

  final CareAppointment appointment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Patient',
          value: 'Patient #${appointment.patientId}',
        ),
        _DetailRow(
          icon: Icons.medical_services_outlined,
          label: 'Professional',
          value: appointment.doctor.displayName,
        ),
        _DetailRow(
          icon: Icons.local_hospital_outlined,
          label: 'Clinic',
          value: appointment.clinic.name,
        ),
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Date',
          value: appointment.appointmentDate,
        ),
        _DetailRow(
          icon: Icons.schedule_outlined,
          label: 'Time',
          value: '${appointment.startTime}–${appointment.endTime}',
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final AdminAppointmentStatusEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.status.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (entry.reason?.trim().isNotEmpty == true)
                Text(
                  entry.reason!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              Text(
                '${_formatDateTime(entry.createdAt)} · changed by user #${entry.changedByUserId}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(color: AppColors.muted, height: 1.4)),
      ],
    ),
  );
}

class _AppointmentStatusBadge extends StatelessWidget {
  const _AppointmentStatusBadge({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color:
          status == AppointmentStatus.cancelled ||
              status == AppointmentStatus.noShow
          ? const Color(0xFFFFE8E4)
          : AppColors.mintSoft,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      status.label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );
}

String _actionTitle(AppointmentStatus status) => switch (status) {
  AppointmentStatus.confirmed => 'Confirm appointment',
  AppointmentStatus.completed => 'Mark completed',
  AppointmentStatus.cancelled => 'Cancel appointment',
  AppointmentStatus.noShow => 'Mark no-show',
  _ => status.label,
};

IconData _statusIcon(AppointmentStatus status) => switch (status) {
  AppointmentStatus.confirmed => Icons.check_circle_outline_rounded,
  AppointmentStatus.completed => Icons.task_alt_rounded,
  AppointmentStatus.cancelled => Icons.cancel_outlined,
  AppointmentStatus.noShow => Icons.person_off_outlined,
  _ => Icons.sync_rounded,
};

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Time unavailable';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
