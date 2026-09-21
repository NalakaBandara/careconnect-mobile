import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/booking/data/booking_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/booking/domain/appointment_booking.dart';
import 'package:careconnect_mobile/features/booking/presentation/booking_confirmation_screen.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:flutter/material.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({
    super.key,
    required this.professional,
    this.repository,
    this.currentUser,
    this.onAppointmentCreated,
    this.onViewAppointments,
    this.initialClinicIndex = 0,
    this.initialDayIndex = 0,
    this.initialTime,
  });

  final CareProfessional professional;
  final AppointmentBookingDataSource? repository;
  final CurrentUser? currentUser;
  final ValueChanged<CareAppointment>? onAppointmentCreated;
  final VoidCallback? onViewAppointments;
  final int initialClinicIndex;
  final int initialDayIndex;
  final String? initialTime;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  int _step = 0;
  int _serviceIndex = 0;
  late int _clinicIndex;
  late int _dayIndex;
  String? _time;
  bool _isSubmitting = false;
  String? _submitError;

  CareProfessional get professional => widget.professional;
  CareService get service => professional.services[_serviceIndex];
  CareClinicSummary get clinic => professional.clinics[_clinicIndex];
  CareAvailabilityPreview get availability =>
      professional.availability[_dayIndex];
  bool get _isPreview => widget.repository == null;

  @override
  void initState() {
    super.initState();
    _clinicIndex = widget.initialClinicIndex.clamp(
      0,
      professional.clinics.length - 1,
    );
    _dayIndex = widget.initialDayIndex.clamp(
      0,
      professional.availability.length - 1,
    );
    _time = widget.initialTime;
    final user = widget.currentUser;
    if (user != null) {
      _nameController.text = user.displayName;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  void _continue() {
    if (_step == 0) {
      if (_time == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choose an available time to continue.'),
          ),
        );
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (!(_detailsFormKey.currentState?.validate() ?? false)) return;
      setState(() => _step = 2);
      return;
    }
    _submitRequest();
  }

  AppointmentBookingDraft _buildDraft() {
    final duration = service.durationMinutes ?? 20;
    final scheduleId = availability.doctorScheduleId;
    final slotEndTime = availability.endTimeFor(_time!);
    return AppointmentBookingDraft(
      professional: professional,
      clinic: clinic,
      service: service,
      appointmentDate: availability.isoDate,
      dateLabel: '${availability.day}, ${availability.date}',
      startTime: _time!,
      endTime: slotEndTime ?? calculateEndTime(_time!, duration),
      doctorScheduleId: scheduleId ?? 'preview-schedule-id',
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      reason: _reasonController.text,
      notes: _notesController.text,
    );
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;
    if (!_isPreview &&
        (availability.doctorScheduleId == null ||
            availability.endTimeFor(_time!) == null)) {
      setState(() {
        _submitError =
            'This time cannot be booked safely because its schedule details are incomplete. Please choose another time.';
      });
      return;
    }
    final draft = _buildDraft();
    if (_isPreview) {
      final reference =
          'CC-${professional.id.padLeft(3, '0')}-${availability.isoDate.replaceAll('-', '')}';
      _openConfirmation(draft, reference);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      final appointment = await widget.repository!.createAppointment(draft);
      if (!mounted) return;
      widget.onAppointmentCreated?.call(appointment);
      _openConfirmation(draft, appointment.reference);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.fieldError('startTime') ?? error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError =
            'We could not send your appointment request. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openConfirmation(AppointmentBookingDraft draft, String reference) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BookingConfirmationScreen(
          booking: draft,
          reference: reference,
          onViewAppointments: widget.onViewAppointments,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            ['Choose appointment', 'Your details', 'Review request'][_step],
          ),
        ),
        body: Column(
          children: [
            _ProgressHeader(currentStep: _step),
            Expanded(
              child: IndexedStack(
                index: _step,
                children: [_slotStep(), _detailsStep(), _reviewStep()],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_submitError != null) ...[
                Text(
                  _submitError!,
                  key: const Key('booking-submit-error'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.coral, fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: Key(
                    _step == 2
                        ? 'confirm-booking-button'
                        : 'booking-continue-button',
                  ),
                  onPressed: _isSubmitting ? null : _continue,
                  child: Text(
                    _isSubmitting
                        ? 'Sending request…'
                        : _step == 2
                        ? 'Send appointment request'
                        : 'Continue',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotStep() {
    return ListView(
      key: const Key('booking-slot-step'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      children: [
        _DoctorStrip(professional: professional),
        const SizedBox(height: 26),
        const _Heading(title: 'What do you need help with?'),
        const SizedBox(height: 12),
        ...List.generate(
          professional.services.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectCard(
              key: ValueKey('booking-service-$index'),
              selected: index == _serviceIndex,
              icon: Icons.health_and_safety_outlined,
              title: professional.services[index].name,
              subtitle:
                  '${professional.services[index].durationMinutes ?? 20} minutes',
              onTap: () => setState(() => _serviceIndex = index),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _Heading(title: 'Practice location'),
        const SizedBox(height: 12),
        ...(_isPreview
                ? List.generate(professional.clinics.length, (index) => index)
                : [_clinicIndex])
            .map(
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SelectCard(
                  selected: index == _clinicIndex,
                  icon: Icons.location_on_outlined,
                  title: professional.clinics[index].name,
                  subtitle:
                      professional.clinics[index].city ??
                      'Location to be confirmed',
                  onTap: () => setState(() => _clinicIndex = index),
                ),
              ),
            ),
        const SizedBox(height: 16),
        const _Heading(title: 'Choose a day'),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: professional.availability.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final item = professional.availability[index];
              return ChoiceChip(
                selected: index == _dayIndex,
                showCheckmark: false,
                label: Text('${item.day} · ${item.date}'),
                onSelected: (_) => setState(() {
                  _dayIndex = index;
                  _time = null;
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: availability.times
              .map(
                (time) => ChoiceChip(
                  key: ValueKey('booking-time-$time'),
                  selected: _time == time,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _time == time ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  label: Text(time),
                  onSelected: (_) => setState(() => _time = time),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _detailsStep() {
    return Form(
      key: _detailsFormKey,
      child: ListView(
        key: const Key('booking-details-step'),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: [
          const _Heading(title: 'Tell the clinic who is visiting'),
          const SizedBox(height: 6),
          const Text(
            'These details are used for this request and can be checked before sending.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('booking-name-field'),
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full name',
              hintText: 'Enter patient name',
            ),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Enter the patient name'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('booking-phone-field'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Contact number',
              hintText: 'e.g. 077 123 4567',
            ),
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 9 ? 'Enter a valid contact number' : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('booking-reason-field'),
            controller: _reasonController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Reason for visit (optional)',
              hintText: 'Briefly describe the concern',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Anything the clinic should know? (optional)',
            ),
          ),
          const SizedBox(height: 18),
          const _PrivacyNote(),
        ],
      ),
    );
  }

  Widget _reviewStep() {
    final duration = service.durationMinutes ?? 20;
    return ListView(
      key: const Key('booking-review-step'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      children: [
        const _Heading(title: 'Everything look right?'),
        const SizedBox(height: 6),
        const Text(
          'Review the details before sending your request.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        _ReviewCard(
          children: [
            _ReviewRow(label: 'Professional', value: professional.displayName),
            _ReviewRow(label: 'Service', value: service.name),
            _ReviewRow(label: 'Clinic', value: clinic.name),
            _ReviewRow(
              label: 'Date',
              value: '${availability.day}, ${availability.date}',
            ),
            _ReviewRow(
              label: 'Time',
              value: '$_time – ${calculateEndTime(_time!, duration)}',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ReviewCard(
          children: [
            _ReviewRow(label: 'Patient', value: _nameController.text.trim()),
            _ReviewRow(label: 'Contact', value: _phoneController.text.trim()),
            if (_reasonController.text.trim().isNotEmpty)
              _ReviewRow(label: 'Reason', value: _reasonController.text.trim()),
          ],
        ),
        const SizedBox(height: 18),
        const _PrivacyNote(),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Appointment', 'Details', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == labels.length - 1 ? 0 : 7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 5,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? AppColors.primaryDark : AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DoctorStrip extends StatelessWidget {
  const _DoctorStrip({required this.professional});
  final CareProfessional professional;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              professional.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  professional.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  professional.primarySpecialty,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
  );
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mintSoft : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, color: Color(0xFF5276D8), size: 20),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'Your details are shared only with the selected clinic for this appointment request.',
            style: TextStyle(color: AppColors.ink, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(children: children),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
