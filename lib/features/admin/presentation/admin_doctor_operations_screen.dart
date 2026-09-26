import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:flutter/material.dart';

class AdminDoctorOperationsScreen extends StatefulWidget {
  const AdminDoctorOperationsScreen({
    required this.doctor,
    required this.clinics,
    required this.specialties,
    required this.repository,
    required this.onChanged,
    super.key,
  });

  final AdminDoctor doctor;
  final List<AdminClinic> clinics;
  final List<CareSpecialty> specialties;
  final AdminDataSource repository;
  final Future<void> Function() onChanged;

  @override
  State<AdminDoctorOperationsScreen> createState() =>
      _AdminDoctorOperationsScreenState();
}

class _AdminDoctorOperationsScreenState
    extends State<AdminDoctorOperationsScreen> {
  late final Set<String> _clinicIds;
  late final Set<String> _specialtyIds;
  late Future<List<AdminDoctorSchedule>> _schedules;
  String? _busyAssignment;

  @override
  void initState() {
    super.initState();
    _clinicIds = widget.doctor.clinics.map((item) => item.id).toSet();
    _specialtyIds = widget.doctor.specialties.map((item) => item.id).toSet();
    _schedules = widget.repository.getDoctorSchedules(widget.doctor.id);
  }

  Future<void> _toggleSpecialty(String id, bool selected) async {
    await _changeAssignment(
      key: 'specialty-$id',
      request: () => selected
          ? widget.repository.addDoctorSpecialty(widget.doctor.id, id)
          : widget.repository.removeDoctorSpecialty(widget.doctor.id, id),
      apply: () => selected ? _specialtyIds.add(id) : _specialtyIds.remove(id),
    );
  }

  Future<void> _toggleClinic(String id, bool selected) async {
    await _changeAssignment(
      key: 'clinic-$id',
      request: () => selected
          ? widget.repository.addDoctorClinic(widget.doctor.id, id)
          : widget.repository.removeDoctorClinic(widget.doctor.id, id),
      apply: () => selected ? _clinicIds.add(id) : _clinicIds.remove(id),
    );
  }

  Future<void> _changeAssignment({
    required String key,
    required Future<void> Function() request,
    required VoidCallback apply,
  }) async {
    if (_busyAssignment != null) return;
    setState(() => _busyAssignment = key);
    try {
      await request();
      if (!mounted) return;
      setState(apply);
      await widget.onChanged();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('The assignment could not be updated.');
    } finally {
      if (mounted) setState(() => _busyAssignment = null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<AdminClinic> get _assignedClinics => widget.clinics
      .where((clinic) => _clinicIds.contains(clinic.id))
      .toList(growable: false);

  Future<void> _openSchedule([AdminDoctorSchedule? schedule]) async {
    if (_assignedClinics.isEmpty) {
      _showError('Assign at least one clinic before creating a schedule.');
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminScheduleFormScreen(
          doctorId: widget.doctor.id,
          clinics: _assignedClinics,
          repository: widget.repository,
          schedule: schedule,
        ),
      ),
    );
    if (changed == true) {
      setState(() {
        _schedules = widget.repository.getDoctorSchedules(widget.doctor.id);
      });
      await widget.onChanged();
    }
  }

  Future<void> _toggleSchedule(
    AdminDoctorSchedule schedule,
    bool active,
  ) async {
    final updated = AdminDoctorSchedule(
      id: schedule.id,
      clinicId: schedule.clinicId,
      dayOfWeek: schedule.dayOfWeek,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      slotDurationMinutes: schedule.slotDurationMinutes,
      isActive: active,
    );
    try {
      await widget.repository.updateDoctorSchedule(widget.doctor.id, updated);
      setState(() {
        _schedules = widget.repository.getDoctorSchedules(widget.doctor.id);
      });
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor setup')),
      body: SafeArea(
        child: ListView(
          key: const Key('admin-doctor-operations'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              widget.doctor.displayName,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 29),
            ),
            const SizedBox(height: 6),
            Text(
              widget.doctor.licenseNumber ?? 'No license number recorded',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              title: 'Specialties',
              subtitle: 'Choose the care areas shown on this profile.',
            ),
            const SizedBox(height: 12),
            _AssignmentChips(
              items: widget.specialties
                  .map((item) => MapEntry(item.id, item.name))
                  .toList(),
              selected: _specialtyIds,
              busyKey: _busyAssignment,
              keyPrefix: 'specialty',
              emptyMessage: 'No specialties are configured.',
              onChanged: _toggleSpecialty,
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              title: 'Clinic assignments',
              subtitle: 'Schedules can only use clinics assigned here.',
            ),
            const SizedBox(height: 12),
            _AssignmentChips(
              items: widget.clinics
                  .map((item) => MapEntry(item.id, item.name))
                  .toList(),
              selected: _clinicIds,
              busyKey: _busyAssignment,
              keyPrefix: 'clinic',
              emptyMessage: 'No clinics are configured.',
              onChanged: _toggleClinic,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                const Expanded(
                  child: _SectionTitle(
                    title: 'Weekly schedules',
                    subtitle: 'Working hours used to generate booking slots.',
                  ),
                ),
                IconButton.filled(
                  key: const Key('admin-add-schedule'),
                  tooltip: 'Add schedule',
                  onPressed: _openSchedule,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AdminDoctorSchedule>>(
              future: _schedules,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _MessageCard(
                    message: 'Schedules could not be loaded.',
                    actionLabel: 'Retry',
                    onAction: () => setState(() {
                      _schedules = widget.repository.getDoctorSchedules(
                        widget.doctor.id,
                      );
                    }),
                  );
                }
                final schedules = snapshot.data ?? const [];
                if (schedules.isEmpty) {
                  return const _MessageCard(
                    message: 'No weekly schedules have been added yet.',
                  );
                }
                return Column(
                  children: schedules
                      .map(
                        (schedule) => _ScheduleCard(
                          schedule: schedule,
                          clinicName: widget.clinics
                              .where((clinic) => clinic.id == schedule.clinicId)
                              .map((clinic) => clinic.name)
                              .firstOrNull,
                          onEdit: () => _openSchedule(schedule),
                          onActiveChanged: (active) =>
                              _toggleSchedule(schedule, active),
                        ),
                      )
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

class AdminScheduleFormScreen extends StatefulWidget {
  const AdminScheduleFormScreen({
    required this.doctorId,
    required this.clinics,
    required this.repository,
    this.schedule,
    super.key,
  });

  final String doctorId;
  final List<AdminClinic> clinics;
  final AdminDataSource repository;
  final AdminDoctorSchedule? schedule;

  @override
  State<AdminScheduleFormScreen> createState() =>
      _AdminScheduleFormScreenState();
}

class _AdminScheduleFormScreenState extends State<AdminScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _clinicId;
  late String _day;
  late final TextEditingController _startTime;
  late final TextEditingController _endTime;
  late int _duration;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    _clinicId = schedule?.clinicId ?? widget.clinics.first.id;
    _day = schedule?.dayOfWeek ?? 'MONDAY';
    _startTime = TextEditingController(text: schedule?.startTime ?? '09:00');
    _endTime = TextEditingController(text: schedule?.endTime ?? '17:00');
    _duration = schedule?.slotDurationMinutes ?? 30;
    _active = schedule?.isActive ?? true;
  }

  @override
  void dispose() {
    _startTime.dispose();
    _endTime.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_minutes(_endTime.text) <= _minutes(_startTime.text)) {
      setState(() => _error = 'End time must be later than start time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final schedule = AdminDoctorSchedule(
      id: widget.schedule?.id ?? '',
      clinicId: _clinicId,
      dayOfWeek: _day,
      startTime: _startTime.text.trim(),
      endTime: _endTime.text.trim(),
      slotDurationMinutes: _duration,
      isActive: _active,
    );
    try {
      if (widget.schedule == null) {
        await widget.repository.createDoctorSchedule(widget.doctorId, schedule);
      } else {
        await widget.repository.updateDoctorSchedule(widget.doctorId, schedule);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'The schedule could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String? _validateTime(String? value) {
    final text = value?.trim() ?? '';
    final match = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(text);
    return match ? null : 'Use 24-hour time, for example 09:30';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule == null ? 'Add schedule' : 'Edit schedule'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                'Weekly availability',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              const Text(
                'Booking slots are generated between these times.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                key: const Key('admin-schedule-clinic'),
                initialValue: _clinicId,
                decoration: _decoration('Clinic'),
                items: widget.clinics
                    .map(
                      (clinic) => DropdownMenuItem(
                        value: clinic.id,
                        child: Text(clinic.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _clinicId = value!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: const Key('admin-schedule-day'),
                initialValue: _day,
                decoration: _decoration('Day of week'),
                items: _days
                    .map(
                      (day) => DropdownMenuItem(
                        value: day,
                        child: Text(_titleCase(day)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _day = value!),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('admin-schedule-start'),
                      controller: _startTime,
                      keyboardType: TextInputType.datetime,
                      decoration: _decoration('Start time'),
                      validator: _validateTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('admin-schedule-end'),
                      controller: _endTime,
                      keyboardType: TextInputType.datetime,
                      decoration: _decoration('End time'),
                      validator: _validateTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                key: const Key('admin-schedule-duration'),
                initialValue: _duration,
                decoration: _decoration('Appointment duration'),
                items: const [15, 20, 30, 45, 60]
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes minutes'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _duration = value!),
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                value: _active,
                onChanged: (value) => setState(() => _active = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Schedule active'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('admin-save-schedule'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentChips extends StatelessWidget {
  const _AssignmentChips({
    required this.items,
    required this.selected,
    required this.busyKey,
    required this.keyPrefix,
    required this.emptyMessage,
    required this.onChanged,
  });

  final List<MapEntry<String, String>> items;
  final Set<String> selected;
  final String? busyKey;
  final String keyPrefix;
  final String emptyMessage;
  final Future<void> Function(String id, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(emptyMessage, style: const TextStyle(color: AppColors.muted));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) {
            final assignmentKey = '$keyPrefix-${item.key}';
            return FilterChip(
              key: Key('admin-$assignmentKey'),
              label: Text(item.value),
              selected: selected.contains(item.key),
              onSelected: busyKey == null
                  ? (value) => onChanged(item.key, value)
                  : null,
              avatar: busyKey == assignmentKey
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            );
          })
          .toList(growable: false),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.clinicName,
    required this.onEdit,
    required this.onActiveChanged,
  });

  final AdminDoctorSchedule schedule;
  final String? clinicName;
  final VoidCallback onEdit;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: context.careColors.card,
      border: Border.all(color: context.careColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.schedule_rounded, color: Color(0xFF4169B2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleCase(schedule.dayOfWeek),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${schedule.startTime}–${schedule.endTime} · ${schedule.slotDurationMinutes} min',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                clinicName ?? 'Clinic #${schedule.clinicId}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch.adaptive(value: schedule.isActive, onChanged: onActiveChanged),
        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
    ],
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.careColors.card,
      border: Border.all(color: context.careColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(message, style: const TextStyle(color: AppColors.muted)),
        ),
        if (onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.border),
  ),
);

String _titleCase(String value) => value
    .toLowerCase()
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

const _days = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];
