import 'package:careconnect_mobile/app/app.dart';
import 'package:careconnect_mobile/core/logging/app_logger.dart';
import 'package:careconnect_mobile/core/network/api_client.dart';
import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/network/api_logger.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/core/theme/theme_controller.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_appointment_screen.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_shell.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_qr_check_in_screen.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_security_screens.dart';
import 'package:careconnect_mobile/features/admin/presentation/admin_user_form_screen.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_preview_data.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_controller.dart';
import 'package:careconnect_mobile/features/appointments/data/appointments_repository.dart';
import 'package:careconnect_mobile/features/appointments/domain/care_appointment.dart';
import 'package:careconnect_mobile/features/appointments/domain/check_in_record.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointment_detail_screen.dart';
import 'package:careconnect_mobile/features/appointments/presentation/appointments_screen.dart';
import 'package:careconnect_mobile/features/appointments/presentation/cancel_appointment_screen.dart';
import 'package:careconnect_mobile/features/appointments/presentation/check_in_screen.dart';
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
import 'package:careconnect_mobile/features/onboarding/data/onboarding_preference_store.dart';
import 'package:careconnect_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:careconnect_mobile/features/onboarding/presentation/splash_screen.dart';
import 'package:careconnect_mobile/features/profile/domain/current_user.dart';
import 'package:careconnect_mobile/features/profile/data/user_repository.dart';
import 'package:careconnect_mobile/features/profile/presentation/profile_screen.dart';
import 'package:careconnect_mobile/features/profile/presentation/profile_settings_screens.dart';
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
    await tester.pumpWidget(
      CareConnectApp(
        onboardingPreferenceStore: _FakeOnboardingPreferenceStore(),
      ),
    );

    expect(find.byKey(const Key('splash-title')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.text('CARE, YOUR WAY'), findsOneWidget);
  });

  testWidgets('skips onboarding after it has been completed', (tester) async {
    usePhoneSize(tester);
    final store = _FakeOnboardingPreferenceStore(completed: true);
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          preferenceStore: store,
          completedBuilder: (_) =>
              const Scaffold(body: Text('Welcome destination')),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.text('Welcome destination'), findsOneWidget);
    expect(find.text('CARE, YOUR WAY'), findsNothing);
  });

  testWidgets('restores and changes the saved app theme', (tester) async {
    final store = _FakeThemePreferenceStore('dark');
    final controller = ThemeController(store: store);
    await controller.load();

    await tester.pumpWidget(CareConnectApp(themeController: controller));
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await controller.setThemeMode(ThemeMode.light);
    await tester.pump();

    expect(store.value, 'light');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('appearance screen offers system light and dark modes', (
    tester,
  ) async {
    final store = _FakeThemePreferenceStore();
    final controller = ThemeController(store: store);

    await tester.pumpWidget(
      ThemeControllerScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: AppearanceScreen(controller: controller),
        ),
      ),
    );

    expect(find.byKey(const Key('theme-system')), findsOneWidget);
    expect(find.byKey(const Key('theme-light')), findsOneWidget);
    expect(find.byKey(const Key('theme-dark')), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme-dark')));
    await tester.pump();

    expect(controller.themeMode, ThemeMode.dark);
    expect(store.value, 'dark');
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
    final onboardingStore = _FakeOnboardingPreferenceStore();
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          preferenceStore: onboardingStore,
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
    expect(onboardingStore.completed, isTrue);
  });

  testWidgets('guest profile offers direct sign in and registration', (
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

    await tester.tap(find.byKey(const Key('browse-as-guest-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guest-profile-screen')), findsOneWidget);
    expect(find.text('You’re browsing as a guest'), findsOneWidget);
    expect(find.byKey(const Key('guest-profile-sign-in')), findsOneWidget);
    expect(
      find.byKey(const Key('guest-profile-create-account')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('guest-profile-create-account')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register-screen')), findsOneWidget);
  });

  testWidgets('guest shell never exposes preview patient records', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeFindCareRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(
          guestFindCareRepository: repository,
          onSignInRequired: () {},
          onCreateAccountRequired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-guest-appointments')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cardiology'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cardiology'), findsOneWidget);
    expect(find.byKey(const Key('next-appointment-card')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-appointments')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guest-appointments-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('guest-appointments-create-account')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('appointment-card-4821')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-notifications-button')),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('home-notifications-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guest-notifications-screen')), findsOneWidget);
    expect(find.byKey(const Key('notifications-list')), findsNothing);
    expect(
      find.byKey(const Key('guest-notifications-create-account')),
      findsOneWidget,
    );
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

  test('signing out clears the locally stored access token', () async {
    final tokenStore = _FakeTokenStore()..token = 'expired-test-token';
    final service = AuthService(
      tokenStore: tokenStore,
      publicClient: _FakeAuthApiClient(),
    );

    await service.logout();

    expect(tokenStore.token, isNull);
  });

  testWidgets('welcome screen explains when a session has expired', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: WelcomeScreen(
          authService: _FakeAuthDataSource(),
          initialMessage: 'Your session expired. Please sign in again.',
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Your session expired. Please sign in again.'),
      findsOneWidget,
    );
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
        home: const MainShell(
          user: CurrentUser(
            id: 'preview-user',
            email: 'preview@example.com',
            firstName: 'Preview',
            lastName: 'User',
            roles: ['PATIENT'],
          ),
          useLiveGuestDirectory: false,
        ),
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

  test(
    'loads each availability date and matches each doctor schedule',
    () async {
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
      final slotQueries = <Map<String, dynamic>>[
        for (var index = 0; index < client.requestedPaths.length; index++)
          if (client.requestedPaths[index] ==
              '/api/v1/doctors/22/available-slots')
            client.requestedQueries[index],
      ];
      expect(slotQueries.every((query) => query['clinicId'] == '7'), isTrue);
      expect(slotQueries.every((query) => query['date'] != null), isTrue);
      expect(
        slotQueries.every(
          (query) =>
              !query.containsKey('fromDate') && !query.containsKey('toDate'),
        ),
        isTrue,
      );
      expect(slotQueries.map((query) => query['date']).toSet(), hasLength(2));
      expect(availability, hasLength(2));
      expect(availability.every((day) => day.doctorScheduleId != null), isTrue);
      expect(availability.first.endTimeFor('09:30'), '09:50');
    },
  );

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

  test('appointment repository parses the status history contract', () async {
    final client = _FakeAppointmentHistoryApiClient();
    final repository = AppointmentsRepository(client);

    final history = await repository.getAppointmentStatusHistory('4821');

    expect(client.lastPath, '/api/v1/appointments/4821/status-history');
    expect(history, hasLength(2));
    expect(history.first.status, AppointmentStatus.pending);
    expect(history.last.status, AppointmentStatus.confirmed);
    expect(history.last.reason, 'Confirmed by clinic');
    expect(history.last.changedByUserId, '4');
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

  testWidgets('loads real appointment status history for a patient', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeAppointmentsDataSource();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppointmentDetailScreen(
          initialAppointment: repository.appointment,
          repository: repository,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.historyCalls, 1);
    expect(
      find.byKey(const Key('patient-appointment-status-history')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('patient-status-history-list')),
      findsOneWidget,
    );
    expect(find.text('Appointment journey'), findsOneWidget);
    expect(find.text('Confirmed'), findsWidgets);
    expect(find.text('Confirmed by Northgate reception'), findsOneWidget);
    expect(find.textContaining('changed by user'), findsNothing);
  });

  testWidgets('shows the QR image returned by the appointment API', (
    tester,
  ) async {
    usePhoneSize(tester);
    final appointment = AppointmentsPreviewData.appointments.first.copyWith(
      qrCode:
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CheckInScreen(appointment: appointment),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appointment-qr-code')), findsOneWidget);
    expect(find.text('APPOINTMENT QR'), findsOneWidget);
    expect(
      find.text('Show this QR code at reception when you arrive.'),
      findsOneWidget,
    );
  });

  testWidgets('shows no fake QR and refreshes until the real QR is available', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _QrRefreshDataSource();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CheckInScreen(
          appointment: repository.appointment,
          repository: repository,
          checkInPollInterval: const Duration(hours: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appointment-qr-unavailable')), findsOneWidget);
    expect(find.text('QR PENDING'), findsOneWidget);
    expect(find.byKey(const Key('appointment-qr-code')), findsNothing);

    await tester.tap(find.byKey(const Key('refresh-appointment-qr')));
    await tester.pumpAndSettle();

    expect(repository.detailCalls, 2);
    expect(find.byKey(const Key('appointment-qr-code')), findsOneWidget);
    expect(find.byKey(const Key('appointment-qr-unavailable')), findsNothing);
  });

  testWidgets('patient check-in status updates after reception scans the QR', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _PollingCheckInDataSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CheckInScreen(
          appointment: repository.appointment,
          repository: repository,
          checkInPollInterval: const Duration(milliseconds: 20),
        ),
      ),
    );

    await tester.pump();
    expect(find.byKey(const Key('checked-in-record')), findsNothing);
    expect(repository.checkInCalls, 1);

    await tester.pump(const Duration(milliseconds: 25));
    await tester.pump();
    expect(find.byKey(const Key('checked-in-record')), findsOneWidget);
    expect(find.text('Your queue number is 9.'), findsOneWidget);
    expect(repository.checkInCalls, 2);

    await tester.pump(const Duration(milliseconds: 60));
    expect(repository.checkInCalls, 2);
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
      'qrCode': 'data:image/png;base64,aGVhbHRoY2FyZQ==',
      'createdAt': '2026-09-17T09:00:00.000Z',
      'updatedAt': '2026-09-17T09:00:00.000Z',
    });

    expect(appointment.status, AppointmentStatus.pending);
    expect(appointment.doctor.displayName, 'Dr. Maya Fernando');
    expect(appointment.service.durationMinutes, 20);
    expect(appointment.reference, 'CC-4821-MEH');
    expect(appointment.qrCode, startsWith('data:image/png;base64,'));
  });

  test('appointment change rules use the backend UTC start-time rule', () {
    final appointment = AppointmentsPreviewData.appointments.first;
    final future = appointment.copyWith(
      appointmentDate: '2099-01-02',
      startTime: '09:30:15',
    );
    final past = appointment.copyWith(
      appointmentDate: '2000-01-02',
      startTime: '09:30',
    );

    expect(future.scheduledStartUtc, DateTime.utc(2099, 1, 2, 9, 30, 15));
    expect(future.hasStartedAt(DateTime.utc(2099, 1, 2, 9, 30)), isFalse);
    expect(future.canChange, isTrue);
    expect(past.hasStartedAt(DateTime.utc(2000, 1, 2, 9, 31)), isTrue);
    expect(past.canChange, isFalse);
  });

  testWidgets('hides change actions after the appointment start time', (
    tester,
  ) async {
    usePhoneSize(tester);
    final pastAppointment = AppointmentsPreviewData.appointments.first.copyWith(
      appointmentDate: '2000-01-02',
      startTime: '09:30',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppointmentDetailScreen(
          initialAppointment: pastAppointment,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const Key('reschedule-appointment-button')),
      findsNothing,
    );
    expect(find.byKey(const Key('cancel-appointment-button')), findsNothing);
  });

  testWidgets('shows the exact backend cancellation conflict', (tester) async {
    usePhoneSize(tester);
    final repository = _CancellationConflictDataSource();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CancelAppointmentScreen(
          appointment: repository.appointment,
          repository: repository,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('confirm-cancellation-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cancellation-error')), findsOneWidget);
    expect(
      find.text(
        'Cannot cancel an appointment that has already started or passed',
      ),
      findsOneWidget,
    );
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

  testWidgets('permanently anonymises a patient after typed confirmation', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeUserDataSource();
    var loggedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProfileScreen(
          user: repository.user,
          repository: repository,
          onLogout: () async => loggedOut = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('privacy-tile')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('privacy-tile')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('delete-account-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('delete-account-button')));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue-account-deletion')));
    await tester.pumpAndSettle();
    expect(find.text('Final confirmation'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('confirm-account-deletion')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('account-deletion-confirmation')),
      'DELETE',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-account-deletion')));
    await tester.pumpAndSettle();

    expect(repository.anonymiseCalls, 1);
    expect(repository.lastAnonymisedUserId, '8');
    expect(loggedOut, isTrue);
  });

  test('account anonymisation follows the latest backend contract', () async {
    final apiClient = _FakeUserApiClient();
    final repository = UserRepository(apiClient);

    await repository.anonymiseUser('8');

    expect(apiClient.lastPatchPath, '/api/v1/users/8?anonymisation=true');
    expect(apiClient.lastPatchBody, isNull);
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
    final repository = _FakeAdminDataSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminShell(
          user: admin,
          accessTokenProvider: () async => 'admin-token',
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-dashboard')), findsOneWidget);
    expect(find.text('Good day, Nalaka'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Pending visits'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-nav-manage')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-management')), findsOneWidget);
    expect(find.text('Amara Silva'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-user-8')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-user-access')), findsOneWidget);
    expect(find.text('Account status: Active'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-assign-role-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign role').last);
    await tester.pumpAndSettle();
    expect(find.text('Assigned'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Doctors'));
    await tester.pumpAndSettle();
    expect(find.text('1 doctor profiles'), findsOneWidget);
    expect(find.text('Dr. Maya Fernando'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-doctor-setup-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-doctor-operations')), findsOneWidget);
    expect(find.text('Weekly schedules'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clinics'));
    await tester.pumpAndSettle();
    expect(find.text('Northgate Medical Centre'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-clinic-setup-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage clinic'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-clinic-hours')), findsOneWidget);
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-clinic-services')), findsOneWidget);
    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-clinic-staff')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-management-add')));
    await tester.pumpAndSettle();
    expect(find.text('Add a care location'), findsOneWidget);
    final saveClinic = find.byKey(const Key('admin-save-clinic'));
    await tester.ensureVisible(saveClinic);
    await tester.pumpAndSettle();
    await tester.tap(saveClinic);
    await tester.pump();
    expect(find.text('Clinic name is required'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-nav-visits')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-appointments')), findsOneWidget);
    expect(find.text('Dr. Maya Fernando'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-appointment-4821')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-appointment-detail')), findsOneWidget);
    final completeAppointment = find.byKey(const Key('admin-status-COMPLETED'));
    await tester.scrollUntilVisible(completeAppointment, 220);
    await tester.tap(completeAppointment);
    await tester.pumpAndSettle();
    expect(find.text('Confirm change'), findsOneWidget);
    await tester.tap(find.text('Confirm change'));
    await tester.pumpAndSettle();
    expect(repository.updatedAppointmentStatus, AppointmentStatus.completed);
    await tester.fling(
      find.byKey(const Key('admin-appointment-detail')),
      const Offset(0, 1200),
      1800,
    );
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-nav-account')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-qr-check-in-tile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-catalog-tile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-specialty-catalog')), findsOneWidget);
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-service-catalog')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final notificationTile = find.byKey(const Key('admin-notification-tile'));
    await tester.drag(
      find.byKey(const Key('admin-account')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(notificationTile);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('admin-notification-composer')),
      findsOneWidget,
    );
    final sendNotification = find.byKey(const Key('admin-send-notification'));
    await tester.ensureVisible(sendNotification);
    await tester.tap(sendNotification);
    await tester.pump();
    expect(find.text('Select a recipient'), findsOneWidget);
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Message is required'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final securityTile = find.byKey(const Key('admin-security-tile'));
    await tester.ensureVisible(securityTile);
    await tester.tap(securityTile);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-role-catalog')), findsOneWidget);
    await tester.tap(find.text('Audit activity'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-audit-logs')), findsOneWidget);
    expect(find.text('Appointment Updated'), findsOneWidget);
  });

  testWidgets('admin permanently anonymises another user', (tester) async {
    usePhoneSize(tester);
    final repository = _FakeAdminDataSource();
    var refreshCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminUserAccessScreen(
          user: const AdminUser(
            id: '8',
            email: 'amara@example.com',
            firstName: 'Amara',
            lastName: 'Silva',
            roles: ['PATIENT'],
            status: 'ACTIVE',
          ),
          currentAdminId: '1',
          repository: repository,
          onChanged: () async => refreshCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('admin-user-access')),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('admin-anonymise-user-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-anonymise-user-button')));
    await tester.pumpAndSettle();
    expect(find.text('Anonymise this user?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue-admin-anonymisation')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('confirm-admin-anonymisation')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('admin-anonymisation-confirmation')),
      'ANONYMISE',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-admin-anonymisation')));
    await tester.pumpAndSettle();

    expect(repository.anonymisedUserId, '8');
    expect(refreshCalls, 1);
  });

  test('admin anonymisation follows the latest backend contract', () async {
    final apiClient = _FakeUserApiClient();

    await AdminRepository(apiClient).anonymiseUser('8');

    expect(apiClient.lastPatchPath, '/api/v1/users/8?anonymisation=true');
    expect(apiClient.lastPatchBody, isNull);
  });

  test('admin repository loads one patient by id', () async {
    final apiClient = _FakeUserApiClient();

    final patient = await AdminRepository(apiClient).getUser('8');

    expect(apiClient.lastGetPath, '/api/v1/users/8');
    expect(patient.displayName, 'Amara Silva');
    expect(patient.email, 'amara@example.com');
    expect(patient.phone, '0771234567');
    expect(patient.status, 'ACTIVE');
  });

  test('admin user creation follows the latest backend contract', () async {
    final apiClient = _FakeUserApiClient();

    final patient = await AdminRepository(apiClient).createUser(
      email: ' PATIENT@EXAMPLE.COM ',
      password: 'temporary-password',
      firstName: ' Amara ',
      lastName: ' Silva ',
      dateOfBirth: '1991-03-14',
      phone: ' 0771234567 ',
      status: 'ACTIVE',
    );

    expect(apiClient.lastPostPath, '/api/v1/users');
    expect(apiClient.lastPostBody, {
      'email': 'patient@example.com',
      'password': 'temporary-password',
      'firstName': 'Amara',
      'lastName': 'Silva',
      'dateOfBirth': '1991-03-14',
      'phone': '0771234567',
      'status': 'ACTIVE',
    });
    expect(patient.displayName, 'Amara Silva');
    expect(patient.roles, ['PATIENT']);
  });

  testWidgets('admin creates a patient account from the user form', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeAdminDataSource();
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => FilledButton(
            key: const Key('open-admin-user-form'),
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AdminUserFormScreen(repository: repository),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-admin-user-form')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('admin-user-first-name')),
      'Amara',
    );
    await tester.enterText(
      find.byKey(const Key('admin-user-last-name')),
      'Silva',
    );
    await tester.enterText(
      find.byKey(const Key('admin-user-email')),
      'amara@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('admin-user-password')),
      'temporary-password',
    );
    final save = find.byKey(const Key('admin-save-user'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.createUserCalls, 1);
    expect(repository.createdUserEmail, 'amara@example.com');
    expect(repository.createdUserStatus, 'ACTIVE');
    expect(result, isTrue);
  });

  testWidgets('admin appointment displays live patient details', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeAdminDataSource();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminAppointmentScreen(
          appointment: AppointmentsPreviewData.appointments.first,
          repository: repository,
          onChanged: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.getUserCalls, 1);
    expect(
      find.byKey(const Key('admin-appointment-patient-card')),
      findsOneWidget,
    );
    expect(find.text('Amara Silva'), findsOneWidget);
    expect(find.text('amara@example.com'), findsOneWidget);
    expect(find.text('0771234567'), findsOneWidget);
    expect(find.text('Patient #8'), findsNothing);
  });

  testWidgets('admin verifies an appointment and records QR check-in', (
    tester,
  ) async {
    usePhoneSize(tester);
    final repository = _FakeAdminDataSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminQrCheckInScreen(
          repository: repository,
          scannerBuilder: (_) => const ColoredBox(color: Colors.black),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-enter-appointment-id')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-manual-appointment-id')),
      '4821',
    );
    await tester.tap(find.byKey(const Key('admin-find-appointment')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('admin-qr-appointment-review')),
      findsOneWidget,
    );
    expect(find.text('CC-004821'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-reception-check-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-confirm-reception-check-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-qr-check-in-success')), findsOneWidget);
    expect(repository.receptionCheckInAppointmentId, '4821');
    expect(find.text('7'), findsOneWidget);
  });
}

