import 'package:go_router/go_router.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/home/home_page.dart';
import '../../features/exam_rooms/exam_rooms_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String examSchedule = '/exam-schedule';
  
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
        path: examSchedule,
        name: 'exam-schedule',
        builder: (context, state) => const ExamRoomsPage(),
      ),
    ],
  );
}

