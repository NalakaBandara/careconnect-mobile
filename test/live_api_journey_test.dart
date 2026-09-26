import 'dart:io';

import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/auth/domain/auth_session.dart';
import 'package:careconnect_mobile/features/booking/data/booking_repository.dart';
import 'package:careconnect_mobile/features/booking/domain/appointment_booking.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_repository.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final liveEnabled =
      Platform.environment['CARECONNECT_RUN_LIVE_E2E']?.toLowerCase() == 'true';

  test(
    'live patient booking, admin check-in, and completion journey',
    () async {
      final patientEmail = _requiredEnvironment('CARECONNECT_PATIENT_EMAIL');
      final patientPassword = _requiredEnvironment(
        'CARECONNECT_PATIENT_PASSWORD',
      );
      final adminEmail = _requiredEnvironment('CARECONNECT_ADMIN_EMAIL');
      final adminPassword = _requiredEnvironment('CARECONNECT_ADMIN_PASSWORD');

      final patientSession = await _login(patientEmail, patientPassword);
      final adminSession = await _login(adminEmail, adminPassword);
      expect(
        adminSession.user.isAdmin,
        isTrue,
        reason: 'The configured admin account does not have the ADMIN role.',
      );

      final patientClient = ApiClient(
        accessTokenProvider: () async => patientSession.accessToken,
      );
      final adminClient = ApiClient(
        accessTokenProvider: () async => adminSession.accessToken,
      );
      final appointments = AppointmentsRepository(patientClient);
      final booking = AppointmentBookingRepository(patientClient);
      final admin = AdminRepository(adminClient);
      CareAppointment? created;
      var reachedFinalStatus = false;

      try {
        final slot = await _findBookableSlot(patientClient);
        created = await booking.createAppointment(
          AppointmentBookingDraft(
            professional: slot.professional,
            clinic: slot.clinic,
            service: slot.service,
            appointmentDate: slot.date,
            dateLabel: slot.date,
            startTime: slot.startTime,
            endTime: slot.endTime,
            doctorScheduleId: slot.scheduleId,
            fullName: patientSession.user.displayName,
            phoneNumber: patientSession.user.phone ?? '',
            reason: 'CareConnect automated live journey',
          ),
        );
        expect(created.status, AppointmentStatus.pending);

        final confirmed = await admin.updateAppointmentStatus(
          created.id,
          AppointmentStatus.confirmed,
          reason: 'Confirmed by CareConnect live journey',
        );
        expect(confirmed.status, AppointmentStatus.confirmed);

        final confirmedPatientView = await appointments.getAppointment(
          created.id,
        );
        expect(confirmedPatientView.status, AppointmentStatus.confirmed);
        expect(
          confirmedPatientView.qrCode?.trim().isNotEmpty,
          isTrue,
          reason: 'The confirmed appointment did not receive a backend QR.',
        );

        final confirmedHistory = await appointments.getAppointmentStatusHistory(
          created.id,
        );
        expect(
          confirmedHistory.any(
            (entry) => entry.status == AppointmentStatus.confirmed,
          ),
          isTrue,
        );

        final checkIn = await admin.createReceptionCheckIn(created.id);
        expect(checkIn.appointmentId, created.id);

        final patientCheckIn = await appointments.getCheckIn(created.id);
        expect(patientCheckIn.appointmentId, created.id);
        expect(patientCheckIn.queueNumber, isNotNull);

        final completed = await admin.updateAppointmentStatus(
          created.id,
          AppointmentStatus.completed,
          reason: 'Completed by CareConnect live journey',
        );
        expect(completed.status, AppointmentStatus.completed);
        reachedFinalStatus = true;

        final finalHistory = await appointments.getAppointmentStatusHistory(
          created.id,
        );
        expect(
          finalHistory.map((entry) => entry.status),
          containsAllInOrder([
            AppointmentStatus.pending,
            AppointmentStatus.confirmed,
            AppointmentStatus.completed,
          ]),
        );
      } finally {
        if (created != null && !reachedFinalStatus) {
          try {
            await admin.updateAppointmentStatus(
              created.id,
              AppointmentStatus.cancelled,
              reason: 'Live journey cleanup after an incomplete run',
            );
          } catch (_) {
            // Preserve the original test failure if cleanup is not possible.
          }
        }
        patientClient.close();
        adminClient.close();
      }
    },
    skip: liveEnabled
        ? false
        : 'Set CARECONNECT_RUN_LIVE_E2E=true and CareConnect test credentials.',
  );
}

Future<AuthSession> _login(String email, String password) async {
  final client = ApiClient(accessTokenProvider: () async => null);
  try {
    final response = await client.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(response as Map<String, dynamic>);
  } finally {
    client.close();
  }
}

Future<_JourneySlot> _findBookableSlot(ApiClient client) async {
  final directory = FindCareRepository(client);
  final doctors = await directory.getDoctors();

  for (final summary in doctors) {
    final professional = await directory.getProfessionalProfile(summary);
    for (final clinic in professional.clinics) {
      final scheduleResponse = await client.get(
        ApiEndpoints.doctorSchedules(professional.id),
        queryParameters: {'clinicId': clinic.id},
      );
      final schedules = _dataList(
        scheduleResponse,
      ).where((item) => item['isActive'] == true).toList(growable: false);

      for (final schedule in schedules) {
        final date = _nextDate(schedule['dayOfWeek'] as String? ?? '');
        if (date == null) continue;
        for (final service in professional.services) {
          final response = await client.get(
            ApiEndpoints.availableSlots(professional.id),
            queryParameters: {
              'clinicId': clinic.id,
              'serviceId': service.id,
              'date': _isoDate(date),
            },
          );
          final body = response as Map<String, dynamic>;
          final slots = (body['slots'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .where((item) => item['available'] == true)
              .toList(growable: false);
          if (slots.isEmpty) continue;
          final slot = slots.first;
          return _JourneySlot(
            professional: professional,
            clinic: clinic,
            service: service,
            scheduleId: schedule['id'].toString(),
            date: _isoDate(date),
            startTime: slot['startTime'] as String,
            endTime: slot['endTime'] as String,
          );
        }
      }
    }
  }
  throw StateError('No live appointment slot is currently available.');
}

List<Map<String, dynamic>> _dataList(Object? response) {
  final body = response as Map<String, dynamic>;
  return (body['data'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

DateTime? _nextDate(String dayOfWeek) {
  const weekdays = {
    'MONDAY': DateTime.monday,
    'TUESDAY': DateTime.tuesday,
    'WEDNESDAY': DateTime.wednesday,
    'THURSDAY': DateTime.thursday,
    'FRIDAY': DateTime.friday,
    'SATURDAY': DateTime.saturday,
    'SUNDAY': DateTime.sunday,
  };
  final target = weekdays[dayOfWeek.toUpperCase()];
  if (target == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var daysAhead = (target - today.weekday) % 7;
  if (daysAhead == 0) daysAhead = 7;
  return today.add(Duration(days: daysAhead));
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _requiredEnvironment(String key) {
  final value = Platform.environment[key]?.trim() ?? '';
  if (value.isEmpty) {
    throw StateError('$key must be supplied outside source control.');
  }
  return value;
}

class _JourneySlot {
  const _JourneySlot({
    required this.professional,
    required this.clinic,
    required this.service,
    required this.scheduleId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final CareProfessional professional;
  final CareClinicSummary clinic;
  final CareService service;
  final String scheduleId;
  final String date;
  final String startTime;
  final String endTime;
}