class _FakeThemePreferenceStore implements ThemePreferenceStore {
  _FakeThemePreferenceStore([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _FakeOnboardingPreferenceStore implements OnboardingPreferenceStore {
  _FakeOnboardingPreferenceStore({this.completed = false});

  bool completed;

  @override
  Future<bool> hasCompleted() async => completed;

  @override
  Future<void> markCompleted() async => completed = true;
}

class _FakeAdminDataSource implements AdminDataSource {
  int clinicUpdates = 0;
  AppointmentStatus? updatedAppointmentStatus;
  String? assignedRoleId;
  String? receptionCheckInAppointmentId;
  String? anonymisedUserId;
  int getUserCalls = 0;
  int createUserCalls = 0;
  String? createdUserEmail;
  String? createdUserStatus;

  @override
  Future<AdminUser> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? phone,
    required String status,
  }) async {
    createUserCalls++;
    createdUserEmail = email;
    createdUserStatus = status;
    return AdminUser(
      id: '10',
      email: email,
      firstName: firstName,
      lastName: lastName,
      roles: const ['PATIENT'],
      status: status,
      phone: phone,
    );
  }

  @override
  Future<void> anonymiseUser(String userId) async {
    anonymisedUserId = userId;
  }

  @override
  Future<AdminUser> getUser(String userId) async {
    getUserCalls++;
    return AdminUser(
      id: userId,
      email: 'amara@example.com',
      firstName: 'Amara',
      lastName: 'Silva',
      roles: const ['PATIENT'],
      status: 'ACTIVE',
      phone: '0771234567',
    );
  }

  @override
  Future<CareAppointment> getAppointment(String appointmentId) async =>
      AppointmentsPreviewData.appointments.firstWhere(
        (appointment) => appointment.id == appointmentId,
      );

  @override
  Future<CheckInRecord> createReceptionCheckIn(String appointmentId) async {
    receptionCheckInAppointmentId = appointmentId;
    return CheckInRecord(
      id: '55',
      appointmentId: appointmentId,
      checkedInAt: DateTime(2026, 9, 24, 9, 25),
      checkedInByUserId: '1',
      method: 'RECEPTION_QR',
      queueNumber: 7,
    );
  }

  @override
  Future<CareSpecialty> saveSpecialty({
    String? id,
    required String name,
    String? description,
  }) async =>
      CareSpecialty(id: id ?? '99', name: name, description: description);

  @override
  Future<CareService> saveService({
    String? id,
    required String name,
    String? description,
    int? durationMinutes,
    required String status,
  }) async => CareService(
    id: id ?? '99',
    name: name,
    description: description,
    durationMinutes: durationMinutes,
    status: status,
  );

  @override
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
  }) async {}

  @override
  Future<void> createClinic(AdminClinic clinic) async {}

  @override
  Future<void> createDoctor({
    required String userId,
    String? licenseNumber,
    String? bio,
    int? yearsOfExperience,
    required bool isVerified,
    required List<String> specialtyIds,
    required List<String> clinicIds,
  }) async {}

  @override
  Future<void> addDoctorClinic(String doctorId, String clinicId) async {}

  @override
  Future<void> addDoctorSpecialty(String doctorId, String specialtyId) async {}

  @override
  Future<void> addClinicService(String clinicId, String serviceId) async {}

  @override
  Future<void> addClinicUser(String clinicId, String userId) async {}

  @override
  Future<void> assignUserRole(String userId, String roleId) async {
    assignedRoleId = roleId;
  }

  @override
  Future<void> createDoctorSchedule(
    String doctorId,
    AdminDoctorSchedule schedule,
  ) async {}

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
        doctors: [
          AdminDoctor(
            id: '3',
            userId: '9',
            firstName: 'Maya',
            lastName: 'Fernando',
            isVerified: true,
            specialties: [CareSpecialty(id: '2', name: 'Cardiology')],
            clinics: [
              CareClinicSummary(id: '1', name: 'Northgate Medical Centre'),
            ],
          ),
        ],
        clinics: [
          AdminClinic(
            id: '1',
            name: 'Northgate Medical Centre',
            addressLine1: '12 Main Street',
            city: 'Colombo',
            country: 'Sri Lanka',
            status: 'ACTIVE',
          ),
        ],
        specialties: [CareSpecialty(id: '2', name: 'Cardiology')],
        services: [
          CareService(
            id: '1',
            name: 'General consultation',
            durationMinutes: 30,
          ),
        ],
        appointments: AppointmentsPreviewData.appointments,
      );

  @override
  Future<List<AdminClinicOperatingHour>> getClinicOperatingHours(
    String clinicId,
  ) async => const [
    AdminClinicOperatingHour(
      id: '1',
      dayOfWeek: 'MONDAY',
      openingTime: '09:00',
      closingTime: '17:00',
      isClosed: false,
    ),
  ];

  @override
  Future<List<CareService>> getClinicServices(String clinicId) async => const [
    CareService(id: '1', name: 'General consultation', durationMinutes: 30),
  ];

  @override
  Future<List<AdminUser>> getClinicUsers(String clinicId) async => const [
    AdminUser(
      id: '8',
      email: 'amara@example.com',
      firstName: 'Amara',
      lastName: 'Silva',
      roles: ['PATIENT'],
      status: 'ACTIVE',
    ),
  ];

  @override
  Future<List<AdminDoctorSchedule>> getDoctorSchedules(String doctorId) async =>
      const [
        AdminDoctorSchedule(
          id: '10',
          clinicId: '1',
          dayOfWeek: 'MONDAY',
          startTime: '09:00',
          endTime: '17:00',
          slotDurationMinutes: 30,
          isActive: true,
        ),
      ];

  @override
  Future<List<AdminAppointmentStatusEntry>> getAppointmentStatusHistory(
    String appointmentId,
  ) async => const [
    AdminAppointmentStatusEntry(
      id: '1',
      appointmentId: '4821',
      status: AppointmentStatus.confirmed,
      changedByUserId: '1',
      createdAt: null,
    ),
  ];

  @override
  Future<List<AdminAuditLog>> getAuditLogs({
    String? userId,
    String? entityType,
  }) async => const [
    AdminAuditLog(
      id: '1',
      userId: '1',
      action: 'APPOINTMENT_UPDATED',
      entityType: 'APPOINTMENT',
      entityId: '4821',
      createdAt: null,
    ),
  ];

  @override
  Future<List<AdminRole>> getRoles() async => const [
    AdminRole(id: '1', name: 'PATIENT', description: 'Patient access'),
    AdminRole(id: '2', name: 'ADMIN', description: 'Administrator access'),
  ];

  @override
  Future<void> removeDoctorClinic(String doctorId, String clinicId) async {}

  @override
  Future<void> removeDoctorSpecialty(
    String doctorId,
    String specialtyId,
  ) async {}

  @override
  Future<void> removeClinicService(String clinicId, String serviceId) async {}

  @override
  Future<void> removeClinicUser(String clinicId, String userId) async {}

  @override
  Future<void> updateClinic(AdminClinic clinic, {String? status}) async {
    clinicUpdates++;
  }

  @override
  Future<void> updateDoctor({
    required String id,
    String? bio,
    int? yearsOfExperience,
    required bool isVerified,
  }) async {}

  @override
  Future<void> updateDoctorSchedule(
    String doctorId,
    AdminDoctorSchedule schedule,
  ) async {}

  @override
  Future<void> updateClinicOperatingHours(
    String clinicId,
    List<AdminClinicOperatingHour> hours,
  ) async {}

  @override
  Future<CareAppointment> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    String? reason,
  }) async {
    updatedAppointmentStatus = status;
    return AppointmentsPreviewData.appointments
        .firstWhere((appointment) => appointment.id == appointmentId)
        .copyWith(status: status, reason: reason);
  }
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
  final List<Map<String, dynamic>> requestedQueries = [];

  static Future<String?> _noToken() async => null;

  @override
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    requestedPaths.add(path);
    requestedQueries.add(queryParameters ?? const {});
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
    final date = queryParameters!['date'] as String;
    return {
      'doctorId': '22',
      'clinicId': '7',
      'date': date,
      'slots': [
        {'startTime': '09:30', 'endTime': '09:50', 'available': true},
        {'startTime': '10:00', 'endTime': '10:20', 'available': false},
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
  int historyCalls = 0;
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
  Future<List<AppointmentStatusHistoryEntry>> getAppointmentStatusHistory(
    String id,
  ) async {
    historyCalls++;
    return [
      AppointmentStatusHistoryEntry(
        id: 'history-1',
        appointmentId: id,
        status: AppointmentStatus.pending,
        changedByUserId: '8',
        createdAt: DateTime.utc(2026, 9, 16, 8, 30),
      ),
      AppointmentStatusHistoryEntry(
        id: 'history-2',
        appointmentId: id,
        status: AppointmentStatus.confirmed,
        changedByUserId: '4',
        reason: 'Confirmed by Northgate reception',
        createdAt: DateTime.utc(2026, 9, 16, 9),
      ),
    ];
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

class _PollingCheckInDataSource extends _FakeAppointmentsDataSource {
  int checkInCalls = 0;

  @override
  Future<CheckInRecord> getCheckIn(String appointmentId) async {
    checkInCalls++;
    if (checkInCalls == 1) {
      throw const ApiException(message: 'Check-in not found', statusCode: 404);
    }
    return CheckInRecord(
      id: '12',
      appointmentId: appointmentId,
      checkedInAt: DateTime(2026, 9, 24, 10, 30),
      checkedInByUserId: '1',
      method: 'RECEPTION_QR',
      queueNumber: 9,
    );
  }
}

class _CancellationConflictDataSource extends _FakeAppointmentsDataSource {
  @override
  Future<CareAppointment> cancelAppointment(String id, {String? reason}) {
    throw const ApiException(
      message:
          'Cannot cancel an appointment that has already started or passed',
      statusCode: 409,
      responseBody: {
        'error': {
          'code': 'APPOINTMENT_ALREADY_PASSED',
          'message':
              'Cannot cancel an appointment that has already started or passed',
        },
      },
    );
  }
}

class _QrRefreshDataSource extends _FakeAppointmentsDataSource {
  static const _qrCode =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

  @override
  Future<CareAppointment> getAppointment(String id) async {
    detailCalls++;
    if (detailCalls >= 2) appointment = appointment.copyWith(qrCode: _qrCode);
    return appointment;
  }

  @override
  Future<CheckInRecord> getCheckIn(String appointmentId) async {
    throw const ApiException(message: 'Check-in not found', statusCode: 404);
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

class _FakeAppointmentHistoryApiClient extends ApiClient {
  _FakeAppointmentHistoryApiClient() : super(accessTokenProvider: _noToken);

  String? lastPath;

  static Future<String?> _noToken() async => null;

  @override
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    return {
      'data': [
        {
          'id': '1',
          'appointmentId': '4821',
          'status': 'PENDING',
          'changedByUserId': '8',
          'reason': null,
          'createdAt': '2026-09-16T08:30:00.000Z',
        },
        {
          'id': '2',
          'appointmentId': '4821',
          'status': 'CONFIRMED',
          'changedByUserId': '4',
          'reason': 'Confirmed by clinic',
          'createdAt': '2026-09-16T09:00:00.000Z',
        },
      ],
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
  int anonymiseCalls = 0;
  String? lastAnonymisedUserId;

  @override
  Future<void> anonymiseUser(String userId) async {
    anonymiseCalls++;
    lastAnonymisedUserId = userId;
  }

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

class _FakeUserApiClient extends ApiClient {
  _FakeUserApiClient() : super(accessTokenProvider: _noToken);

  String? lastPatchPath;
  Object? lastPatchBody;
  String? lastGetPath;
  String? lastPostPath;
  Object? lastPostBody;

  static Future<String?> _noToken() async => null;

  @override
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetPath = path;
    return {
      'data': {
        'id': '8',
        'email': 'amara@example.com',
        'firstName': 'Amara',
        'lastName': 'Silva',
        'phone': '0771234567',
        'status': 'ACTIVE',
        'roles': ['PATIENT'],
      },
    };
  }

  @override
  Future<Object?> patch(String path, {Object? body}) async {
    lastPatchPath = path;
    lastPatchBody = body;
    return {
      'data': {
        'id': '8',
        'status': 'ANONYMISED',
        'anonymisedAt': '2026-09-26T03:00:00.000Z',
      },
    };
  }

  @override
  Future<Object?> post(String path, {Object? body}) async {
    lastPostPath = path;
    lastPostBody = body;
    return {
      'data': {
        'id': '10',
        'email': 'patient@example.com',
        'firstName': 'Amara',
        'lastName': 'Silva',
        'phone': '0771234567',
        'status': 'ACTIVE',
        'roles': ['PATIENT'],
      },
    };
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
