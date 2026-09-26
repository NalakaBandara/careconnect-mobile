import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/domain/check_in_record.dart';

abstract interface class AppointmentsDataSource {
  Future<List<CareAppointment>> getMyAppointments({
    AppointmentStatus? status,
    String? fromDate,
    String? toDate,
  });

  Future<CareAppointment> getAppointment(String id);

  Future<List<AppointmentStatusHistoryEntry>> getAppointmentStatusHistory(
    String id,
  );

  Future<CareAppointment> cancelAppointment(String id, {String? reason});

  Future<List<AppointmentTimeSlot>> getAvailableSlots({
    required CareAppointment appointment,
    required String date,
  });

  Future<CareAppointment> rescheduleAppointment(
    String id, {
    required String appointmentDate,
    required String startTime,
    required String endTime,
  });

  Future<CheckInRecord> getCheckIn(String appointmentId);
}

class AppointmentsRepository implements AppointmentsDataSource {
  const AppointmentsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<CareAppointment>> getMyAppointments({
    AppointmentStatus? status,
    String? fromDate,
    String? toDate,
  }) async {
    final response = await _client.get(
      ApiEndpoints.myAppointments,
      queryParameters: {
        if (status != null) 'status': status.apiValue,
        'fromDate': ?fromDate,
        'toDate': ?toDate,
      },
    );
    final body = response as Map<String, dynamic>;
    return (body['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CareAppointment.fromJson)
        .toList(growable: false);
  }

  @override
  Future<CareAppointment> getAppointment(String id) async {
    final response = await _client.get(ApiEndpoints.appointment(id));
    return CareAppointment.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<AppointmentStatusHistoryEntry>> getAppointmentStatusHistory(
    String id,
  ) async {
    final response = await _client.get(
      ApiEndpoints.appointmentStatusHistory(id),
    );
    final body = response as Map<String, dynamic>;
    return (body['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AppointmentStatusHistoryEntry.fromJson)
        .toList(growable: false);
  }

  @override
  Future<CareAppointment> cancelAppointment(String id, {String? reason}) async {
    final response = await _client.patch(
      ApiEndpoints.appointment(id),
      body: {
        'status': AppointmentStatus.cancelled.apiValue,
        if (reason?.trim().isNotEmpty ?? false) 'reason': reason!.trim(),
      },
    );
    return CareAppointment.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<AppointmentTimeSlot>> getAvailableSlots({
    required CareAppointment appointment,
    required String date,
  }) async {
    final response = await _client.get(
      ApiEndpoints.availableSlots(appointment.doctor.id),
      queryParameters: {
        'clinicId': appointment.clinic.id,
        'serviceId': appointment.service.id,
        'date': date,
      },
    );
    final body = response as Map<String, dynamic>;
    return (body['slots'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((slot) => slot['available'] == true)
        .map(AppointmentTimeSlot.fromJson)
        .toList(growable: false);
  }

  @override
  Future<CareAppointment> rescheduleAppointment(
    String id, {
    required String appointmentDate,
    required String startTime,
    required String endTime,
  }) async {
    final response = await _client.patch(
      ApiEndpoints.appointment(id),
      body: {
        'appointmentDate': appointmentDate,
        'startTime': startTime,
        'endTime': endTime,
      },
    );
    return CareAppointment.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CheckInRecord> getCheckIn(String appointmentId) async {
    final response = await _client.get(
      ApiEndpoints.appointmentCheckIn(appointmentId),
    );
    return CheckInRecord.fromJson(response as Map<String, dynamic>);
  }

  /// Records arrival immediately. Opening the code screen must not call this.
  Future<CheckInRecord> createCheckIn(
    String appointmentId, {
    required String method,
  }) async {
    final response = await _client.post(
      ApiEndpoints.appointmentCheckIn(appointmentId),
      body: {'method': method},
    );
    return CheckInRecord.fromJson(response as Map<String, dynamic>);
  }
}
