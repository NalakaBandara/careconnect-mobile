import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';

abstract interface class AdminDataSource {
  Future<AdminDashboardSnapshot> getDashboard();

  Future<void> createDoctor({
    required String userId,
    String? licenseNumber,
    String? bio,
    int? yearsOfExperience,
    required bool isVerified,
    required List<String> specialtyIds,
    required List<String> clinicIds,
  });

  Future<void> updateDoctor({
    required String id,
    String? bio,
    int? yearsOfExperience,
    required bool isVerified,
  });

  Future<void> createClinic(AdminClinic clinic);

  Future<void> updateClinic(AdminClinic clinic, {String? status});
}

class AdminRepository implements AdminDataSource {
  const AdminRepository(this._client);

  final ApiClient _client;

  @override
  Future<AdminDashboardSnapshot> getDashboard() async {
    final responses = await Future.wait<Object?>([
      _client.get(
        ApiEndpoints.users,
        queryParameters: const {'page': 1, 'pageSize': 100},
      ),
      _client.get(ApiEndpoints.doctors),
      _client.get(ApiEndpoints.clinics),
      _client.get(ApiEndpoints.appointments),
      _client.get(ApiEndpoints.specialties),
    ]);

    final usersBody = _objectMap(responses[0]);
    final doctorsBody = _objectMap(responses[1]);
    final clinicsBody = _objectMap(responses[2]);
    final appointmentsBody = _objectMap(responses[3]);
    final specialtiesBody = _objectMap(responses[4]);
    final users = _dataList(usersBody).map(AdminUser.fromJson).toList();
    final appointments = _dataList(
      appointmentsBody,
    ).map(CareAppointment.fromJson).toList();

    return AdminDashboardSnapshot(
      users: users,
      totalUsers: _paginationTotal(usersBody) ?? users.length,
      doctors: _dataList(doctorsBody).map(AdminDoctor.fromJson).toList(),
      clinics: _dataList(clinicsBody).map(AdminClinic.fromJson).toList(),
      specialties: _dataList(
        specialtiesBody,
      ).map(CareSpecialty.fromJson).toList(),
      appointments: appointments,
    );
  }

  @override
  Future<void> createDoctor({
    required String userId,
    String? licenseNumber,
    String? bio,
    int? yearsOfExperience,
    required bool isVerified,
    required List<String> specialtyIds,
    required List<String> clinicIds,
  }) async {
    await _client.post(
      ApiEndpoints.doctors,
      body: {
        'userId': userId,
        if (licenseNumber?.trim().isNotEmpty ?? false)
          'licenseNumber': licenseNumber!.trim(),
        if (bio?.trim().isNotEmpty ?? false) 'bio': bio!.trim(),
        'yearsOfExperience': yearsOfExperience,
        'isVerified': isVerified,
        'specialtyIds': specialtyIds,
        'clinicIds': clinicIds,
      },
    );
  }

  @override
  Future<void> updateDoctor({
    required String id,
    String? bio,
    int? yearsOfExperience,
    required bool isVerified,
  }) async {
    await _client.put(
      ApiEndpoints.doctor(id),
      body: {
        'bio': bio?.trim(),
        'yearsOfExperience': yearsOfExperience,
        'isVerified': isVerified,
      },
    );
  }

  @override
  Future<void> createClinic(AdminClinic clinic) async {
    await _client.post(ApiEndpoints.clinics, body: clinic.toRequestJson());
  }

  @override
  Future<void> updateClinic(AdminClinic clinic, {String? status}) async {
    await _client.put(
      ApiEndpoints.clinic(clinic.id),
      body: clinic.toRequestJson(statusOverride: status),
    );
  }

  static Map<String, dynamic> _objectMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Invalid admin API response');
  }

  static Iterable<Map<String, dynamic>> _dataList(Map<String, dynamic> body) =>
      (body['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();

  static int? _paginationTotal(Map<String, dynamic> body) {
    final pagination = body['pagination'];
    if (pagination is Map<String, dynamic>) {
      return pagination['total'] as int?;
    }
    return null;
  }
}
