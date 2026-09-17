import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';

class AppointmentBookingDraft {
  const AppointmentBookingDraft({
    required this.professional,
    required this.clinic,
    required this.service,
    required this.appointmentDate,
    required this.dateLabel,
    required this.startTime,
    required this.endTime,
    required this.doctorScheduleId,
    required this.fullName,
    required this.phoneNumber,
    this.reason,
    this.notes,
  });

  final CareProfessional professional;
  final CareClinicSummary clinic;
  final CareService service;
  final String appointmentDate;
  final String dateLabel;
  final String startTime;
  final String endTime;
  final String doctorScheduleId;
  final String fullName;
  final String phoneNumber;
  final String? reason;
  final String? notes;

  /// Matches POST /api/v1/appointments. Patient contact data belongs to the
  /// signed-in user profile and is intentionally not duplicated in this body.
  Map<String, dynamic> toApiJson() => {
    'doctorProfileId': professional.id,
    'clinicId': clinic.id,
    'serviceId': service.id,
    'doctorScheduleId': doctorScheduleId,
    'appointmentDate': appointmentDate,
    'startTime': startTime,
    'endTime': endTime,
    if (reason?.trim().isNotEmpty ?? false) 'reason': reason!.trim(),
    if (notes?.trim().isNotEmpty ?? false) 'notes': notes!.trim(),
  };
}

String calculateEndTime(String startTime, int durationMinutes) {
  final parts = startTime.split(':');
  final startMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
  final endMinutes = startMinutes + durationMinutes;
  final hours = (endMinutes ~/ 60) % 24;
  final minutes = endMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}
