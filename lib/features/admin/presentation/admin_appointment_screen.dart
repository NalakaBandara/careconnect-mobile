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
  late Future<AdminUser> _patient;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    _history = widget.repository.getAppointmentStatusHistory(_appointment.id);
    _patient = widget.repository.getUser(_appointment.patientId);
  }

  void _refreshPatient() {
    setState(() {
      _patient = widget.repository.getUser(_appointment.patientId);
    });
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
            const SizedBox(height: 16),
            _PatientSection(patient: _patient, onRetry: _refreshPatient),
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

class _PatientSection extends StatelessWidget {
  const _PatientSection({required this.patient, required this.onRetry});

  final Future<AdminUser> patient;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<AdminUser>(
    future: patient,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Container(
          key: const Key('admin-patient-loading'),
          height: 132,
          decoration: BoxDecoration(
            color: AppColors.mintSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return _PatientLoadError(onRetry: onRetry);
      }
      return _PatientCard(patient: snapshot.data!);
    },
  );
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final AdminUser patient;

  @override
  Widget build(BuildContext context) {
    final initials = [
      if (patient.firstName.isNotEmpty) patient.firstName[0],
      if (patient.lastName.isNotEmpty) patient.lastName[0],
    ].join();
    final phone = patient.phone?.trim();
    return Container(
      key: const Key('admin-appointment-patient-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  initials.isEmpty ? 'P' : initials.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patient.displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _AccountStatusPill(status: patient.status),
            ],
          ),
          const SizedBox(height: 15),
          _PatientContactRow(
            icon: Icons.mail_outline_rounded,
            value: patient.email.isEmpty ? 'Email unavailable' : patient.email,
          ),
          const SizedBox(height: 9),
          _PatientContactRow(
            icon: Icons.phone_outlined,
            value: phone?.isNotEmpty == true ? phone! : 'Phone unavailable',
          ),
        ],
      ),
    );
  }
}

class _PatientContactRow extends StatelessWidget {
  const _PatientContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: AppColors.primary),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _AccountStatusPill extends StatelessWidget {
  const _AccountStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status.toUpperCase() == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0xFFFFE8E4),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: active ? AppColors.primary : const Color(0xFFB84C4C),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PatientLoadError extends StatelessWidget {
  const _PatientLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('admin-patient-error'),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.person_off_outlined, color: Color(0xFFB84C4C)),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient details unavailable',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text(
                'The appointment is still available for review.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
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
