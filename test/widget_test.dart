import 'package:careconnect_mobile/app/app.dart';
import 'package:careconnect_mobile/core/logging/app_logger.dart';
import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/network/api_logger.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_shell.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_preview_data.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_controller.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/domain/check_in_record.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointments_screen.dart';
import 'package:careconnect_mobile/features/booking/domain/appointment_booking.dart';
import 'package:careconnect_mobile/features/booking/data/booking_repository.dart';
import 'package:careconnect_mobile/features/booking/presentation/booking_flow_screen.dart';
import 'package:careconnect_mobile/features/auth/data/auth_service.dart';
import 'package:careconnect_mobile/features/auth/domain/auth_session.dart';
import 'package:careconnect_mobile/features/auth/presentation/auth_form_screen.dart';
import 'package:careconnect_mobile/features/auth/presentation/welcome_screen.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_preview_data.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_repository.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:careconnect_mobile/features/find_care/presentation/find_care_screen.dart';
import 'package:careconnect_mobile/features/home/presentation/home_screen.dart';
import 'package:careconnect_mobile/features/navigation/presentation/main_shell.dart';
import 'package:careconnect_mobile/features/notifications/data/notifications_repository.dart';
import 'package:careconnect_mobile/features/notifications/domain/care_notification.dart';
import 'package:careconnect_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:careconnect_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/features/profile/data/user_repository.dart';
import 'package:careconnect_mobile/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildOfflineAuthenticatedHome(
    BuildContext context,
    CurrentUser user,
  ) => MainShell(user: user, useLiveGuestDirectory: false);

  testWidgets('shows splash then opens onboarding', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const CareConnectApp());

    expect(find.byKey(const Key('splash-title')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.text('CARE, YOUR WAY'), findsOneWidget);
  });

  test('API logs redact credentials and personal fields', () {
    final sanitized = ApiLogger.sanitize({
      'doctorProfileId': '3',
      'email': 'amara@example.com',
      'access_token': 'secret-token',
      'patient': {'firstName': 'Amara', 'phone': '0771234567'},
      'items': [
        {'id': '8', 'notes': 'Private health note'},
      ],
    });

    expect(sanitized, {
      'doctorProfileId': '3',
      'email': '<redacted>',
      'access_token': '<redacted>',
      'patient': {'firstName': '<redacted>', 'phone': '<redacted>'},
      'items': [
        {'id': '8', 'notes': '<redacted>'},
      ],
    });
  });

  test('application logs redact sensitive debug context', () {
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);

    AppLogger.info(
      'AUTH',
      'Test event',
      details: {'email': 'amara@example.com', 'userId': '8', 'count': 2},
    );

    final output = messages.join('\n');
    expect(output, contains('[CareConnect][INFO][AUTH] Test event'));
    expect(output, contains('"email":"<redacted>"'));
    expect(output, contains('"userId":"<redacted>"'));
    expect(output, contains('"count":2'));
    expect(output, isNot(contains('amara@example.com')));
  });

  testWidgets('moves through onboarding and opens auth entry', (tester) async {
    usePhoneSize(tester);
    final auth = _FakeAuthDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          authBuilder: (_) => WelcomeScreen(authService: auth),
        ),
      ),
    );

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

  testWidgets('signs in with the CareConnect API account flow', (tester) async {
    usePhoneSize(tester);
    final auth = _FakeAuthDataSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: WelcomeScreen(
          authService: auth,
          homeBuilder: buildOfflineAuthenticatedHome,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-screen')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-email-field')),
      'AMARA@EXAMPLE.COM',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      'private-password',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(auth.loginCalls, 1);
    expect(auth.lastEmail, 'AMARA@EXAMPLE.COM');
    expect(find.byKey(const Key('home-greeting')), findsOneWidget);
    expect(find.textContaining('Amara'), findsWidgets);
  });

  testWidgets('registers a patient with the backend contract fields', (
    tester,
  ) async {
    usePhoneSize(tester);
    final auth = _FakeAuthDataSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: WelcomeScreen(
          authService: auth,
          homeBuilder: buildOfflineAuthenticatedHome,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-account-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register-screen')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('register-first-name')),
      'Amara',
    );
    await tester.enterText(
      find.byKey(const Key('register-last-name')),
      'Silva',
    );
    await tester.enterText(
      find.byKey(const Key('auth-email-field')),
      'amara@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-phone-field')),
      '0771234567',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password')),
      'password123',
    );
    final termsCheckbox = find.byType(Checkbox);
    if (termsCheckbox.evaluate().isNotEmpty) {
      await tester.ensureVisible(termsCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(termsCheckbox);
    }
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(auth.registerCalls, 1);
    expect(auth.lastFirstName, 'Amara');
    expect(auth.lastPhone, '0771234567');
    expect(find.byKey(const Key('home-greeting')), findsOneWidget);
  });

  testWidgets('shows backend validation beside the matching auth field', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthFormScreen(
          authService: _FieldErrorAuthDataSource(),
          signUp: true,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('register-first-name')),
      'Amara',
    );
    await tester.enterText(
      find.byKey(const Key('register-last-name')),
      'Silva',
    );
    await tester.enterText(
      find.byKey(const Key('auth-email-field')),
      'amara@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password')),
      'password123',
    );
    final termsCheckbox = find.byType(Checkbox);
    if (termsCheckbox.evaluate().isNotEmpty) {
      await tester.ensureVisible(termsCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(termsCheckbox);
    }
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Email already registered'), findsOneWidget);
    expect(find.text('A user with this email already exists'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('auth-email-field')),
      'new@example.com',
    );
    await tester.pump();
    expect(find.text('Email already registered'), findsNothing);
  });

  test('parses the self-hosted JWT authentication response', () {
    final session = AuthSession.fromJson({
      'data': {
        'id': '8',
        'email': 'amara@example.com',
        'firstName': 'Amara',
        'lastName': 'Silva',
        'status': 'ACTIVE',
        'roles': ['PATIENT'],
      },
      'accessToken': 'signed-jwt',
    });

    expect(session.accessToken, 'signed-jwt');
    expect(session.user.id, '8');
    expect(session.user.roles, ['PATIENT']);
  });

  test('stores the JWT after sending the backend login contract', () async {
    final tokenStore = _FakeTokenStore();
    final apiClient = _FakeAuthApiClient();
    final service = AuthService(
      tokenStore: tokenStore,
      publicClient: apiClient,
    );

    final session = await service.login(
      email: ' AMARA@EXAMPLE.COM ',
      password: 'private-password',
    );

    expect(apiClient.lastPath, '/api/v1/auth/login');
    expect(apiClient.lastBody, {
      'email': 'amara@example.com',
      'password': 'private-password',
    });
    expect(tokenStore.token, 'signed-jwt');
    expect(session.user.firstName, 'Amara');
  });

  testWidgets('shows home dashboard and switches main navigation', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MainShell(useLiveGuestDirectory: false),
      ),
    );

    expect(find.byKey(const Key('home-greeting')), findsOneWidget);
    expect(find.byKey(const Key('home-search')), findsOneWidget);
    expect(find.text('Next appointment'), findsOneWidget);
    expect(find.byType(FindCareScreen, skipOffstage: false), findsNothing);
    expect(find.byType(AppointmentsScreen, skipOffstage: false), findsNothing);
    expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);

    await tester.tap(find.byKey(const Key('nav-find-care')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('find-care-title')), findsOneWidget);
    expect(find.byType(FindCareScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(AppointmentsScreen, skipOffstage: false), findsNothing);

    await tester.tap(find.byKey(const Key('nav-appointments')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appointments-title')), findsOneWidget);
    expect(find.byType(FindCareScreen, skipOffstage: false), findsOneWidget);
    expect(
      find.byType(AppointmentsScreen, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('loads the public care directory for a guest', (tester) async {
    usePhoneSize(tester);
    final repository = _FakeFindCareRepository();
    var signInRequested = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(
          initialIndex: 1,
          guestFindCareRepository: repository,
          onSignInRequired: () => signInRequested = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dr. Nadeesha Fernando'), findsOneWidget);
    expect(find.text('1 professional'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('professional-22')));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to book'), findsOneWidget);

    await tester.tap(find.byKey(const Key('book-professional-button')));
    expect(signInRequested, isTrue);
  });

  testWidgets('loads real appointment data on the home dashboard', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeAppointmentsDataSource();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(
          firstName: 'Amara',
          repository: repository,
          onFindCare: () {},
          onAppointments: () {},
          onProfile: () {},
          onNotifications: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.listCalls, 1);
    expect(find.byKey(const Key('home-greeting')), findsOneWidget);
    expect(find.textContaining('Amara'), findsWidgets);
    expect(find.text('1 upcoming visit'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('home-scroll-view')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(repository.appointment.doctor.displayName),
      findsOneWidget,
    );
  });

  testWidgets('shows the real home dashboard empty state', (tester) async {
    usePhoneSize(tester);
    final repository = _FakeAppointmentsDataSource()..appointments = [];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(
          repository: repository,
          onFindCare: () {},
          onAppointments: () {},
          onProfile: () {},
          onNotifications: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 upcoming visits'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('home-scroll-view')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-dashboard-empty')), findsOneWidget);
  });

  testWidgets('opens notifications from home and reads an update', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MainShell(useLiveGuestDirectory: false),
      ),
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

  testWidgets('loads and reads real backend notifications', (tester) async {
    usePhoneSize(tester);
    final repository = _FakeNotificationsDataSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NotificationsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.getCalls, 1);
    expect(find.text('2 updates waiting for you.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notification-91')));
    await tester.pumpAndSettle();
    expect(repository.setReadCalls, 1);
    expect(find.byKey(const Key('notification-detail-screen')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1 update waiting for you.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mark-all-notifications-read')));
    await tester.pumpAndSettle();
    expect(repository.setReadCalls, 2);
    expect(find.text('You are all caught up.'), findsOneWidget);
  });

  test('notification repository follows the backend API contract', () async {
    final client = _FakeNotificationsApiClient();
    final repository = NotificationsRepository(client);

    final notifications = await repository.getNotifications(isRead: false);
    expect(client.lastGetPath, '/api/v1/notifications');
    expect(client.lastQuery, {'isRead': false});
    expect(notifications.single.id, '91');

    final updated = await repository.setRead('91', isRead: true);
    expect(client.lastPatchPath, '/api/v1/notifications/91/read');
    expect(client.lastPatchBody, {'isRead': true});
    expect(updated.isRead, isTrue);
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

  testWidgets('loads the authenticated care directory and available slots', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeFindCareRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: FindCareScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dr. Nadeesha Fernando'), findsOneWidget);
    expect(find.text('1 professional'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cardiology'));
    await tester.pumpAndSettle();
    expect(repository.lastSpecialtyId, '12');

    await tester.tap(find.byKey(const ValueKey('professional-22')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('professional-profile-name')), findsOneWidget);

    final service = find.text('Heart health review');
    await tester.scrollUntilVisible(service, 220);
    expect(service, findsOneWidget);
    final slot = find.byKey(const ValueKey('availability-time-09:30'));
    await tester.scrollUntilVisible(slot, 220);
    expect(slot, findsOneWidget);
  });

  test('matches available slots to one unambiguous doctor schedule', () async {
    final client = _FakeAvailabilityApiClient();
    final repository = FindCareRepository(client);

    final availability = await repository.getUpcomingAvailability(
      doctorId: '22',
      clinicId: '7',
      days: 2,
    );

    expect(client.requestedPaths.first, '/api/v1/doctors/22/schedules');
    expect(
      client.requestedPaths
          .where((path) => path == '/api/v1/doctors/22/available-slots')
          .length,
      2,
    );
    expect(availability, hasLength(2));
    expect(availability.every((day) => day.doctorScheduleId != null), isTrue);
    expect(availability.first.endTimeFor('09:30'), '09:50');
  });

  test('parses the backend doctor directory contract', () {
    final professional = CareProfessional.fromJson({
      'id': '22',
      'firstName': 'Nadeesha',
      'lastName': 'Fernando',
      'profilePhoto': null,
      'bio': 'Cardiac care',
      'yearsOfExperience': 8,
      'isVerified': true,
      'specialties': [
        {'id': '12', 'name': 'Cardiology', 'description': null},
      ],
      'clinics': [
        {'id': '7', 'name': 'Harbour Medical Centre'},
      ],
    });

    expect(professional.id, '22');
    expect(professional.displayName, 'Dr. Nadeesha Fernando');
    expect(professional.primarySpecialty, 'Cardiology');
    expect(professional.isVerified, isTrue);
  });

  test('unwraps the latest backend doctor detail response', () async {
    final repository = FindCareRepository(_FakeDoctorDetailApiClient());

    final professional = await repository.getDoctor('22');

    expect(professional.id, '22');
    expect(professional.displayName, 'Dr. Nadeesha Fernando');
    expect(professional.primarySpecialty, 'Cardiology');
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

  testWidgets('creates a real appointment with an exact backend slot', (
    tester,
  ) async {
    usePhoneSize(tester);
    final bookingRepository = _FakeBookingDataSource();
    CareAppointment? createdAppointment;
    var openedAppointments = false;
    final professional = FindCarePreviewData.professionals.first.copyWith(
      availability: const [
        CareAvailabilityPreview(
          day: 'Today',
          date: 'Sep 21',
          isoDate: '2026-09-21',
          times: ['09:30'],
          doctorScheduleId: '15',
          endTimes: {'09:30': '09:50'},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BookingFlowScreen(
          professional: professional,
          repository: bookingRepository,
          onAppointmentCreated: (appointment) =>
              createdAppointment = appointment,
          onViewAppointments: () => openedAppointments = true,
          currentUser: const CurrentUser(
            id: '8',
            email: 'amara@example.com',
            firstName: 'Amara',
            lastName: 'Silva',
            roles: ['PATIENT'],
            phone: '0771234567',
          ),
          initialTime: '09:30',
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('booking-continue-button')));
    await tester.pumpAndSettle();
    expect(find.text('Amara Silva'), findsOneWidget);
    expect(find.text('0771234567'), findsOneWidget);

    await tester.tap(find.byKey(const Key('booking-continue-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-booking-button')));
    await tester.pumpAndSettle();

    expect(bookingRepository.createCalls, 1);
    expect(bookingRepository.lastBooking?.doctorScheduleId, '15');
    expect(bookingRepository.lastBooking?.endTime, '09:50');
    expect(createdAppointment?.reference, 'CC-7351-REAL');
    expect(find.text('CC-7351-REAL'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('booking-done-button')),
      220,
    );
    expect(find.text('View appointments'), findsOneWidget);

    await tester.tap(find.byKey(const Key('booking-done-button')));
    await tester.pumpAndSettle();
    expect(openedAppointments, isTrue);
  });

  test('booking repository posts the backend appointment contract', () async {
    final client = _FakeBookingApiClient();
    final repository = AppointmentBookingRepository(client);
    final professional = FindCarePreviewData.professionals.first;
    final draft = AppointmentBookingDraft(
      professional: professional,
      clinic: professional.clinics.first,
      service: professional.services.first,
      appointmentDate: '2026-09-21',
      dateLabel: 'Today, Sep 21',
      startTime: '09:30',
      endTime: '09:50',
      doctorScheduleId: '15',
      fullName: 'Amara Silva',
      phoneNumber: '0771234567',
    );

    final appointment = await repository.createAppointment(draft);

    expect(client.lastPath, '/api/v1/appointments');
    expect(client.lastBody, draft.toApiJson());
    expect(appointment.reference, 'CC-7351-REAL');
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

  test(
    'shared appointments controller deduplicates loads and syncs updates',
    () async {
      final repository = _FakeAppointmentsDataSource();
      final controller = AppointmentsController(repository);
      addTearDown(controller.dispose);

      await controller.load();
      await controller.load();
      expect(repository.listCalls, 1);
      expect(controller.appointments, hasLength(1));

      controller.upsert(
        repository.appointment.copyWith(
          status: AppointmentStatus.cancelled,
          reason: 'Changed in appointment detail',
        ),
      );
      expect(
        controller.appointments.single.status,
        AppointmentStatus.cancelled,
      );

      final created = AppointmentsPreviewData.appointments[1].copyWith(
        bookingReference: 'CC-NEW-SYNC',
      );
      controller.upsert(created);
      expect(controller.appointments, hasLength(2));
      expect(
        controller.appointments.any(
          (appointment) => appointment.reference == 'CC-NEW-SYNC',
        ),
        isTrue,
      );
    },
  );

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

  testWidgets('loads, checks in and cancels a backend appointment', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeAppointmentsDataSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppointmentsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.listCalls, 1);
    await tester.tap(find.byKey(const ValueKey('appointment-card-4821')));
    await tester.pumpAndSettle();
    expect(repository.detailCalls, 1);

    final checkInButton = find.byKey(const Key('open-check-in-button'));
    await tester.scrollUntilVisible(checkInButton, 220);
    await tester.tap(checkInButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checked-in-record')), findsOneWidget);
    expect(find.text('Your queue number is 7.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final cancelButton = find.byKey(const Key('cancel-appointment-button'));
    await tester.scrollUntilVisible(cancelButton, 240);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('cancellation-reason-field')),
      'Schedule changed',
    );
    await tester.tap(find.byKey(const Key('confirm-cancellation-button')));
    await tester.pumpAndSettle();

    expect(repository.cancelReason, 'Schedule changed');
    expect(find.text('Cancelled'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appointments-past-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('appointment-card-4821')), findsOneWidget);
  });

  testWidgets('loads real slots and reschedules a backend appointment', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeAppointmentsDataSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppointmentsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('appointment-card-4821')));
    await tester.pumpAndSettle();
    final reschedule = find.byKey(const Key('reschedule-appointment-button'));
    await tester.drag(
      find.byKey(const Key('appointment-detail-screen')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    await tester.tap(reschedule);
    await tester.pumpAndSettle();

    expect(repository.slotCalls, 1);
    await tester.tap(find.byKey(const ValueKey('reschedule-time-11:00')));
    await tester.tap(find.byKey(const Key('confirm-reschedule-button')));
    await tester.pumpAndSettle();

    expect(repository.rescheduleCalls, 1);
    expect(repository.rescheduledStartTime, '11:00');
    expect(repository.appointment.reference, 'CC-4821-MEH');
    expect(find.text('11:00 – 11:20'), findsOneWidget);
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
      'bookingReference': 'CC-4821-MEH',
      'reason': 'Review',
      'notes': null,
      'createdAt': '2026-09-17T09:00:00.000Z',
      'updatedAt': '2026-09-17T09:00:00.000Z',
    });

    expect(appointment.status, AppointmentStatus.pending);
    expect(appointment.doctor.displayName, 'Dr. Maya Fernando');
    expect(appointment.service.durationMinutes, 20);
    expect(appointment.reference, 'CC-4821-MEH');
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

  testWidgets('refreshes and saves an authenticated user profile', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeUserDataSource();
    CurrentUser? propagated;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProfileScreen(
          user: repository.user,
          repository: repository,
          onUserChanged: (user) => propagated = user,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.getCalls, 1);
    expect(find.text('Amara Silva'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-profile-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-first-name-field')),
      'Ayesha',
    );
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.user.firstName, 'Ayesha');
    expect(propagated?.firstName, 'Ayesha');
    expect(find.text('Ayesha Silva'), findsOneWidget);
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

  test('recognizes the backend ADMIN role without changing patient roles', () {
    const admin = CurrentUser(
      id: '1',
      email: 'admin@careconnect.test',
      firstName: 'Care',
      lastName: 'Admin',
      roles: ['ADMIN', 'PATIENT'],
    );
    const patient = CurrentUser(
      id: '2',
      email: 'patient@careconnect.test',
      firstName: 'Care',
      lastName: 'Patient',
      roles: ['PATIENT'],
    );

    expect(admin.isAdmin, isTrue);
    expect(patient.isAdmin, isFalse);
  });

  testWidgets('shows live admin sections from the admin repository', (
    tester,
  ) async {
    usePhoneSize(tester);
    const admin = CurrentUser(
      id: '1',
      email: 'admin@careconnect.test',
      firstName: 'Nalaka',
      lastName: 'Admin',
      roles: ['ADMIN'],
      status: 'ACTIVE',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminShell(
          user: admin,
          accessTokenProvider: () async => 'admin-token',
          repository: _FakeAdminDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-dashboard')), findsOneWidget);
    expect(find.text('Good day, Nalaka'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Pending visits'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-nav-users')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-users')), findsOneWidget);
    expect(find.text('Amara Silva'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-nav-visits')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-appointments')), findsOneWidget);
    expect(find.text('Dr. Maya Fernando'), findsOneWidget);
  });
}

class _FakeAdminDataSource implements AdminDataSource {
  @override
  Future<AdminDashboardSnapshot> getDashboard() async =>
      const AdminDashboardSnapshot(
        users: [
          AdminUser(
            id: '8',
            email: 'amara@example.com',
            firstName: 'Amara',
            lastName: 'Silva',
            roles: ['PATIENT'],
            status: 'ACTIVE',
          ),
        ],
        totalUsers: 12,
        doctorCount: 4,
        clinicCount: 3,
        appointments: AppointmentsPreviewData.appointments,
      );
}

class _FakeFindCareRepository implements FindCareDataSource {
  String? lastSpecialtyId;

  static const professional = CareProfessional(
    id: '22',
    firstName: 'Nadeesha',
    lastName: 'Fernando',
    specialties: [CareSpecialty(id: '12', name: 'Cardiology')],
    clinics: [
      CareClinicSummary(
        id: '7',
        name: 'Harbour Medical Centre',
        city: 'Colombo',
      ),
    ],
    isVerified: true,
    yearsOfExperience: 8,
  );

  @override
  Future<List<CareSpecialty>> getSpecialties() async => const [
    CareSpecialty(id: '12', name: 'Cardiology'),
  ];

  @override
  Future<List<CareProfessional>> getDoctors({
    String? specialtyId,
    String? clinicId,
  }) async {
    lastSpecialtyId = specialtyId;
    return const [professional];
  }

  @override
  Future<CareProfessional> getProfessionalProfile(
    CareProfessional summary,
  ) async => professional.copyWith(
    services: const [
      CareService(id: '31', name: 'Heart health review', durationMinutes: 30),
    ],
  );

  @override
  Future<List<CareAvailabilityPreview>> getUpcomingAvailability({
    required String doctorId,
    required String clinicId,
    int days = 7,
  }) async => const [
    CareAvailabilityPreview(
      day: 'Tomorrow',
      date: 'Sep 20',
      isoDate: '2026-09-20',
      times: ['09:30'],
    ),
  ];
}

class _FakeAvailabilityApiClient extends ApiClient {
  _FakeAvailabilityApiClient() : super(accessTokenProvider: _noToken);

  final List<String> requestedPaths = [];

  static Future<String?> _noToken() async => null;

  @override
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    requestedPaths.add(path);
    if (path.endsWith('/schedules')) {
      const weekdays = [
        'MONDAY',
        'TUESDAY',
        'WEDNESDAY',
        'THURSDAY',
        'FRIDAY',
        'SATURDAY',
        'SUNDAY',
      ];
      return {
        'data': [
          for (var index = 0; index < weekdays.length; index++)
            {
              'id': '${index + 10}',
              'clinicId': '7',
              'dayOfWeek': weekdays[index],
              'startTime': '09:00',
              'endTime': '17:00',
              'slotDurationMinutes': 20,
              'isActive': true,
            },
        ],
      };
    }
    return {
      'slots': [
        {'startTime': '09:30', 'endTime': '09:50', 'available': true},
      ],
    };
  }
}

class _FakeDoctorDetailApiClient extends ApiClient {
  _FakeDoctorDetailApiClient() : super(accessTokenProvider: _noToken);

  static Future<String?> _noToken() async => null;

  @override
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async => {
    'data': {
      'id': '22',
      'firstName': 'Nadeesha',
      'lastName': 'Fernando',
      'profilePhoto': null,
      'bio': 'Cardiac care',
      'yearsOfExperience': 8,
      'isVerified': true,
      'specialties': [
        {'id': '12', 'name': 'Cardiology', 'description': null},
      ],
      'clinics': [
        {'id': '7', 'name': 'Harbour Medical Centre'},
      ],
    },
  };
}

class _FakeAppointmentsDataSource implements AppointmentsDataSource {
  CareAppointment appointment = AppointmentsPreviewData.appointments.first
      .copyWith(bookingReference: 'CC-4821-MEH');
  int listCalls = 0;
  int detailCalls = 0;
  int slotCalls = 0;
  int rescheduleCalls = 0;
  List<CareAppointment>? appointments;
  String? cancelReason;
  String? rescheduledStartTime;

  @override
  Future<List<CareAppointment>> getMyAppointments({
    AppointmentStatus? status,
    String? fromDate,
    String? toDate,
  }) async {
    listCalls++;
    return appointments ?? [appointment];
  }

  @override
  Future<CareAppointment> getAppointment(String id) async {
    detailCalls++;
    return appointment;
  }

  @override
  Future<CareAppointment> cancelAppointment(String id, {String? reason}) async {
    cancelReason = reason;
    appointment = appointment.copyWith(
      status: AppointmentStatus.cancelled,
      reason: reason,
    );
    return appointment;
  }

  @override
  Future<List<AppointmentTimeSlot>> getAvailableSlots({
    required CareAppointment appointment,
    required String date,
  }) async {
    slotCalls++;
    return const [
      AppointmentTimeSlot(startTime: '11:00', endTime: '11:20'),
      AppointmentTimeSlot(startTime: '11:30', endTime: '11:50'),
    ];
  }

  @override
  Future<CheckInRecord> getCheckIn(String appointmentId) async => CheckInRecord(
    id: '11',
    appointmentId: appointmentId,
    checkedInAt: DateTime(2026, 9, 18, 9, 20),
    checkedInByUserId: '8',
    method: 'RECEPTION_QR',
    queueNumber: 7,
  );

  @override
  Future<CareAppointment> rescheduleAppointment(
    String id, {
    required String appointmentDate,
    required String startTime,
    required String endTime,
  }) async {
    rescheduleCalls++;
    rescheduledStartTime = startTime;
    appointment = appointment.copyWith(
      appointmentDate: appointmentDate,
      startTime: startTime,
      endTime: endTime,
    );
    return appointment;
  }
}

class _FakeBookingDataSource implements AppointmentBookingDataSource {
  int createCalls = 0;
  AppointmentBookingDraft? lastBooking;

  @override
  Future<CareAppointment> createAppointment(
    AppointmentBookingDraft booking,
  ) async {
    createCalls++;
    lastBooking = booking;
    return AppointmentsPreviewData.appointments.first.copyWith(
      bookingReference: 'CC-7351-REAL',
      doctorScheduleId: booking.doctorScheduleId,
      appointmentDate: booking.appointmentDate,
      startTime: booking.startTime,
      endTime: booking.endTime,
      status: AppointmentStatus.pending,
    );
  }
}

class _FakeBookingApiClient extends ApiClient {
  _FakeBookingApiClient() : super(accessTokenProvider: _noToken);

  String? lastPath;
  Object? lastBody;

  static Future<String?> _noToken() async => null;

  @override
  Future<Object?> post(String path, {Object? body}) async {
    lastPath = path;
    lastBody = body;
    return {
      'id': '73',
      'patientId': '8',
      'doctor': {
        'id': '1',
        'firstName': 'Arun',
        'lastName': 'Mehta',
        'licenseNumber': 'SLMC 12458',
      },
      'clinic': {'id': '1', 'name': 'Northgate Medical Centre'},
      'service': {
        'id': '1',
        'name': 'General consultation',
        'durationMinutes': 20,
      },
      'doctorScheduleId': '15',
      'appointmentDate': '2026-09-21',
      'startTime': '09:30',
      'endTime': '09:50',
      'status': 'PENDING',
      'bookingReference': 'CC-7351-REAL',
      'reason': null,
      'notes': null,
      'createdAt': '2026-09-21T08:00:00.000Z',
      'updatedAt': '2026-09-21T08:00:00.000Z',
    };
  }
}

class _FakeNotificationsDataSource implements NotificationsDataSource {
  int getCalls = 0;
  int setReadCalls = 0;
  List<CareNotification> notifications = [
    CareNotification(
      id: '91',
      type: CareNotificationType.reminder,
      title: 'Appointment tomorrow',
      message: 'Your appointment begins at 09:30.',
      isRead: false,
      createdAt: DateTime(2026, 9, 20, 8, 30),
    ),
    CareNotification(
      id: '92',
      type: CareNotificationType.appointment,
      title: 'Appointment confirmed',
      message: 'Your appointment is confirmed.',
      isRead: false,
      createdAt: DateTime(2026, 9, 19, 9),
    ),
  ];

  @override
  Future<List<CareNotification>> getNotifications({bool? isRead}) async {
    getCalls++;
    if (isRead == null) return List.of(notifications);
    return notifications
        .where((notification) => notification.isRead == isRead)
        .toList(growable: false);
  }

  @override
  Future<CareNotification> setRead(String id, {required bool isRead}) async {
    setReadCalls++;
    final index = notifications.indexWhere((item) => item.id == id);
    final updated = notifications[index].copyWith(
      isRead: isRead,
      readAt: isRead ? DateTime(2026, 9, 21, 8) : null,
    );
    notifications[index] = updated;
    return updated;
  }
}

class _FakeNotificationsApiClient extends ApiClient {
  _FakeNotificationsApiClient() : super(accessTokenProvider: _noToken);

  String? lastGetPath;
  Map<String, dynamic>? lastQuery;
  String? lastPatchPath;
  Object? lastPatchBody;

  static Future<String?> _noToken() async => null;

  @override
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetPath = path;
    lastQuery = queryParameters;
    return {
      'data': [
        {
          'id': '91',
          'type': 'APPOINTMENT_REMINDER',
          'title': 'Appointment tomorrow',
          'message': 'Your appointment begins at 09:30.',
          'isRead': false,
          'createdAt': '2026-09-20T08:30:00.000Z',
          'readAt': null,
        },
      ],
    };
  }

  @override
  Future<Object?> patch(String path, {Object? body}) async {
    lastPatchPath = path;
    lastPatchBody = body;
    return {
      'id': '91',
      'type': 'APPOINTMENT_REMINDER',
      'title': 'Appointment tomorrow',
      'message': 'Your appointment begins at 09:30.',
      'isRead': true,
      'createdAt': '2026-09-20T08:30:00.000Z',
      'readAt': '2026-09-21T08:00:00.000Z',
    };
  }
}

class _FakeUserDataSource implements UserDataSource {
  CurrentUser user = CurrentUser(
    id: '8',
    email: 'amara@example.com',
    firstName: 'Amara',
    lastName: 'Silva',
    roles: const ['PATIENT'],
    dateOfBirth: DateTime(1991, 3, 14),
    phone: '0771234567',
    status: 'ACTIVE',
  );
  int getCalls = 0;
  int updateCalls = 0;

  @override
  Future<CurrentUser> getCurrentUser() async {
    getCalls++;
    return user;
  }

  @override
  Future<CurrentUser> updateCurrentUser(CurrentUser updated) async {
    updateCalls++;
    user = updated;
    return user;
  }
}

class _FakeAuthDataSource implements AuthDataSource {
  int loginCalls = 0;
  int registerCalls = 0;
  int logoutCalls = 0;
  String? lastEmail;
  String? lastFirstName;
  String? lastPhone;

  static const user = CurrentUser(
    id: '8',
    email: 'amara@example.com',
    firstName: 'Amara',
    lastName: 'Silva',
    roles: ['PATIENT'],
    status: 'ACTIVE',
  );

  static const session = AuthSession(user: user, accessToken: 'test-token');

  @override
  Future<String?> accessToken() async => session.accessToken;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    return session;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    registerCalls++;
    lastFirstName = firstName;
    lastEmail = email;
    lastPhone = phone;
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async => null;
}

class _FieldErrorAuthDataSource extends _FakeAuthDataSource {
  @override
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) {
    throw const ApiException(
      statusCode: 409,
      message: 'A user with this email already exists',
      responseBody: {
        'error': {
          'code': 'CONFLICT',
          'message': 'A user with this email already exists',
          'fields': {
            'email': ['Email already registered'],
          },
        },
      },
    );
  }
}

class _FakeTokenStore implements TokenStore {
  String? token;

  @override
  Future<void> delete() async {
    token = null;
  }

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async {
    this.token = token;
  }
}

class _FakeAuthApiClient extends ApiClient {
  _FakeAuthApiClient() : super(accessTokenProvider: _noToken);

  String? lastPath;
  Object? lastBody;

  static Future<String?> _noToken() async => null;

  @override
  Future<Object?> post(String path, {Object? body}) async {
    lastPath = path;
    lastBody = body;
    return {
      'data': {
        'id': '8',
        'email': 'amara@example.com',
        'firstName': 'Amara',
        'lastName': 'Silva',
        'status': 'ACTIVE',
        'roles': ['PATIENT'],
      },
      'accessToken': 'signed-jwt',
    };
  }
}
