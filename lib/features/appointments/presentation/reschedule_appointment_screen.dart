import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:flutter/material.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  const RescheduleAppointmentScreen({super.key, required this.appointment});
  final CareAppointment appointment;

  @override
  State<RescheduleAppointmentScreen> createState() =>
      _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState
    extends State<RescheduleAppointmentScreen> {
  static const _days = [
    (label: 'Tomorrow', date: '2026-09-18'),
    (label: 'Monday', date: '2026-09-21'),
    (label: 'Wednesday', date: '2026-09-23'),
  ];
  static const _times = ['09:00', '09:30', '10:30', '14:00'];

  int _selectedDay = 0;
  String? _selectedTime;

  void _confirm() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a new time to continue.')),
      );
      return;
    }
    final updated = widget.appointment.copyWith(
      appointmentDate: _days[_selectedDay].date,
      startTime: _selectedTime,
      endTime: _endTime(
        _selectedTime!,
        widget.appointment.service.durationMinutes,
      ),
      status: AppointmentStatus.pending,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose a new time')),
    body: ListView(
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
          height: 47,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) => ChoiceChip(
              key: ValueKey('reschedule-day-$index'),
              selected: index == _selectedDay,
              showCheckmark: false,
              label: Text(_days[index].label),
              onSelected: (_) => setState(() {
                _selectedDay = index;
                _selectedTime = null;
              }),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Available times',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ..._times.map(
          (time) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('reschedule-time-$time'),
              onPressed: () => setState(() => _selectedTime = time),
              style: OutlinedButton.styleFrom(
                backgroundColor: _selectedTime == time
                    ? AppColors.primary
                    : Colors.white,
                foregroundColor: _selectedTime == time
                    ? Colors.white
                    : AppColors.ink,
                side: BorderSide(
                  color: _selectedTime == time
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Text(time),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1D2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF93600A)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Preview only: the current backend does not yet accept new date and time fields when updating an appointment.',
                  style: TextStyle(
                    color: Color(0xFF76500D),
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
          onPressed: _confirm,
          child: const Text('Confirm new time'),
        ),
      ],
    ),
  );

  String _endTime(String start, int minutes) {
    final parts = start.split(':');
    final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
    return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
  }
}
