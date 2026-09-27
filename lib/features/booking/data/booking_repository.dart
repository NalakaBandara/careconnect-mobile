import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/booking/domain/appointment_booking.dart';

abstract interface class AppointmentBookingDataSource {
  Future<CareAppointment> createAppointment(AppointmentBookingDraft booking);
}

class AppointmentBookingRepository implements AppointmentBookingDataSource {
  const AppointmentBookingRepository(this._client);

  final ApiClient _client;

  @override
  Future<CareAppointment> createAppointment(
    AppointmentBookingDraft booking,
  ) async {
    final response = await _client.post(
      ApiEndpoints.appointments,
      body: booking.toApiJson(),
    );
    final created = _appointmentFromResponse(response);
    if (created.status != AppointmentStatus.pending) return created;

    final confirmedResponse = await _client.patch(
      ApiEndpoints.appointmentStatus(created.id),
      body: const {
        'status': 'CONFIRMED',
        'reason': 'Automatically confirmed when booked',
      },
    );
    return _appointmentFromResponse(confirmedResponse);
  }

  CareAppointment _appointmentFromResponse(Object? response) {
    if (response case {'data': final Map<String, dynamic> data}) {
      return CareAppointment.fromJson(data);
    }
    return CareAppointment.fromJson(response as Map<String, dynamic>);
  }
}
