enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  noShow,
  unknown;

  factory AppointmentStatus.fromApi(String? value) => switch (value) {
    'PENDING' => pending,
    'CONFIRMED' => confirmed,
    'COMPLETED' => completed,
    'CANCELLED' => cancelled,
    'NO_SHOW' => noShow,
    _ => unknown,
  };

  String get apiValue => switch (this) {
    pending => 'PENDING',
    confirmed => 'CONFIRMED',
    completed => 'COMPLETED',
    cancelled => 'CANCELLED',
    noShow => 'NO_SHOW',
    unknown => 'UNKNOWN',
  };

  String get label => switch (this) {
    pending => 'Awaiting clinic',
    confirmed => 'Confirmed',
    completed => 'Completed',
    cancelled => 'Cancelled',
    noShow => 'Missed',
    unknown => 'Status unavailable',
  };
}

class AppointmentStatusHistoryEntry {
  const AppointmentStatusHistoryEntry({
    required this.id,
    required this.appointmentId,
    required this.status,
    required this.changedByUserId,
    required this.createdAt,
    this.reason,
  });

  final String id;
  final String appointmentId;
  final AppointmentStatus status;
  final String changedByUserId;
  final String? reason;
  final DateTime? createdAt;

  factory AppointmentStatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      AppointmentStatusHistoryEntry(
        id: json['id'].toString(),
        appointmentId: json['appointmentId'].toString(),
        status: AppointmentStatus.fromApi(json['status'] as String?),
        changedByUserId: json['changedByUserId'].toString(),
        reason: json['reason'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

class AppointmentDoctor {
  const AppointmentDoctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.licenseNumber,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? licenseNumber;

  String get displayName => 'Dr. $firstName $lastName';
  String get initials =>
      '${firstName.isEmpty ? '' : firstName[0]}${lastName.isEmpty ? '' : lastName[0]}';

  factory AppointmentDoctor.fromJson(Map<String, dynamic> json) =>
      AppointmentDoctor(
        id: json['id'].toString(),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        licenseNumber: json['licenseNumber'] as String?,
      );
}

class AppointmentClinic {
  const AppointmentClinic({required this.id, required this.name});
  final String id;
  final String name;

  factory AppointmentClinic.fromJson(Map<String, dynamic> json) =>
      AppointmentClinic(
        id: json['id'].toString(),
        name: json['name'] as String? ?? 'Clinic',
      );
}

class AppointmentService {
  const AppointmentService({
    required this.id,
    required this.name,
    required this.durationMinutes,
  });
  final String id;
  final String name;
  final int durationMinutes;

  factory AppointmentService.fromJson(Map<String, dynamic> json) =>
      AppointmentService(
        id: json['id'].toString(),
        name: json['name'] as String? ?? 'Healthcare service',
        durationMinutes: json['durationMinutes'] as int? ?? 0,
      );
}

class AppointmentTimeSlot {
  const AppointmentTimeSlot({required this.startTime, required this.endTime});

  final String startTime;
  final String endTime;

  factory AppointmentTimeSlot.fromJson(Map<String, dynamic> json) =>
      AppointmentTimeSlot(
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
      );
}

class CareAppointment {
  const CareAppointment({
    required this.id,
    required this.patientId,
    required this.doctor,
    required this.clinic,
    required this.service,
    required this.doctorScheduleId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bookingReference,
    this.reason,
    this.notes,
    this.qrCode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final AppointmentDoctor doctor;
  final AppointmentClinic clinic;
  final AppointmentService service;
  final String doctorScheduleId;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final AppointmentStatus status;
  final String? bookingReference;
  final String? reason;
  final String? notes;
  final String? qrCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DateTime? get date => DateTime.tryParse(appointmentDate);
  DateTime? get scheduledStartUtc {
    final dateMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})',
    ).firstMatch(appointmentDate);
    final timeMatch = RegExp(
      r'^(\d{2}):(\d{2})(?::(\d{2}))?',
    ).firstMatch(startTime);
    if (dateMatch == null || timeMatch == null) return null;
    return DateTime.utc(
      int.parse(dateMatch.group(1)!),
      int.parse(dateMatch.group(2)!),
      int.parse(dateMatch.group(3)!),
      int.parse(timeMatch.group(1)!),
      int.parse(timeMatch.group(2)!),
      int.tryParse(timeMatch.group(3) ?? '') ?? 0,
    );
  }

  bool hasStartedAt(DateTime now) {
    final start = scheduledStartUtc;
    return start != null && start.isBefore(now.toUtc());
  }

  bool get hasStarted => hasStartedAt(DateTime.now());
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isPast =>
      status == AppointmentStatus.completed ||
      status == AppointmentStatus.cancelled ||
      status == AppointmentStatus.noShow;
  bool get canChange =>
      !hasStarted &&
      (status == AppointmentStatus.pending ||
          status == AppointmentStatus.confirmed);
  String get reference => bookingReference?.trim().isNotEmpty == true
      ? bookingReference!.trim()
      : 'CC-${id.padLeft(6, '0')}';

  CareAppointment copyWith({
    String? doctorScheduleId,
    String? appointmentDate,
    String? startTime,
    String? endTime,
    AppointmentStatus? status,
    String? bookingReference,
    String? reason,
    String? notes,
    String? qrCode,
  }) => CareAppointment(
    id: id,
    patientId: patientId,
    doctor: doctor,
    clinic: clinic,
    service: service,
    doctorScheduleId: doctorScheduleId ?? this.doctorScheduleId,
    appointmentDate: appointmentDate ?? this.appointmentDate,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    status: status ?? this.status,
    bookingReference: bookingReference ?? this.bookingReference,
    reason: reason ?? this.reason,
    notes: notes ?? this.notes,
    qrCode: qrCode ?? this.qrCode,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  factory CareAppointment.fromJson(
    Map<String, dynamic> json,
  ) => CareAppointment(
    id: json['id'].toString(),
    patientId: json['patientId'].toString(),
    doctor: AppointmentDoctor.fromJson(json['doctor'] as Map<String, dynamic>),
    clinic: AppointmentClinic.fromJson(json['clinic'] as Map<String, dynamic>),
    service: AppointmentService.fromJson(
      json['service'] as Map<String, dynamic>,
    ),
    doctorScheduleId: json['doctorScheduleId'].toString(),
    appointmentDate: json['appointmentDate'] as String,
    startTime: json['startTime'] as String,
    endTime: json['endTime'] as String,
    status: AppointmentStatus.fromApi(json['status'] as String?),
    bookingReference: json['bookingReference'] as String?,
    reason: json['reason'] as String?,
    notes: json['notes'] as String?,
    qrCode: json['qrCode'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}
