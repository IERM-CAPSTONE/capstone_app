import 'package:go_router/go_router.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/auth/register/register_page.dart';
import '../../features/home/home_page.dart';
import '../../features/attendance/attendance_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String attendance = '/attendance';
  
  // static final GoRouter router = GoRouter(
  //   initialLocation: login,
  //   routes: [
  //     GoRoute(
  //       path: login,
  //       name: 'login',
  //       builder: (context, state) => const LoginPage(),
  //     ),
  //     GoRoute(
  //       path: register,
  //       name: 'register',
  //       builder: (context, state) => const RegisterPage(),
  //     ),
  //     GoRoute(
  //       path: home,
  //       name: 'home',
  //       builder: (context, state) => const HomePage(),
  //     ),
  //     GoRoute(
  //       path: attendance,
  //       name: 'attendance',
  //       builder: (context, state) => const AttendancePage(),
  //     ),
  //   ],
  // );
}

