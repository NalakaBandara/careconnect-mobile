import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_endpoints.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/domain/check_in_record.dart';
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

  Future<List<AdminDoctorSchedule>> getDoctorSchedules(String doctorId);

  Future<void> addDoctorSpecialty(String doctorId, String specialtyId);

  Future<void> removeDoctorSpecialty(String doctorId, String specialtyId);

  Future<void> addDoctorClinic(String doctorId, String clinicId);

  Future<void> removeDoctorClinic(String doctorId, String clinicId);

  Future<void> createDoctorSchedule(
    String doctorId,
    AdminDoctorSchedule schedule,
  );

  Future<void> updateDoctorSchedule(
    String doctorId,
    AdminDoctorSchedule schedule,
  );

  Future<List<AdminAppointmentStatusEntry>> getAppointmentStatusHistory(
    String appointmentId,
  );

  Future<CareAppointment> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    String? reason,
  });

  Future<List<AdminRole>> getRoles();

  Future<void> assignUserRole(String userId, String roleId);

  Future<List<AdminAuditLog>> getAuditLogs({
    String? userId,
    String? entityType,
  });

  Future<List<AdminClinicOperatingHour>> getClinicOperatingHours(
    String clinicId,
  );

  Future<void> updateClinicOperatingHours(
    String clinicId,
    List<AdminClinicOperatingHour> hours,
  );

  Future<List<CareService>> getClinicServices(String clinicId);

  Future<void> addClinicService(String clinicId, String serviceId);

  Future<void> removeClinicService(String clinicId, String serviceId);

  Future<List<AdminUser>> getClinicUsers(String clinicId);

  Future<void> addClinicUser(String clinicId, String userId);

  Future<void> removeClinicUser(String clinicId, String userId);

  Future<CareSpecialty> saveSpecialty({
    String? id,
    required String name,
    String? description,
  });

  Future<CareService> saveService({
    String? id,
    required String name,
    String? description,
    int? durationMinutes,
    required String status,
  });

  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
  });

  Future<CareAppointment> getAppointment(String appointmentId);

  Future<CheckInRecord> createReceptionCheckIn(String appointmentId);
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
      _client.get(ApiEndpoints.services),
    ]);

    final usersBody = _objectMap(responses[0]);
    final doctorsBody = _objectMap(responses[1]);
    final clinicsBody = _objectMap(responses[2]);
    final appointmentsBody = _objectMap(responses[3]);
    final specialtiesBody = _objectMap(responses[4]);
    final servicesBody = _objectMap(responses[5]);
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
      services: _dataList(servicesBody).map(CareService.fromJson).toList(),
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

  @override
  Future<List<AdminDoctorSchedule>> getDoctorSchedules(String doctorId) async {
    final response = await _client.get(ApiEndpoints.doctorSchedules(doctorId));
    return _dataList(
      _objectMap(response),
    ).map(AdminDoctorSchedule.fromJson).toList(growable: false);
  }

  @override
  Future<void> addDoctorSpecialty(String doctorId, String specialtyId) async {
    await _client.post(
      ApiEndpoints.doctorSpecialties(doctorId),
      body: {'specialtyId': specialtyId},
    );
  }

  @override
  Future<void> removeDoctorSpecialty(
    String doctorId,
    String specialtyId,
  ) async {
    await _client.delete(ApiEndpoints.doctorSpecialty(doctorId, specialtyId));
  }

  @override
  Future<void> addDoctorClinic(String doctorId, String clinicId) async {
    await _client.post(
      ApiEndpoints.doctorClinics(doctorId),
      body: {'clinicId': clinicId},
    );
  }

  @override
  Future<void> removeDoctorClinic(String doctorId, String clinicId) async {
    await _client.delete(ApiEndpoints.doctorClinic(doctorId, clinicId));
  }

  @override
  Future<void> createDoctorSchedule(
    String doctorId,
    AdminDoctorSchedule schedule,
  ) async {
    await _client.post(
      ApiEndpoints.doctorSchedules(doctorId),
      body: schedule.toRequestJson(),
    );
  }

  @override
  Future<void> updateDoctorSchedule(
    String doctorId,
    AdminDoctorSchedule schedule,
  ) async {
    await _client.put(
      ApiEndpoints.doctorSchedule(doctorId, schedule.id),
      body: schedule.toRequestJson(),
    );
  }

  @override
  Future<List<AdminAppointmentStatusEntry>> getAppointmentStatusHistory(
    String appointmentId,
  ) async {
    final response = await _client.get(
      ApiEndpoints.appointmentStatusHistory(appointmentId),
    );
    return _dataList(
      _objectMap(response),
    ).map(AdminAppointmentStatusEntry.fromJson).toList(growable: false);
  }

  @override
  Future<CareAppointment> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    String? reason,
  }) async {
    final response = await _client.patch(
      ApiEndpoints.appointmentStatus(appointmentId),
      body: {
        'status': status.apiValue,
        if (reason?.trim().isNotEmpty ?? false) 'reason': reason!.trim(),
      },
    );
    return CareAppointment.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<AdminRole>> getRoles() async {
    final response = await _client.get(ApiEndpoints.roles);
    return _dataList(
      _objectMap(response),
    ).map(AdminRole.fromJson).toList(growable: false);
  }

  @override
  Future<void> assignUserRole(String userId, String roleId) async {
    await _client.post(
      ApiEndpoints.userRoles,
      body: {'userId': userId, 'roleId': roleId},
    );
  }

  @override
  Future<List<AdminAuditLog>> getAuditLogs({
    String? userId,
    String? entityType,
  }) async {
    final response = await _client.get(
      ApiEndpoints.auditLogs,
      queryParameters: {
        if (userId?.trim().isNotEmpty ?? false) 'userId': userId!.trim(),
        if (entityType?.trim().isNotEmpty ?? false)
          'entityType': entityType!.trim(),
      },
    );
    return _dataList(
      _objectMap(response),
    ).map(AdminAuditLog.fromJson).toList(growable: false);
  }

  @override
  Future<List<AdminClinicOperatingHour>> getClinicOperatingHours(
    String clinicId,
  ) async {
    final response = await _client.get(
      ApiEndpoints.clinicOperatingHours(clinicId),
    );
    return _dataList(
      _objectMap(response),
    ).map(AdminClinicOperatingHour.fromJson).toList(growable: false);
  }

  @override
  Future<void> updateClinicOperatingHours(
    String clinicId,
    List<AdminClinicOperatingHour> hours,
  ) async {
    await _client.put(
      ApiEndpoints.clinicOperatingHours(clinicId),
      body: {'hours': hours.map((hour) => hour.toRequestJson()).toList()},
    );
  }

  @override
  Future<List<CareService>> getClinicServices(String clinicId) async {
    final response = await _client.get(ApiEndpoints.clinicServices(clinicId));
    return _dataList(
      _objectMap(response),
    ).map(CareService.fromJson).toList(growable: false);
  }

  @override
  Future<void> addClinicService(String clinicId, String serviceId) async {
    await _client.post(
      ApiEndpoints.clinicServices(clinicId),
      body: {'serviceId': serviceId},
    );
  }

  @override
  Future<void> removeClinicService(String clinicId, String serviceId) async {
    await _client.delete(ApiEndpoints.clinicService(clinicId, serviceId));
  }

  @override
  Future<List<AdminUser>> getClinicUsers(String clinicId) async {
    final response = await _client.get(ApiEndpoints.clinicUsers(clinicId));
    return _dataList(
      _objectMap(response),
    ).map(AdminUser.fromJson).toList(growable: false);
  }

  @override
  Future<void> addClinicUser(String clinicId, String userId) async {
    await _client.post(
      ApiEndpoints.clinicUsers(clinicId),
      body: {'userId': userId},
    );
  }

  @override
  Future<void> removeClinicUser(String clinicId, String userId) async {
    await _client.delete(ApiEndpoints.clinicUser(clinicId, userId));
  }

  @override
  Future<CareSpecialty> saveSpecialty({
    String? id,
    required String name,
    String? description,
  }) async {
    final body = {
      'name': name.trim(),
      if (description?.trim().isNotEmpty ?? false)
        'description': description!.trim(),
    };
    final response = id == null
        ? await _client.post(ApiEndpoints.specialties, body: body)
        : await _client.put(ApiEndpoints.specialty(id), body: body);
    return CareSpecialty.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CareService> saveService({
    String? id,
    required String name,
    String? description,
    int? durationMinutes,
    required String status,
  }) async {
    final body = {
      'name': name.trim(),
      if (description?.trim().isNotEmpty ?? false)
        'description': description!.trim(),
      'durationMinutes': durationMinutes,
      'status': status,
    };
    final response = id == null
        ? await _client.post(ApiEndpoints.services, body: body)
        : await _client.put(ApiEndpoints.service(id), body: body);
    return CareService.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
  }) async {
    await _client.post(
      ApiEndpoints.notifications,
      body: {
        'userId': userId,
        'type': type,
        'title': title.trim(),
        'message': message.trim(),
      },
    );
  }

  @override
  Future<CareAppointment> getAppointment(String appointmentId) async {
    final response = await _client.get(ApiEndpoints.appointment(appointmentId));
    return CareAppointment.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<CheckInRecord> createReceptionCheckIn(String appointmentId) async {
    final response = await _client.post(
      ApiEndpoints.appointmentCheckIn(appointmentId),
      body: const {'method': 'RECEPTION_QR'},
    );
    return CheckInRecord.fromJson(response as Map<String, dynamic>);
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
