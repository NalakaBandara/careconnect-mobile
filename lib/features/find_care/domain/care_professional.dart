class CareSpecialty {
  const CareSpecialty({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String? description;

  factory CareSpecialty.fromJson(Map<String, dynamic> json) => CareSpecialty(
    id: json['id'].toString(),
    name: json['name'] as String? ?? 'Specialty',
    description: json['description'] as String?,
  );
}

class CareClinicSummary {
  const CareClinicSummary({required this.id, required this.name, this.city});

  final String id;
  final String name;
  final String? city;

  factory CareClinicSummary.fromJson(Map<String, dynamic> json) =>
      CareClinicSummary(
        id: json['id'].toString(),
        name: json['name'] as String? ?? 'Clinic',
        city: json['city'] as String?,
      );
}

class CareService {
  const CareService({
    required this.id,
    required this.name,
    this.description,
    this.durationMinutes,
  });

  final String id;
  final String name;
  final String? description;
  final int? durationMinutes;

  factory CareService.fromJson(Map<String, dynamic> json) => CareService(
    id: json['id'].toString(),
    name: json['name'] as String? ?? 'Healthcare service',
    description: json['description'] as String?,
    durationMinutes: json['durationMinutes'] as int?,
  );
}

class CareAvailabilityPreview {
  const CareAvailabilityPreview({
    required this.day,
    required this.date,
    required this.isoDate,
    required this.times,
    this.doctorScheduleId,
    this.endTimes = const {},
  });

  final String day;
  final String date;
  final String isoDate;
  final List<String> times;
  final String? doctorScheduleId;
  final Map<String, String> endTimes;

  String? endTimeFor(String startTime) => endTimes[startTime];
}

class CareProfessional {
  const CareProfessional({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.specialties,
    required this.clinics,
    required this.isVerified,
    this.profilePhoto,
    this.bio,
    this.yearsOfExperience,
    this.rating,
    this.nextAvailableLabel,
    this.services = const [],
    this.availability = const [],
  });

  final String id;
  final String firstName;
  final String lastName;
  final List<CareSpecialty> specialties;
  final List<CareClinicSummary> clinics;
  final bool isVerified;
  final String? profilePhoto;
  final String? bio;
  final int? yearsOfExperience;

  /// Preview-only enrichment until these fields are added to the API contract.
  final double? rating;
  final String? nextAvailableLabel;
  final List<CareService> services;
  final List<CareAvailabilityPreview> availability;

  String get displayName => 'Dr. $firstName $lastName';
  String get initials =>
      '${firstName.isEmpty ? '' : firstName[0]}${lastName.isEmpty ? '' : lastName[0]}';
  String get primarySpecialty =>
      specialties.isEmpty ? 'Healthcare professional' : specialties.first.name;
  String get primaryClinic =>
      clinics.isEmpty ? 'Clinic to be confirmed' : clinics.first.name;
  String? get city => clinics.isEmpty ? null : clinics.first.city;

  factory CareProfessional.fromJson(Map<String, dynamic> json) =>
      CareProfessional(
        id: json['id'].toString(),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        specialties: (json['specialties'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CareSpecialty.fromJson)
            .toList(growable: false),
        clinics: (json['clinics'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CareClinicSummary.fromJson)
            .toList(growable: false),
        isVerified: json['isVerified'] as bool? ?? false,
        profilePhoto: json['profilePhoto'] as String?,
        bio: json['bio'] as String?,
        yearsOfExperience: json['yearsOfExperience'] as int?,
      );

  CareProfessional copyWith({
    List<CareClinicSummary>? clinics,
    List<CareService>? services,
    List<CareAvailabilityPreview>? availability,
    String? nextAvailableLabel,
  }) => CareProfessional(
    id: id,
    firstName: firstName,
    lastName: lastName,
    specialties: specialties,
    clinics: clinics ?? this.clinics,
    isVerified: isVerified,
    profilePhoto: profilePhoto,
    bio: bio,
    yearsOfExperience: yearsOfExperience,
    rating: rating,
    nextAvailableLabel: nextAvailableLabel ?? this.nextAvailableLabel,
    services: services ?? this.services,
    availability: availability ?? this.availability,
  );
}
