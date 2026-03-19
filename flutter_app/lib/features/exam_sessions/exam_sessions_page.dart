import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../profile/widgets/bottom_nav_bar.dart';
import 'exam_session_detail_page.dart';
import 'exam_sessions_controller.dart';
import 'widgets/exam_sessions_content.dart';
import 'widgets/exam_sessions_header.dart';
import 'widgets/exam_sessions_summary.dart';
import 'widgets/exam_sessions_toggle.dart';

class ExamSessionsPage extends ConsumerStatefulWidget {
  const ExamSessionsPage({super.key});

  @override
  ConsumerState<ExamSessionsPage> createState() => _ExamSessionsPageState();
}

class _ExamSessionsPageState extends ConsumerState<ExamSessionsPage> {
  int _selectedTab = 0; // 0: Upcoming, 1: All Exams

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examSessionsControllerProvider);
    final controller = ref.read(examSessionsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: SafeArea(
        child: Column(
          children: [
            ExamSessionsHeader(onBackPressed: () => context.go(AppRoutes.home)),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F3F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    ExamSessionsToggle(
                      selectedTab: _selectedTab,
                      onTabChanged: (tabIndex) => setState(() => _selectedTab = tabIndex),
                    ),
                    ExamSessionsSummary(
                      examSessions: state.examSessions,
                      isLoading: state.isLoading,
                    ),
                    Expanded(
                      child: ExamSessionsContent(
                        state: state,
                        controller: controller,
                        selectedTab: _selectedTab,
                        onSessionTap: _handleSessionTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Future<void> _handleSessionTap(String examSessionId) async {
    final authService = DependencyInjection.get<AuthService>();
    final user = await authService.getSavedUserData();
    if (!mounted) return;

    final role = user?.role?.toUpperCase();
    final l10n = AppLocalizations.of(context)!;

    if (role == 'STUDENT') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.studentAccessDenied),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamSessionDetailPage(examSessionId: examSessionId),
      ),
    );
  }
}
