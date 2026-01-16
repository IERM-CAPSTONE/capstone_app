import 'package:go_router/go_router.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/home/home_page.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../../features/exam_rooms/exam_rooms_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String examSchedule = '/exam-schedule';
  
  static final GoRouter router = GoRouter(
    initialLocation: login,
    redirect: (context, state) {
      try {
        final authService = DependencyInjection.get<AuthService>();
        final isLoggedIn = authService.isLoggedIn();
        
        if (isLoggedIn && state.matchedLocation == login) {
          print('Token found! Redirecting to home...');
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
        path: examSchedule,
        name: 'exam-schedule',
        builder: (context, state) => const ExamRoomsPage(),
      ),
    ],
  );
}

