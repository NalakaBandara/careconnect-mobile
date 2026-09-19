import 'package:careconnect_mobile/app/app.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/domain/check_in_record.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointments_screen.dart';
import 'package:careconnect_mobile/features/booking/domain/appointment_booking.dart';
import 'package:careconnect_mobile/features/booking/presentation/booking_flow_screen.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_preview_data.dart';
import 'package:careconnect_mobile/features/find_care/presentation/find_care_screen.dart';
import 'package:careconnect_mobile/features/navigation/presentation/main_shell.dart';
import 'package:careconnect_mobile/features/notifications/domain/care_notification.dart';
import 'package:careconnect_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:careconnect_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/features/profile/domain/profile_creation_request.dart';
import 'package:careconnect_mobile/features/profile/presentation/profile_screen.dart';
import 'package:careconnect_mobile/features/profile/presentation/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows splash then opens onboarding', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const CareConnectApp());

    expect(find.byKey(const Key('splash-title')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.text('CARE, YOUR WAY'), findsOneWidget);
  });

  testWidgets('moves through onboarding and opens auth entry', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(
      find.text('The right care,\nwithout the guesswork.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('YOUR TIME MATTERS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('READY WHEN YOU ARE'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Your care starts here.'), findsOneWidget);
  });

  testWidgets('does not attempt sign in without CareConnect Auth0 config', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const CareConnectApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skip-onboarding')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pumpAndSettle();

    expect(find.text('CareConnect setup required'), findsOneWidget);
  });

  testWidgets('shows home dashboard and switches main navigation', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MainShell()),
    );

    expect(find.byKey(const Key('home-greeting')), findsOneWidget);
    expect(find.byKey(const Key('home-search')), findsOneWidget);
    expect(find.text('Next appointment'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-find-care')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('find-care-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-appointments')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appointments-title')), findsOneWidget);
  });

  testWidgets('opens notifications from home and reads an update', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MainShell()),
    );

    await tester.tap(find.byKey(const Key('home-notifications-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-title')), findsOneWidget);
    expect(find.text('2 updates waiting for you.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notification-notification-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notification-detail-screen')), findsOneWidget);
    expect(find.text('Appointment confirmed'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1 update waiting for you.'), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-notification-1')), findsNothing);
  });

  testWidgets('shows the empty unread notification state', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const NotificationsScreen()),
    );

    await tester.tap(find.byKey(const Key('mark-all-notifications-read')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notifications-unread-filter')));
    await tester.pumpAndSettle();

    expect(find.text('Everything is read'), findsOneWidget);
    expect(find.text('You are all caught up.'), findsOneWidget);
  });

  test('parses the backend notification response contract', () {
    final notification = CareNotification.fromJson({
      'id': '91',
      'type': 'APPOINTMENT_REMINDER',
      'title': 'Appointment tomorrow',
      'message': 'Your appointment begins at 09:30.',
      'isRead': false,
      'createdAt': '2026-09-19T08:30:00.000Z',
      'readAt': null,
    });

    expect(notification.id, '91');
    expect(notification.type, CareNotificationType.reminder);
    expect(notification.isRead, isFalse);
    expect(notification.readAt, isNull);
  });

  testWidgets('filters care professionals and opens a profile', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const FindCareScreen()),
    );

    expect(find.text('4 professionals'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('find-care-search-field')),
      'cardiology',
    );
    await tester.pump();

    expect(find.text('1 professional'), findsOneWidget);
    expect(find.text('Dr. Senuri Perera'), findsOneWidget);
    expect(find.text('Dr. Arun Mehta'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('professional-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('professional-profile-name')), findsOneWidget);

    final time = find.byKey(const ValueKey('availability-time-09:00'));
    await tester.scrollUntilVisible(time, 300);
    await tester.tap(time);
    await tester.pump();
    expect(find.text('Continue with 09:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('book-professional-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('booking-slot-step')), findsOneWidget);
  });

  testWidgets('completes the preview appointment request journey', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BookingFlowScreen(
          professional: FindCarePreviewData.professionals.first,
          initialTime: '16:30',
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('booking-continue-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('booking-details-step')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('booking-name-field')),
      'Amara Silva',
    );
    await tester.enterText(
      find.byKey(const Key('booking-phone-field')),
      '0771234567',
    );
    await tester.tap(find.byKey(const Key('booking-continue-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('booking-review-step')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-booking-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('booking-confirmation')), findsOneWidget);
    expect(find.text('Your appointment request is in'), findsOneWidget);
  });

  test('appointment payload follows the backend create contract', () {
    final professional = FindCarePreviewData.professionals.first;
    final draft = AppointmentBookingDraft(
      professional: professional,
      clinic: professional.clinics.first,
      service: professional.services.first,
      appointmentDate: '2026-09-11',
      dateLabel: 'Today, Sep 11',
      startTime: '16:30',
      endTime: '16:50',
      doctorScheduleId: 'schedule-1',
      fullName: 'Amara Silva',
      phoneNumber: '0771234567',
      reason: 'General check-up',
    );

    expect(draft.toApiJson(), {
      'doctorProfileId': '1',
      'clinicId': '1',
      'serviceId': '1',
      'doctorScheduleId': 'schedule-1',
      'appointmentDate': '2026-09-11',
      'startTime': '16:30',
      'endTime': '16:50',
      'reason': 'General check-up',
    });
  });

  testWidgets('opens an appointment and moves a cancellation to past', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AppointmentsScreen()),
    );

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.byKey(const ValueKey('appointment-card-4821')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('appointment-card-4821')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appointment-detail-screen')), findsOneWidget);
    expect(find.text('CC-004821'), findsOneWidget);

    final checkInButton = find.byKey(const Key('open-check-in-button'));
    await tester.scrollUntilVisible(checkInButton, 220);
    await tester.tap(checkInButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('check-in-screen')), findsOneWidget);
    expect(find.byKey(const Key('check-in-reference')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final cancelButton = find.byKey(const Key('cancel-appointment-button'));
    await tester.scrollUntilVisible(cancelButton, 250);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('cancellation-reason-field')),
      'Unable to attend',
    );
    await tester.tap(find.byKey(const Key('confirm-cancellation-button')));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appointments-past-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('appointment-card-4821')), findsOneWidget);
  });

  test('parses the backend appointment response contract', () {
    final appointment = CareAppointment.fromJson({
      'id': '42',
      'patientId': '8',
      'doctor': {
        'id': '3',
        'firstName': 'Maya',
        'lastName': 'Fernando',
        'licenseNumber': 'SLMC 15102',
      },
      'clinic': {'id': '7', 'name': 'Harbour Wellness Clinic'},
      'service': {
        'id': '6',
        'name': 'Skin consultation',
        'durationMinutes': 20,
      },
      'doctorScheduleId': '15',
      'appointmentDate': '2026-09-21',
      'startTime': '14:30',
      'endTime': '14:50',
      'status': 'PENDING',
      'reason': 'Review',
      'notes': null,
      'createdAt': '2026-09-17T09:00:00.000Z',
      'updatedAt': '2026-09-17T09:00:00.000Z',
    });

    expect(appointment.status, AppointmentStatus.pending);
    expect(appointment.doctor.displayName, 'Dr. Maya Fernando');
    expect(appointment.service.durationMinutes, 20);
    expect(appointment.reference, 'CC-000042');
  });

  test('parses the backend check-in response contract', () {
    final checkIn = CheckInRecord.fromJson({
      'id': '5',
      'appointmentId': '42',
      'checkedInAt': '2026-09-21T08:58:00.000Z',
      'checkedInByUserId': '8',
      'method': 'RECEPTION_QR',
      'queueNumber': 3,
      'createdAt': '2026-09-21T08:58:00.000Z',
    });

    expect(checkIn.appointmentId, '42');
    expect(checkIn.method, 'RECEPTION_QR');
    expect(checkIn.queueNumber, 3);
  });

  testWidgets('edits preview profile details and opens support', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
    );

    expect(find.byKey(const Key('profile-title')), findsOneWidget);
    expect(find.text('Amara Silva'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-profile-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-profile-screen')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('profile-first-name-field')),
      'Ayesha',
    );
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();
    expect(find.text('Ayesha Silva'), findsOneWidget);

    final supportTile = find.byKey(const Key('support-tile'));
    await tester.drag(
      find.byKey(const Key('profile-screen')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.tap(supportTile);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('support-screen')), findsOneWidget);
  });

  test('profile update payload follows the backend contract', () {
    final user = CurrentUser(
      id: '8',
      email: 'amara@example.com',
      firstName: 'Amara',
      lastName: 'Silva',
      roles: const ['PATIENT'],
      dateOfBirth: DateTime(1991, 3, 14),
      phone: '0771234567',
      status: 'ACTIVE',
    );

    expect(user.toUpdateJson(), {
      'firstName': 'Amara',
      'lastName': 'Silva',
      'dateOfBirth': '1991-03-14',
      'phone': '0771234567',
      'profilePhoto': null,
    });
  });

  testWidgets('creates a CareConnect profile after authenticated sign-up', (
    tester,
  ) async {
    usePhoneSize(tester);
    ProfileCreationRequest? submitted;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProfileSetupScreen(
          email: 'amara@example.com',
          displayName: 'Amara Silva',
          onCreate: (request) async {
            submitted = request;
            return CurrentUser(
              id: '8',
              email: request.email,
              firstName: request.firstName,
              lastName: request.lastName,
              roles: const ['PATIENT'],
              dateOfBirth: request.dateOfBirth,
              phone: request.phone,
              status: 'ACTIVE',
            );
          },
          homeBuilder: (_, user) => Scaffold(
            body: Text(
              'Welcome ${user.firstName}',
              key: const Key('created-profile-home'),
            ),
          ),
          onExit: (_) async {},
        ),
      ),
    );

    expect(find.byKey(const Key('profile-setup-screen')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('profile-setup-phone')),
      '0771234567',
    );
    await tester.tap(find.byKey(const Key('profile-setup-date-of-birth')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final submit = find.byKey(const Key('create-profile-submit'));
    await tester.drag(
      find.byKey(const Key('profile-setup-screen')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('created-profile-home')), findsOneWidget);
    expect(submitted?.toJson(), {
      'firstName': 'Amara',
      'lastName': 'Silva',
      'email': 'amara@example.com',
      'dateOfBirth': '1990-01-01',
      'phone': '0771234567',
    });
  });

  test('profile creation payload follows the updated backend contract', () {
    final request = ProfileCreationRequest(
      firstName: ' Amara ',
      lastName: ' Silva ',
      email: 'AMARA@EXAMPLE.COM ',
      dateOfBirth: DateTime(1991, 3, 14),
      phone: ' 0771234567 ',
    );

    expect(request.toJson(), {
      'firstName': 'Amara',
      'lastName': 'Silva',
      'email': 'amara@example.com',
      'dateOfBirth': '1991-03-14',
      'phone': '0771234567',
    });
  });
}
