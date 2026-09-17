import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointment_ui.dart';
import 'package:flutter/material.dart';

class CancelAppointmentScreen extends StatefulWidget {
  const CancelAppointmentScreen({super.key, required this.appointment});
  final CareAppointment appointment;

  @override
  State<CancelAppointmentScreen> createState() =>
      _CancelAppointmentScreenState();
}

class _CancelAppointmentScreenState extends State<CancelAppointmentScreen> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirmCancellation() {
    final updated = widget.appointment.copyWith(
      status: AppointmentStatus.cancelled,
      reason: _reasonController.text.trim().isEmpty
          ? widget.appointment.reason
          : _reasonController.text.trim(),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cancel appointment')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_busy_outlined,
                  color: Color(0xFFB84C4C),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cancel this appointment?',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.appointment.doctor.displayName} · ${appointmentDateLabel(widget.appointment.appointmentDate)} at ${widget.appointment.startTime}',
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              TextField(
                key: const Key('cancellation-reason-field'),
                controller: _reasonController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Tell the clinic why you need to cancel',
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('confirm-cancellation-button'),
                onPressed: _confirmCancellation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB84C4C),
                ),
                child: const Text('Yes, cancel appointment'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Keep appointment'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This preview updates the app locally. The real action will use PATCH /appointments/:id after authentication is connected.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
        ),
      ],
    ),
  );
}
