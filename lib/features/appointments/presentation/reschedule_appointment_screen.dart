import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:flutter/material.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  const RescheduleAppointmentScreen({
    super.key,
    required this.appointment,
    this.repository,
  });

  final CareAppointment appointment;
  final AppointmentsDataSource? repository;

  @override
  State<RescheduleAppointmentScreen> createState() =>
      _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState
    extends State<RescheduleAppointmentScreen> {
  late final List<DateTime> _days;
  List<AppointmentTimeSlot> _slots = const [];
  int _selectedDay = 0;
  AppointmentTimeSlot? _selectedSlot;
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  String? _error;

  bool get _isPreview => widget.repository == null;
  DateTime get _selectedDate => _days[_selectedDay];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day + index + 1),
    );
    if (_isPreview) {
      _slots = _previewSlots;
    } else {
      _loadSlots();
    }
  }

  Future<void> _selectDay(int index) async {
    setState(() {
      _selectedDay = index;
      _selectedSlot = null;
      _error = null;
      if (_isPreview) _slots = _previewSlots;
    });
    if (!_isPreview) await _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _error = null;
      _slots = const [];
    });
    try {
      final slots = await widget.repository!.getAvailableSlots(
        appointment: widget.appointment,
        date: _isoDate(_selectedDate),
      );
      if (!mounted) return;
      setState(() => _slots = slots);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Available times could not be loaded. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _confirm() async {
    final selected = _selectedSlot;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a new time to continue.')),
      );
      return;
    }

    if (_isPreview) {
      Navigator.of(context).pop(
        widget.appointment.copyWith(
          appointmentDate: _isoDate(_selectedDate),
          startTime: selected.startTime,
          endTime: selected.endTime,
          status: AppointmentStatus.pending,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final updated = await widget.repository!.rescheduleAppointment(
        widget.appointment.id,
        appointmentDate: _isoDate(_selectedDate),
        startTime: selected.startTime,
        endTime: selected.endTime,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        await _loadSlots();
        if (mounted) {
          setState(
            () => _error =
                'That time was just booked. Choose another available time.',
          );
        }
      } else {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'This appointment could not be rescheduled. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose a new time')),
    body: ListView(
      key: const Key('reschedule-screen'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          widget.appointment.doctor.displayName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          widget.appointment.clinic.name,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final date = _days[index];
              return ChoiceChip(
                key: ValueKey('reschedule-day-$index'),
                selected: index == _selectedDay,
                showCheckmark: false,
                label: Text('${_dayLabel(date)}\n${date.day} ${_month(date)}'),
                labelStyle: const TextStyle(height: 1.35),
                onSelected: _isSubmitting ? null : (_) => _selectDay(index),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Available times',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
            ),
            if (_isLoadingSlots)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          _RescheduleError(message: _error!, onRetry: _loadSlots),
          const SizedBox(height: 12),
        ],
        if (!_isLoadingSlots && _slots.isEmpty && _error == null)
          Container(
            key: const Key('reschedule-empty-slots'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'No appointments are available on this day. Try another date.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
        ..._slots.map(
          (slot) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('reschedule-time-${slot.startTime}'),
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _selectedSlot = slot),
              style: OutlinedButton.styleFrom(
                backgroundColor: _selectedSlot == slot
                    ? AppColors.primary
                    : Colors.white,
                foregroundColor: _selectedSlot == slot
                    ? Colors.white
                    : AppColors.ink,
                side: BorderSide(
                  color: _selectedSlot == slot
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Text('${slot.startTime} – ${slot.endTime}'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.mintSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isPreview
                      ? 'Preview mode updates this appointment locally.'
                      : 'The clinic will receive your new appointment date and time immediately.',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          key: const Key('confirm-reschedule-button'),
          onPressed: _isSubmitting || _isLoadingSlots ? null : _confirm,
          child: Text(_isSubmitting ? 'Rescheduling…' : 'Confirm new time'),
        ),
      ],
    ),
  );
}

class _RescheduleError extends StatelessWidget {
  const _RescheduleError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('reschedule-error'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EE),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.sync_problem_rounded, color: Color(0xFFB84C4C)),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 11))),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

const _previewSlots = [
  AppointmentTimeSlot(startTime: '09:00', endTime: '09:20'),
  AppointmentTimeSlot(startTime: '09:30', endTime: '09:50'),
  AppointmentTimeSlot(startTime: '10:30', endTime: '10:50'),
  AppointmentTimeSlot(startTime: '14:00', endTime: '14:20'),
];

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _dayLabel(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return weekdays[date.weekday - 1];
}

String _month(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[date.month - 1];
}
