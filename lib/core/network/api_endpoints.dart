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
  static String clinicDoctors(Object id) => '${clinic(id)}/doctors';
  static String clinicServices(Object id) => '${clinic(id)}/services';
  static String doctor(Object id) => '$doctors/$id';
  static String doctorSchedules(Object id) => '${doctor(id)}/schedules';
  static String availableSlots(Object doctorId) =>
      '${doctor(doctorId)}/available-slots';
  static String appointment(Object id) => '$appointments/$id';
  static String appointmentStatusHistory(Object id) =>
      '${appointment(id)}/status-history';
  static String appointmentCheckIn(Object id) => '${appointment(id)}/check-in';
  static String notificationRead(Object id) => '$notifications/$id/read';
  static String user(Object id) => '$users/$id';
}
