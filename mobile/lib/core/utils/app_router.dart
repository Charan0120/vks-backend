import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vks_app/data/providers/auth_provider.dart';
import 'package:vks_app/features/splash/splash_screen.dart';
import 'package:vks_app/features/onboarding/onboarding_screen.dart';
import 'package:vks_app/features/auth/screens/login_screen.dart';
import 'package:vks_app/features/auth/screens/register_screen.dart';
import 'package:vks_app/features/home/screens/home_screen.dart';
import 'package:vks_app/features/activities/screens/activities_screen.dart';
import 'package:vks_app/features/activities/screens/activity_detail_screen.dart';
import 'package:vks_app/features/admissions/screens/admission_screen.dart';
import 'package:vks_app/features/enquiry/screens/enquiry_screen.dart';
import 'package:vks_app/features/gallery/screens/gallery_screen.dart';
import 'package:vks_app/features/courses/screens/courses_screen.dart';
import 'package:vks_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:vks_app/features/admin/screens/admin_admissions_screen.dart';
import 'package:vks_app/features/admin/screens/admin_admission_detail_screen.dart';
import 'package:vks_app/features/admin/screens/admin_enquiries_screen.dart';
import 'package:vks_app/features/admin/screens/admin_users_screen.dart';
import 'package:vks_app/features/admin/screens/admin_courses_screen.dart';
import 'package:vks_app/features/admin/screens/admin_activities_screen.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isProtected = state.matchedLocation.startsWith('/admissions') ||
            state.matchedLocation.startsWith('/enquiry');
        final isAdminRoute = state.matchedLocation.startsWith('/admin');

        if (isProtected && !isLoggedIn) return '/login';
        if (isAdminRoute && (!isLoggedIn || !authProvider.isStaff)) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/activities', builder: (_, __) => const ActivitiesScreen()),
        GoRoute(
          path: '/activities/:id',
          builder: (_, state) => ActivityDetailScreen(
            activityId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
        GoRoute(path: '/gallery', builder: (_, __) => const GalleryScreen()),
        GoRoute(
          path: '/admissions',
          builder: (_, state) {
            final courseId = state.uri.queryParameters['courseId'];
            return AdmissionScreen(
              initialCourseId: courseId != null ? int.tryParse(courseId) : null,
            );
          },
        ),
        GoRoute(path: '/enquiry', builder: (_, __) => const EnquiryScreen()),

        // Admin routes
        GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
        GoRoute(
          path: '/admin/admissions',
          builder: (_, state) => AdminAdmissionsScreen(
            initialFilter: state.uri.queryParameters['status'],
          ),
        ),
        GoRoute(
          path: '/admin/admissions/:id',
          builder: (_, state) => AdminAdmissionDetailScreen(
            admissionId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(path: '/admin/enquiries', builder: (_, __) => const AdminEnquiriesScreen()),
        GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
        GoRoute(path: '/admin/courses', builder: (_, __) => const AdminCoursesScreen()),
        GoRoute(path: '/admin/activities', builder: (_, __) => const AdminActivitiesScreen()),
      ],
    );
  }
}
