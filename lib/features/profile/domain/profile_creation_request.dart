class ProfileCreationRequest {
  const ProfileCreationRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dateOfBirth,
    required this.phone,
  });

  final String firstName;
  final String lastName;
  final String email;
  final DateTime dateOfBirth;
  final String phone;

  Map<String, dynamic> toJson() => {
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'email': email.trim().toLowerCase(),
    'dateOfBirth':
        '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
    'phone': phone.trim(),
  };
}
