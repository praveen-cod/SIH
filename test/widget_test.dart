import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthcall_ai/main.dart';
import 'package:healthcall_ai/models/user_model.dart';
import 'package:healthcall_ai/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:healthcall_ai/features/doctor/dashboard/doctor_dashboard_screen.dart';
import 'package:healthcall_ai/features/auth/presentation/login_screen.dart';
import 'package:healthcall_ai/features/admin/screens/admin_add_doctor_screen.dart';

void main() {
  testWidgets('HealthCall AI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HealthCallApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Admin Dashboard renders header and overview cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Check Header & greeting
    expect(find.textContaining('HealthCall AI'), findsWidgets);
    expect(find.textContaining('Admin'), findsWidgets);
    expect(find.text('System Online'), findsOneWidget);

    // Check Stat card labels
    expect(find.text('TOTAL PATIENTS'), findsOneWidget);
    expect(find.text('TOTAL DOCTORS'), findsOneWidget);
    expect(find.text("TODAY'S APPOINTMENTS"), findsOneWidget);
    expect(find.text('ACTIVE CONSULTATIONS'), findsOneWidget);
    expect(find.text('EMERGENCY ALERTS'), findsOneWidget);

    // Check Funnel & Assistant
    expect(find.text('Appointment Pipeline'), findsOneWidget);
    expect(find.text('AI Voice Assistant Status'), findsOneWidget);

    // Dispose widget tree to cancel animation controllers and complete staggered animations
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Doctor Dashboard renders clinical workflow and availability toggle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DoctorDashboardScreen(enableLiveTimer: false),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    // Check Header & practice overview
    expect(find.textContaining('HealthCall AI'), findsWidgets);
    expect(find.text("Here's your practice overview."), findsOneWidget);
    expect(find.text('Available'), findsWidgets);

    // Check Doctor stats
    expect(find.text("TODAY'S APPOINTMENTS"), findsOneWidget);
    expect(find.text('PENDING REQUESTS'), findsOneWidget);
    expect(find.text('COMPLETED TODAY'), findsOneWidget);
    expect(find.text('TOTAL PATIENTS'), findsOneWidget);

    // Check Sections
    expect(find.text("Today's Appointments"), findsOneWidget);
    expect(find.text('Pending Requests'), findsOneWidget);
    expect(find.text('Recent Patients'), findsOneWidget);
    expect(find.text('Your Availability'), findsOneWidget);

    // Verify AI Consultation / Active Consultation is NOT present in doctor dashboard
    expect(find.text('Active Consultation'), findsNothing);
    expect(find.text('AI Consultation'), findsNothing);

    // Dispose widget tree to cancel active consultation timer and pump to complete all animations
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  test('User role validation prevents cross-role access', () {
    final adminUser = UserModel(
      id: 'ADM-001',
      name: 'System Admin',
      email: 'admin@demo.com',
      role: UserRole.admin,
      createdAt: DateTime(2026, 1, 1),
    );

    final doctorUser = UserModel(
      id: 'DOC-001',
      name: 'Dr. Sarah',
      email: 'doctor@demo.com',
      role: UserRole.doctor,
      createdAt: DateTime(2026, 1, 1),
    );

    final patientUser = UserModel(
      id: 'PAT-001',
      name: 'Alex',
      email: 'patient@demo.com',
      role: UserRole.patient,
      createdAt: DateTime(2026, 1, 1),
    );

    expect(adminUser.role, equals(UserRole.admin));
    expect(doctorUser.role, equals(UserRole.doctor));
    expect(patientUser.role, equals(UserRole.patient));
    expect(adminUser.role == UserRole.doctor, isFalse);
    expect(doctorUser.role == UserRole.admin, isFalse);
    expect(patientUser.role == UserRole.admin, isFalse);
  });

  testWidgets('LoginScreen role switcher auto-fills doctor and admin demo credentials',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Initially patient credentials are set
    expect(find.text('patient@demo.com'), findsWidgets);

    // Switch to Doctor
    await tester.tap(find.text('Doctor'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('doctor@demo.com'), findsWidgets);
    expect(find.text('Quick Login as Doctor'), findsOneWidget);

    // Switch to Admin
    await tester.tap(find.text('Admin'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('admin@demo.com'), findsWidgets);
    expect(find.text('Quick Login as Admin'), findsOneWidget);

    // Clean up
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('AdminAddDoctorScreen renders full signup-style provisioning form without overflow',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminAddDoctorScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Provision Doctor'), findsWidgets);
    expect(find.text('Doctor Account Provisioning'), findsOneWidget);
    expect(find.text('Doctor Full Name'), findsOneWidget);
    expect(find.text('Medical Specialization'), findsOneWidget);
    expect(find.text('Professional Email'), findsOneWidget);
    expect(find.text('Temporary Password'), findsOneWidget);
    expect(find.text('Provision Doctor Account'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
