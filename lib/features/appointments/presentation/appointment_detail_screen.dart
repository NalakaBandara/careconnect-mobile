import 'package:careconnect_mobile/core/theme/app_theme.dart';
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
  });

  final CareAppointment initialAppointment;
  final ValueChanged<CareAppointment> onChanged;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late CareAppointment _appointment = widget.initialAppointment;

  Future<void> _reschedule() async {
    final updated = await Navigator.of(context).push<CareAppointment>(
      MaterialPageRoute(
        builder: (_) => RescheduleAppointmentScreen(appointment: _appointment),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _appointment = updated);
    widget.onChanged(updated);
  }

  Future<void> _cancel() async {
    final updated = await Navigator.of(context).push<CareAppointment>(
      MaterialPageRoute(
        builder: (_) => CancelAppointmentScreen(appointment: _appointment),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _appointment = updated);
    widget.onChanged(updated);
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
          const SizedBox(height: 18),
          _InformationCard(appointment: appointment),
          if (appointment.reason?.isNotEmpty ?? false) ...[
            const SizedBox(height: 14),
            _ReasonCard(reason: appointment.reason!),
          ],
          if (appointment.status == AppointmentStatus.confirmed) ...[
            const SizedBox(height: 14),
            _CheckInCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CheckInScreen(appointment: appointment),
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
