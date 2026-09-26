abstract final class ApiEndpoints {
  static const apiVersion = '/api/v1';

  static const auth = '$apiVersion/auth';
  static const login = '$auth/login';
  static const register = '$auth/register';
  static const currentUser = '$apiVersion/users/me';
  static const users = '$apiVersion/users';
  static const clinics = '$apiVersion/clinics';
  static const doctors = '$apiVersion/doctors';
  static const specialties = '$apiVersion/specialties';
  static const services = '$apiVersion/services';
  static const appointments = '$apiVersion/appointments';
  static const myAppointments = '$appointments/me';
  static const notifications = '$apiVersion/notifications';
  static const roles = '$apiVersion/roles';
  static const userRoles = '$apiVersion/user-roles';
  static const auditLogs = '$apiVersion/audit-logs';

  static String clinic(Object id) => '$clinics/$id';
  static String specialty(Object id) => '$specialties/$id';
  static String service(Object id) => '$services/$id';
  static String clinicDoctors(Object id) => '${clinic(id)}/doctors';
  static String clinicServices(Object id) => '${clinic(id)}/services';
  static String clinicService(Object clinicId, Object serviceId) =>
      '${clinicServices(clinicId)}/$serviceId';
  static String clinicOperatingHours(Object id) =>
      '${clinic(id)}/operating-hours';
  static String clinicUsers(Object id) => '${clinic(id)}/users';
  static String clinicUser(Object clinicId, Object userId) =>
      '${clinicUsers(clinicId)}/$userId';
  static String doctor(Object id) => '$doctors/$id';
  static String doctorSchedules(Object id) => '${doctor(id)}/schedules';
  static String doctorSchedule(Object doctorId, Object scheduleId) =>
      '${doctorSchedules(doctorId)}/$scheduleId';
  static String doctorSpecialties(Object id) => '${doctor(id)}/specialties';
  static String doctorSpecialty(Object doctorId, Object specialtyId) =>
      '${doctorSpecialties(doctorId)}/$specialtyId';
  static String doctorClinics(Object id) => '${doctor(id)}/clinics';
  static String doctorClinic(Object doctorId, Object clinicId) =>
      '${doctorClinics(doctorId)}/$clinicId';
  static String availableSlots(Object doctorId) =>
      '${doctor(doctorId)}/available-slots';
  static String appointment(Object id) => '$appointments/$id';
  static String appointmentStatus(Object id) => '${appointment(id)}/status';
  static String appointmentStatusHistory(Object id) =>
      '${appointment(id)}/status-history';
  static String appointmentCheckIn(Object id) => '${appointment(id)}/check-in';
  static String notificationRead(Object id) => '$notifications/$id/read';
  static String user(Object id) => '$users/$id';
  static String anonymiseUser(Object id) => '${user(id)}?anonymisation=true';
}
