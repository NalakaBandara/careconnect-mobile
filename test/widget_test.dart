import 'package:careconnect_mobile/app/app.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/booking/domain/appointment_booking.dart';
import 'package:careconnect_mobile/features/booking/presentation/booking_flow_screen.dart';
import 'package:careconnect_mobile/features/find_care/data/find_care_preview_data.dart';
import 'package:careconnect_mobile/features/find_care/presentation/find_care_screen.dart';
import 'package:careconnect_mobile/features/navigation/presentation/main_shell.dart';
import 'package:careconnect_mobile/features/onboarding/presentation/onboarding_screen.dart';
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
    expect(find.text('Every visit, beautifully organized.'), findsOneWidget);
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
}
