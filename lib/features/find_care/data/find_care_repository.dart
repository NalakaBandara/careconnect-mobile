import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';

abstract interface class FindCareDataSource {
  Future<List<CareSpecialty>> getSpecialties();

  Future<List<CareProfessional>> getDoctors({
    String? specialtyId,
    String? clinicId,
  });

  Future<CareProfessional> getProfessionalProfile(CareProfessional summary);

  Future<List<CareAvailabilityPreview>> getUpcomingAvailability({
    required String doctorId,
    required String clinicId,
    int days = 7,
  });
}

class FindCareRepository implements FindCareDataSource {
  const FindCareRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<CareSpecialty>> getSpecialties() async {
    final response = await _client.get(ApiEndpoints.specialties);
    return _listFromResponse(response).map(CareSpecialty.fromJson).toList();
  }

  Future<List<CareClinicSummary>> getClinics() async {
    final response = await _client.get(ApiEndpoints.clinics);
    return _listFromResponse(response).map(CareClinicSummary.fromJson).toList();
  }

  @override
  Future<List<CareProfessional>> getDoctors({
    String? specialtyId,
    String? clinicId,
  }) async {
    final responses = await Future.wait<Object?>([
      _client.get(
        ApiEndpoints.doctors,
        queryParameters: {'specialtyId': ?specialtyId, 'clinicId': ?clinicId},
      ),
      _client.get(ApiEndpoints.clinics),
    ]);
    final clinics = _listFromResponse(
      responses[1],
    ).map(CareClinicSummary.fromJson).toList();
    final clinicById = {for (final clinic in clinics) clinic.id: clinic};
    return _listFromResponse(responses[0])
        .map((json) {
          final doctor = CareProfessional.fromJson(json);
          return doctor.copyWith(
            clinics: doctor.clinics
                .map((clinic) => clinicById[clinic.id] ?? clinic)
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  Future<CareProfessional> getDoctor(String id) async {
    final response = await _client.get(ApiEndpoints.doctor(id));
    return CareProfessional.fromJson(response as Map<String, dynamic>);
  }

  Future<List<CareService>> getDoctorServices(String doctorId) async {
    final response = await _client.get(
      ApiEndpoints.services,
      queryParameters: {'doctorId': doctorId},
    );
    return _listFromResponse(response).map(CareService.fromJson).toList();
  }

  Future<CareAvailabilityPreview> getAvailableSlots({
    required String doctorId,
    required String clinicId,
    required DateTime date,
    String? serviceId,
  }) async {
    final isoDate = _isoDate(date);
    final response = await _client.get(
      ApiEndpoints.availableSlots(doctorId),
      queryParameters: {
        'clinicId': clinicId,
        'date': isoDate,
        'serviceId': ?serviceId,
      },
    );
    final body = response as Map<String, dynamic>;
    final slots = (body['slots'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((slot) => slot['available'] == true)
        .map((slot) => slot['startTime'] as String)
        .toList(growable: false);
    return CareAvailabilityPreview(
      day: _dayLabel(date),
      date: '${_months[date.month - 1]} ${date.day}',
      isoDate: isoDate,
      times: slots,
    );
  }

  @override
  Future<CareProfessional> getProfessionalProfile(
    CareProfessional summary,
  ) async {
    final results = await Future.wait<Object>([
      getDoctor(summary.id),
      getDoctorServices(summary.id),
      getClinics(),
    ]);
    final doctor = results[0] as CareProfessional;
    final services = results[1] as List<CareService>;
    final allClinics = results[2] as List<CareClinicSummary>;
    final clinicById = {for (final clinic in allClinics) clinic.id: clinic};
    final clinics = doctor.clinics
        .map((clinic) => clinicById[clinic.id] ?? clinic)
        .toList(growable: false);
    return doctor.copyWith(clinics: clinics, services: services);
  }

  @override
  Future<List<CareAvailabilityPreview>> getUpcomingAvailability({
    required String doctorId,
    required String clinicId,
    int days = 7,
  }) async {
    final today = DateTime.now();
    final dates = List.generate(
      days,
      (index) => DateTime(today.year, today.month, today.day + index),
    );
    final availability = await Future.wait(
      dates.map(
        (date) => getAvailableSlots(
          doctorId: doctorId,
          clinicId: clinicId,
          date: date,
        ),
      ),
    );
    return availability
        .where((day) => day.times.isNotEmpty)
        .toList(growable: false);
  }
}

List<Map<String, dynamic>> _listFromResponse(Object? response) {
  final body = response as Map<String, dynamic>;
  return (body['data'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _dayLabel(DateTime date) {
  final current = DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final target = DateTime(date.year, date.month, date.day);
  final difference = target.difference(today).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Tomorrow';
  return _weekdays[date.weekday - 1];
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
