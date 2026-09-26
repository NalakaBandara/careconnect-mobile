import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';

abstract final class AppointmentsPreviewData {
  static const appointments = [
    CareAppointment(
      id: '4821',
      patientId: 'preview-patient',
      doctor: AppointmentDoctor(
        id: '1',
        firstName: 'Arun',
        lastName: 'Mehta',
        licenseNumber: 'SLMC 12458',
      ),
      clinic: AppointmentClinic(id: '1', name: 'Northgate Medical Centre'),
      service: AppointmentService(
        id: '1',
        name: 'General consultation',
        durationMinutes: 20,
      ),
      doctorScheduleId: 'preview-schedule-1',
      appointmentDate: '2027-09-18',
      startTime: '09:30',
      endTime: '09:50',
      status: AppointmentStatus.confirmed,
      reason: 'Routine health check-up',
    ),
    CareAppointment(
      id: '4827',
      patientId: 'preview-patient',
      doctor: AppointmentDoctor(
        id: '3',
        firstName: 'Maya',
        lastName: 'Fernando',
        licenseNumber: 'SLMC 15102',
      ),
      clinic: AppointmentClinic(id: '3', name: 'Harbour Wellness Clinic'),
      service: AppointmentService(
        id: '6',
        name: 'Skin consultation',
        durationMinutes: 20,
      ),
      doctorScheduleId: 'preview-schedule-3',
      appointmentDate: '2027-09-21',
      startTime: '14:30',
      endTime: '14:50',
      status: AppointmentStatus.pending,
      reason: 'Skin irritation review',
    ),
    CareAppointment(
      id: '4790',
      patientId: 'preview-patient',
      doctor: AppointmentDoctor(
        id: '2',
        firstName: 'Senuri',
        lastName: 'Perera',
        licenseNumber: 'SLMC 13881',
      ),
      clinic: AppointmentClinic(id: '2', name: 'Lakeside Health'),
      service: AppointmentService(
        id: '4',
        name: 'Cardiology consultation',
        durationMinutes: 30,
      ),
      doctorScheduleId: 'preview-schedule-2',
      appointmentDate: '2026-09-10',
      startTime: '11:00',
      endTime: '11:30',
      status: AppointmentStatus.completed,
      reason: 'Heart health review',
    ),
  ];
}
