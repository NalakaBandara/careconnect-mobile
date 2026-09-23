import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
    required this.status,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final String status;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'CareConnect user' : name;
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'].toString(),
    email: json['email'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    roles: (json['roles'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
    status: json['status'] as String? ?? 'UNKNOWN',
  );
}

class AdminDashboardSnapshot {
  const AdminDashboardSnapshot({
    required this.users,
    required this.totalUsers,
    required this.doctorCount,
    required this.clinicCount,
    required this.appointments,
  });

  final List<AdminUser> users;
  final int totalUsers;
  final int doctorCount;
  final int clinicCount;
  final List<CareAppointment> appointments;

  int get pendingAppointmentCount => appointments
      .where((item) => item.status == AppointmentStatus.pending)
      .length;
}
