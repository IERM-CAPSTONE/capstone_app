import 'package:go_router/go_router.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/home/home_page.dart';
import '../../features/home/proctor_dashboard_page.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/proctor_profile_page.dart';
import '../../features/exam_rooms/exam_rooms_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String profile = '/profile';
  static const String proctorProfile = '/proctor-profile';
  static const String examSchedule = '/exam-schedule';
  static const String proctorDashboard = '/proctor-dashboard';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    redirect: (context, state) async {
      try {
        final authService = DependencyInjection.get<AuthService>();
        final isLoggedIn = authService.isLoggedIn();

        if (isLoggedIn && state.matchedLocation == login) {
          final user = await authService.getSavedUserData();
          final role = user?.role?.toLowerCase();
          print('Token found! Redirecting based on role: $role');
          
          if (role == 'proctor') {
            return proctorDashboard;
          }
          return home;
        }

        if (!isLoggedIn && state.matchedLocation == home) {
          print('No token found. Redirecting to login...');
          return login;
        }
      } catch (e) {
        print('Error checking auth status: $e');
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
        builder: (context, state) => const HomePage(),
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
        path: examSchedule,
        name: 'exam-schedule',
        builder: (context, state) => const ExamRoomsPage(),
      ),
      GoRoute(
        path: proctorDashboard,
        name: 'proctor-dashboard',
        builder: (context, state) => const ProctorDashboardPage(),
      ),
    ],
  );
}
