import 'package:go_router/go_router.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/proctor_profile_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String profile = '/profile';
  static const String proctorProfile = '/proctor-profile';
  
  static final GoRouter router = GoRouter(
    initialLocation: login,
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
    ],
  );
}

