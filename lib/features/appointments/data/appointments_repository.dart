import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';

class AppointmentsRepository {
  const AppointmentsRepository(this._client);

  final ApiClient _client;

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

  Future<CareAppointment> getAppointment(String id) async {
    final response = await _client.get(ApiEndpoints.appointment(id));
    return CareAppointment.fromJson(response as Map<String, dynamic>);
  }

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
}
