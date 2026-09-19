class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
    this.dateOfBirth,
    this.phone,
    this.profilePhoto,
    this.status,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final DateTime? dateOfBirth;
  final String? phone;
  final String? profilePhoto;
  final String? status;

  String get displayName => '$firstName $lastName'.trim();

  CurrentUser copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? phone,
    String? profilePhoto,
  }) => CurrentUser(
    id: id,
    email: email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    roles: roles,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    phone: phone ?? this.phone,
    profilePhoto: profilePhoto ?? this.profilePhoto,
    status: status,
  );

  Map<String, dynamic> toUpdateJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth == null
        ? null
        : '${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}',
    'phone': phone,
    'profilePhoto': profilePhoto,
  };

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
    id: json['id'] as String,
    email: json['email'] as String,
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    roles: (json['roles'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
    dateOfBirth: DateTime.tryParse(json['dateOfBirth'] as String? ?? ''),
    phone: json['phone'] as String?,
    profilePhoto: json['profilePhoto'] as String?,
    status: json['status'] as String?,
  );
}
