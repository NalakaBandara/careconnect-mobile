import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointment_ui.dart';
import 'package:flutter/material.dart';

class CancelAppointmentScreen extends StatefulWidget {
  const CancelAppointmentScreen({
    super.key,
    required this.appointment,
    this.repository,
  });
  final CareAppointment appointment;
  final AppointmentsDataSource? repository;

  @override
  State<CancelAppointmentScreen> createState() =>
      _CancelAppointmentScreenState();
}

class _CancelAppointmentScreenState extends State<CancelAppointmentScreen> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirmCancellation() async {
    final reason = _reasonController.text.trim();
    if (widget.repository == null) {
      final updated = widget.appointment.copyWith(
        status: AppointmentStatus.cancelled,
        reason: reason.isEmpty ? widget.appointment.reason : reason,
      );
      Navigator.of(context).pop(updated);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final updated = await widget.repository!.cancelAppointment(
        widget.appointment.id,
        reason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(updated);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error =
            'This appointment could not be cancelled. Check its latest status and try again.';
      });
    }
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
            color: context.careColors.card,
            border: Border.all(color: context.careColors.border),
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
              if (_error != null) ...[
                Container(
                  key: const Key('cancellation-error'),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFF9C3F3F),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              FilledButton(
                key: const Key('confirm-cancellation-button'),
                onPressed: _isSubmitting ? null : _confirmCancellation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB84C4C),
                ),
                child: Text(
                  _isSubmitting ? 'Cancelling…' : 'Yes, cancel appointment',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Keep appointment'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.repository == null
              ? 'Preview mode updates this appointment locally.'
              : 'Cancellation is sent securely to the CareConnect appointment API.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
        ),
      ],
    ),
  );
}
