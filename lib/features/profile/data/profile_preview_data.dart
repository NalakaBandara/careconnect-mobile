import 'package:careconnect_mobile/features/profile/domain/current_user.dart';

abstract final class ProfilePreviewData {
  static final user = CurrentUser(
    id: 'preview-user',
    email: 'amara.silva@example.com',
    firstName: 'Amara',
    lastName: 'Silva',
    roles: const ['PATIENT'],
    dateOfBirth: DateTime(1991, 3, 14),
    phone: '077 123 4567',
    status: 'ACTIVE',
  );
}
