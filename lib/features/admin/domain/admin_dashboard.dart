import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';

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
    required this.doctors,
    required this.clinics,
    required this.specialties,
    required this.appointments,
  });

  final List<AdminUser> users;
  final int totalUsers;
  final List<AdminDoctor> doctors;
  final List<AdminClinic> clinics;
  final List<CareSpecialty> specialties;
  final List<CareAppointment> appointments;

  int get doctorCount => doctors.length;
  int get clinicCount => clinics.length;

  int get pendingAppointmentCount => appointments
      .where((item) => item.status == AppointmentStatus.pending)
      .length;
}

class AdminDoctor {
  const AdminDoctor({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.isVerified,
    required this.specialties,
    required this.clinics,
    this.licenseNumber,
    this.bio,
    this.yearsOfExperience,
  });

  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? licenseNumber;
  final String? bio;
  final int? yearsOfExperience;
  final bool isVerified;
  final List<CareSpecialty> specialties;
  final List<CareClinicSummary> clinics;

  String get displayName => 'Dr. $firstName $lastName'.trim();

  factory AdminDoctor.fromJson(Map<String, dynamic> json) => AdminDoctor(
    id: json['id'].toString(),
    userId: json['userId']?.toString() ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    licenseNumber: json['licenseNumber'] as String?,
    bio: json['bio'] as String?,
    yearsOfExperience: json['yearsOfExperience'] as int?,
    isVerified: json['isVerified'] as bool? ?? false,
    specialties: (json['specialties'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CareSpecialty.fromJson)
        .toList(growable: false),
    clinics: (json['clinics'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CareClinicSummary.fromJson)
        .toList(growable: false),
  );
}

class AdminClinic {
  const AdminClinic({
    required this.id,
    required this.name,
    required this.addressLine1,
    required this.city,
    required this.country,
    required this.status,
    this.description,
    this.addressLine2,
    this.district,
    this.province,
    this.postalCode,
    this.telephone,
    this.email,
  });

  final String id;
  final String name;
  final String? description;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? district;
  final String? province;
  final String? postalCode;
  final String country;
  final String? telephone;
  final String? email;
  final String status;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory AdminClinic.fromJson(Map<String, dynamic> json) => AdminClinic(
    id: json['id'].toString(),
    name: json['name'] as String? ?? 'Clinic',
    description: json['description'] as String?,
    addressLine1: json['addressLine1'] as String? ?? '',
    addressLine2: json['addressLine2'] as String?,
    city: json['city'] as String? ?? '',
    district: json['district'] as String?,
    province: json['province'] as String?,
    postalCode: json['postalCode'] as String?,
    country: json['country'] as String? ?? 'Sri Lanka',
    telephone: json['telephone'] as String?,
    email: json['email'] as String?,
    status: json['status'] as String? ?? 'ACTIVE',
  );

  Map<String, dynamic> toRequestJson({String? statusOverride}) => {
    'name': name,
    'description': description,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'district': district,
    'province': province,
    'postalCode': postalCode,
    'country': country,
    'telephone': telephone,
    'email': email,
    'status': statusOverride ?? status,
  };
}
