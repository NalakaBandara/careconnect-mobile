import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:flutter/material.dart';

class AdminClinicOperationsScreen extends StatefulWidget {
  const AdminClinicOperationsScreen({
    required this.clinic,
    required this.services,
    required this.users,
    required this.repository,
    super.key,
  });

  final AdminClinic clinic;
  final List<CareService> services;
  final List<AdminUser> users;
  final AdminDataSource repository;

  @override
  State<AdminClinicOperationsScreen> createState() =>
      _AdminClinicOperationsScreenState();
}

class _AdminClinicOperationsScreenState
    extends State<AdminClinicOperationsScreen> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinic setup')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clinic.name,
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${widget.clinic.addressLine1}, ${widget.clinic.city}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Hours')),
                        ButtonSegment(value: 1, label: Text('Services')),
                        ButtonSegment(value: 2, label: Text('Staff')),
                      ],
                      selected: {_section},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) =>
                          setState(() => _section = value.single),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _section,
                children: [
                  _HoursSection(
                    clinicId: widget.clinic.id,
                    repository: widget.repository,
                  ),
                  _ServicesSection(
                    clinicId: widget.clinic.id,
                    allServices: widget.services,
                    repository: widget.repository,
                  ),
                  _StaffSection(
                    clinicId: widget.clinic.id,
                    allUsers: widget.users,
                    repository: widget.repository,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoursSection extends StatefulWidget {
  const _HoursSection({required this.clinicId, required this.repository});

  final String clinicId;
  final AdminDataSource repository;

  @override
  State<_HoursSection> createState() => _HoursSectionState();
}

class _HoursSectionState extends State<_HoursSection> {
  late Future<List<AdminClinicOperatingHour>> _request;
  Map<String, AdminClinicOperatingHour>? _hours;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _request = widget.repository.getClinicOperatingHours(widget.clinicId);
  }

  Map<String, AdminClinicOperatingHour> _completeWeek(
    List<AdminClinicOperatingHour> values,
  ) {
    final existing = {for (final value in values) value.dayOfWeek: value};
    return {
      for (final day in _days)
        day:
            existing[day] ??
            AdminClinicOperatingHour(dayOfWeek: day, isClosed: true),
    };
  }

  Future<void> _chooseTime(String day, {required bool opening}) async {
    final hour = _hours![day]!;
    final currentValue = opening ? hour.openingTime : hour.closingTime;
    final initial =
        _parseTime(currentValue) ??
        (opening
            ? const TimeOfDay(hour: 9, minute: 0)
            : const TimeOfDay(hour: 17, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final value = _formatTime(picked);
    setState(() {
      _hours![day] = AdminClinicOperatingHour(
        id: hour.id,
        dayOfWeek: day,
        openingTime: opening ? value : hour.openingTime,
        closingTime: opening ? hour.closingTime : value,
        isClosed: false,
      );
    });
  }

  void _toggleDay(String day, bool open) {
    final hour = _hours![day]!;
    setState(() {
      _hours![day] = AdminClinicOperatingHour(
        id: hour.id,
        dayOfWeek: day,
        openingTime: open ? hour.openingTime ?? '09:00' : hour.openingTime,
        closingTime: open ? hour.closingTime ?? '17:00' : hour.closingTime,
        isClosed: !open,
      );
    });
  }

  Future<void> _save() async {
    final invalidDay = _hours!.values.where((hour) {
      if (hour.isClosed) return false;
      final opening = _toMinutes(hour.openingTime!);
      final closing = _toMinutes(hour.closingTime!);
      return closing <= opening;
    }).firstOrNull;
    if (invalidDay != null) {
      _showError('${_label(invalidDay.dayOfWeek)} closing time must be later.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.updateClinicOperatingHours(
        widget.clinicId,
        _days.map((day) => _hours![day]!).toList(growable: false),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Operating hours saved.')));
      }
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Operating hours could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminClinicOperatingHour>>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _FailureState(
            message: 'Operating hours could not be loaded.',
            onRetry: () => setState(() {
              _request = widget.repository.getClinicOperatingHours(
                widget.clinicId,
              );
            }),
          );
        }
        _hours ??= _completeWeek(snapshot.data ?? const []);
        return ListView(
          key: const Key('admin-clinic-hours'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            const Text(
              'Set the public opening hours used by patients when choosing care.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            for (final day in _days)
              _DayHoursCard(
                hour: _hours![day]!,
                onOpenChanged: (open) => _toggleDay(day, open),
                onOpeningTap: () => _chooseTime(day, opening: true),
                onClosingTap: () => _chooseTime(day, opening: false),
              ),
            const SizedBox(height: 10),
            FilledButton(
              key: const Key('admin-save-clinic-hours'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save operating hours'),
            ),
          ],
        );
      },
    );
  }
}

class _ServicesSection extends StatefulWidget {
  const _ServicesSection({
    required this.clinicId,
    required this.allServices,
    required this.repository,
  });

  final String clinicId;
  final List<CareService> allServices;
  final AdminDataSource repository;

  @override
  State<_ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<_ServicesSection> {
  late Future<List<CareService>> _request;
  Set<String>? _selected;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _request = widget.repository.getClinicServices(widget.clinicId);
  }

  Future<void> _toggle(String id, bool selected) async {
    if (_busyId != null) return;
    setState(() => _busyId = id);
    try {
      if (selected) {
        await widget.repository.addClinicService(widget.clinicId, id);
      } else {
        await widget.repository.removeClinicService(widget.clinicId, id);
      }
      if (mounted) {
        setState(() => selected ? _selected!.add(id) : _selected!.remove(id));
      }
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('The clinic service could not be updated.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<CareService>>(
    future: _request,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _FailureState(
          message: 'Clinic services could not be loaded.',
          onRetry: () => setState(() {
            _request = widget.repository.getClinicServices(widget.clinicId);
          }),
        );
      }
      _selected ??= (snapshot.data ?? const []).map((item) => item.id).toSet();
      return ListView(
        key: const Key('admin-clinic-services'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        children: [
          const Text(
            'Select the services patients can book at this clinic.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (widget.allServices.isEmpty)
            const _InfoCard(message: 'No services are configured.')
          else
            ...widget.allServices.map(
              (service) => CheckboxListTile(
                key: Key('admin-clinic-service-${service.id}'),
                value: _selected!.contains(service.id),
                onChanged: _busyId == null
                    ? (value) => _toggle(service.id, value ?? false)
                    : null,
                title: Text(service.name),
                subtitle: service.durationMinutes == null
                    ? null
                    : Text('${service.durationMinutes} minutes'),
                secondary: _busyId == service.id
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Icon(Icons.medical_services_outlined),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      );
    },
  );
}

class _StaffSection extends StatefulWidget {
  const _StaffSection({
    required this.clinicId,
    required this.allUsers,
    required this.repository,
  });

  final String clinicId;
  final List<AdminUser> allUsers;
  final AdminDataSource repository;

  @override
  State<_StaffSection> createState() => _StaffSectionState();
}

class _StaffSectionState extends State<_StaffSection> {
  late Future<List<AdminUser>> _request;
  Set<String>? _selected;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _request = widget.repository.getClinicUsers(widget.clinicId);
  }

  Future<void> _toggle(AdminUser user, bool selected) async {
    if (_busyId != null) return;
    if (!selected) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove clinic access?'),
          content: Text(
            '${user.displayName} will no longer be linked to this clinic. Their account role is not changed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep access'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove access'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busyId = user.id);
    try {
      if (selected) {
        await widget.repository.addClinicUser(widget.clinicId, user.id);
      } else {
        await widget.repository.removeClinicUser(widget.clinicId, user.id);
      }
      if (mounted) {
        setState(
          () => selected ? _selected!.add(user.id) : _selected!.remove(user.id),
        );
      }
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Clinic staff access could not be updated.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<AdminUser>>(
    future: _request,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _FailureState(
          message: 'Clinic staff could not be loaded.',
          onRetry: () => setState(() {
            _request = widget.repository.getClinicUsers(widget.clinicId);
          }),
        );
      }
      _selected ??= (snapshot.data ?? const []).map((user) => user.id).toSet();
      return ListView(
        key: const Key('admin-clinic-staff'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        children: [
          const _InfoCard(
            message:
                'Clinic access and account roles are separate. Assign STAFF or CLINIC_ADMIN from the user access screen when required.',
          ),
          const SizedBox(height: 12),
          ...widget.allUsers.map(
            (user) => CheckboxListTile(
              key: Key('admin-clinic-user-${user.id}'),
              value: _selected!.contains(user.id),
              onChanged: _busyId == null
                  ? (value) => _toggle(user, value ?? false)
                  : null,
              title: Text(user.displayName),
              subtitle: Text(
                '${user.email}\n${user.roles.isEmpty ? 'No role assigned' : user.roles.join(' · ')}',
              ),
              isThreeLine: true,
              secondary: _busyId == user.id
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.badge_outlined),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      );
    },
  );
}

class _DayHoursCard extends StatelessWidget {
  const _DayHoursCard({
    required this.hour,
    required this.onOpenChanged,
    required this.onOpeningTap,
    required this.onClosingTap,
  });

  final AdminClinicOperatingHour hour;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onOpeningTap;
  final VoidCallback onClosingTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _label(hour.dayOfWeek),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              hour.isClosed ? 'Closed' : 'Open',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Switch.adaptive(value: !hour.isClosed, onChanged: onOpenChanged),
          ],
        ),
        if (!hour.isClosed) ...[
          const Divider(),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'Opens',
                  value: hour.openingTime ?? '09:00',
                  onTap: onOpeningTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeButton(
                  label: 'Closes',
                  value: hour.closingTime ?? '17:00',
                  onTap: onClosingTap,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
        Text(value),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.mintSoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.muted, height: 1.4),
    ),
  );
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

TimeOfDay? _parseTime(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTime(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

int _toMinutes(String value) {
  final parts = value.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String _label(String value) => value
    .toLowerCase()
    .split('_')
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
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
