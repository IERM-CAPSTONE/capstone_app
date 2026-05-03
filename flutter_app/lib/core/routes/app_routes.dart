import 'package:go_router/go_router.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/devices/my_devices_page.dart';
import '../../features/exam_sessions/exam_sessions_page.dart';
import '../../features/home/proctor_dashboard_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/tickets/ticket_detail_page.dart';
import '../../features/tickets/tickets_page.dart';
import '../../features/face_enrollment/student/otp_input_page.dart';
import '../../features/face_enrollment/invigilator/enrollment_dashboard_page.dart';
import '../../features/face_enrollment/student/face_storage_consent_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String myDeviceList = '/profile/my-devices';
  static const String examSchedule = '/exam-schedule';
  static const String proctorDashboard = '/proctor-dashboard';
  static const String tickets = '/tickets';
  static const String notifications = '/notifications';
  
  static const String faceEnrollmentOtp = '/face-enrollment-otp';
  static const String faceEnrollmentDashboard = '/face-enrollment-dashboard';
  static const String faceEnrollmentConsent = '/face-enrollment-consent';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginPage()),
      GoRoute(path: home, builder: (context, state) => const ExamSessionsPage()),
      GoRoute(path: examSchedule, builder: (context, state) => const ExamSessionsPage()),
      GoRoute(path: faceEnrollmentOtp, builder: (context, state) => const OtpInputPage()),
      GoRoute(path: faceEnrollmentDashboard, builder: (context, state) => const EnrollmentDashboardPage()),
      GoRoute(path: faceEnrollmentConsent, builder: (context, state) => const FaceStorageConsentPage()),
      GoRoute(path: profile, builder: (context, state) => const ProfilePage()),
      GoRoute(path: myDeviceList, builder: (context, state) => const MyDevicesPage()),
      GoRoute(path: proctorDashboard, builder: (context, state) => const ProctorDashboardPage()),
      GoRoute(path: tickets, builder: (context, state) => const TicketsPage()),
      GoRoute(
        path: '/tickets/:ticketId',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId']!;
          return TicketDetailPage(ticketId: ticketId);
        },
      ),
      GoRoute(path: notifications, builder: (context, state) => const NotificationsPage()),
    ],
  );
}