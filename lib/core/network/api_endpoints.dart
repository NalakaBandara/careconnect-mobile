abstract final class ApiEndpoints {
  static const apiVersion = '/api/v1';

  static const currentUser = '$apiVersion/users/me';
  static const clinics = '$apiVersion/clinics';
  static const doctors = '$apiVersion/doctors';
  static const specialties = '$apiVersion/specialties';
  static const services = '$apiVersion/services';
  static const appointments = '$apiVersion/appointments';
  static const myAppointments = '$appointments/me';
  static const notifications = '$apiVersion/notifications';

  static String clinic(Object id) => '$clinics/$id';
  static String clinicDoctors(Object id) => '${clinic(id)}/doctors';
  static String clinicServices(Object id) => '${clinic(id)}/services';
  static String doctor(Object id) => '$doctors/$id';
  static String availableSlots(Object doctorId) =>
      '${doctor(doctorId)}/available-slots';
  static String appointment(Object id) => '$appointments/$id';
  static String notificationRead(Object id) => '$notifications/$id/read';
}
