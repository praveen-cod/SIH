import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/patient/dashboard/patient_dashboard_screen.dart';
import '../../features/doctor/dashboard/doctor_dashboard_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../shared/screens/coming_soon_screen.dart';
import '../../shared/screens/instant_ai_screen.dart';
import '../../features/consultation/presentation/consultation_screen.dart';
import '../../features/patient/appointments/doctor_booking_screen.dart';
import '../../features/patient/appointments/patient_appointments_screen.dart';
import '../../features/doctor/dashboard/doctor_appointments_screen.dart';
import '../../features/admin/screens/admin_add_doctor_screen.dart';
import '../../features/admin/screens/admin_doctors_screen.dart';
import '../../features/admin/screens/admin_patients_screen.dart';
import '../../features/admin/screens/admin_appointments_screen.dart';
import 'app_routes.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final location = state.uri.toString();

      // If not authenticated, only allow login, signup, instant-ai, consultation
      if (!isAuthenticated) {
        final allowedRoutes = [
          AppRoutes.login,
          AppRoutes.signup,
          AppRoutes.instantAI,
          AppRoutes.consultation,
        ];
        if (!allowedRoutes.any((r) => location.startsWith(r))) {
          return AppRoutes.login;
        }
        return null;
      }

      // If authenticated, redirect away from login/signup
      if (isAuthenticated &&
          (location == AppRoutes.login || location == AppRoutes.signup)) {
        return _dashboardForRole(user?.role);
      }

      // Role-based route protection
      if (user != null) {
        if (location.startsWith(AppRoutes.patientDashboard) &&
            user.role != UserRole.patient) {
          return _dashboardForRole(user.role);
        }
        if (location.startsWith(AppRoutes.doctorDashboard) &&
            user.role != UserRole.doctor) {
          return _dashboardForRole(user.role);
        }
        if (location.startsWith(AppRoutes.adminDashboard) &&
            user.role != UserRole.admin) {
          return _dashboardForRole(user.role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _buildPage(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => _buildPage(
          state,
          const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.instantAI,
        name: 'instant-ai',
        pageBuilder: (context, state) => _buildPage(
          state,
          const InstantAIScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.consultation,
        name: 'consultation',
        pageBuilder: (context, state) {
          final isGuest = state.uri.queryParameters['guest'] == 'true';
          return _buildPage(
            state,
            ConsultationScreen(isGuest: isGuest),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.patientDashboard,
        name: 'patient-dashboard',
        pageBuilder: (context, state) => _buildPage(
          state,
          const PatientDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.doctorDashboard,
        name: 'doctor-dashboard',
        pageBuilder: (context, state) => _buildPage(
          state,
          const DoctorDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        pageBuilder: (context, state) => _buildPage(
          state,
          const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminAddDoctor,
        name: 'admin-add-doctor',
        pageBuilder: (context, state) => _buildPage(
          state,
          const AdminAddDoctorScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.bookDoctor,
        name: 'book-doctor',
        pageBuilder: (context, state) {
          final consultationId = state.uri.queryParameters['consultationId'];
          final initialComplaint = state.uri.queryParameters['initialComplaint'];
          return _buildPage(
            state,
            DoctorBookingScreen(
              consultationId: consultationId,
              initialComplaint: initialComplaint,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.patientAppointments,
        name: 'patient-appointments',
        pageBuilder: (context, state) => _buildPage(
          state,
          const PatientAppointmentsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.doctorAppointments,
        name: 'doctor-appointments',
        pageBuilder: (context, state) => _buildPage(
          state,
          const DoctorAppointmentsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminDoctors,
        name: 'admin-doctors',
        pageBuilder: (context, state) => _buildPage(
          state,
          const AdminDoctorsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminPatients,
        name: 'admin-patients',
        pageBuilder: (context, state) => _buildPage(
          state,
          const AdminPatientsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminAppointments,
        name: 'admin-appointments',
        pageBuilder: (context, state) => _buildPage(
          state,
          const AdminAppointmentsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.comingSoon,
        name: 'coming-soon',
        pageBuilder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Feature';
          return _buildPage(state, ComingSoonScreen(featureTitle: title));
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF060B18),
      body: Center(
        child: Text(
          'Page not found: ${state.error}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
});

Page<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
  );
}

String _dashboardForRole(UserRole? role) {
  switch (role) {
    case UserRole.patient:
      return AppRoutes.patientDashboard;
    case UserRole.doctor:
      return AppRoutes.doctorDashboard;
    case UserRole.admin:
      return AppRoutes.adminDashboard;
    default:
      return AppRoutes.login;
  }
}
