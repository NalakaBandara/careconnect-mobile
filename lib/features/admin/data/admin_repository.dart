import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';

abstract interface class AdminDataSource {
  Future<AdminDashboardSnapshot> getDashboard();
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
    ]);

    final usersBody = _objectMap(responses[0]);
    final doctorsBody = _objectMap(responses[1]);
    final clinicsBody = _objectMap(responses[2]);
    final appointmentsBody = _objectMap(responses[3]);
    final users = _dataList(usersBody).map(AdminUser.fromJson).toList();
    final appointments = _dataList(
      appointmentsBody,
    ).map(CareAppointment.fromJson).toList();

    return AdminDashboardSnapshot(
      users: users,
      totalUsers: _paginationTotal(usersBody) ?? users.length,
      doctorCount: _dataList(doctorsBody).length,
      clinicCount: _dataList(clinicsBody).length,
      appointments: appointments,
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
