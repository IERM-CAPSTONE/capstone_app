import 'package:go_router/go_router.dart';

import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/devices/my_devices_page.dart';
import '../../features/exam_sessions/exam_sessions_page.dart';
import '../../features/home/proctor_dashboard_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/profile/proctor_profile_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/tickets/ticket_detail_page.dart';
import '../../features/tickets/tickets_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String profile = '/profile';
  static const String proctorProfile = '/proctor-profile';
  static const String myDeviceList = '/proctor-profile/my-devices';
  static const String examSchedule = '/exam-schedule';
  static const String proctorDashboard = '/proctor-dashboard';
  static const String tickets = '/tickets';
  static const String notifications = '/notifications';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    redirect: (context, state) async {
      try {
        final authService = DependencyInjection.get<AuthService>();
        final isLoggedIn = authService.isLoggedIn();

        if (isLoggedIn) {
          final user = await authService.getSavedUserData();
          final role = user?.role?.toLowerCase();

          if (state.matchedLocation == login) {
            return examSchedule;
          }

          if (state.matchedLocation == profile &&
              (role == 'proctor' ||
                  role == 'it_support' ||
                  role == 'hall_invigilator')) {
            return proctorProfile;
          }

          if (state.matchedLocation == home) {
            return examSchedule;
          }

          if (state.matchedLocation == proctorProfile &&
              role != 'proctor' &&
              role != 'it_support' &&
              role != 'hall_invigilator') {
            return profile;
          }
        }

        if (!isLoggedIn && state.matchedLocation == examSchedule) {
          return login;
        }
      } catch (_) {
        return null;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const ExamSessionsPage(),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: proctorProfile,
        name: 'proctor-profile',
        builder: (context, state) => const ProctorProfilePage(),
      ),
      GoRoute(
        path: myDeviceList,
        name: 'proctor-my-devices',
        builder: (context, state) => const MyDevicesPage(),
      ),
      GoRoute(
        path: examSchedule,
        name: 'exam-schedule',
        builder: (context, state) => const ExamSessionsPage(),
      ),
      GoRoute(
        path: proctorDashboard,
        name: 'proctor-dashboard',
        builder: (context, state) => const ProctorDashboardPage(),
      ),
      GoRoute(
        path: tickets,
        name: 'tickets',
        builder: (context, state) => const TicketsPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'ticket-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TicketDetailPage(ticketId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}
