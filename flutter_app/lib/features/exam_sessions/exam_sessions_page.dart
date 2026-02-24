import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/exam_session.dart';
import '../../core/routes/app_routes.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import 'exam_sessions_controller.dart';
import 'exam_sessions_state.dart';
import 'widgets/exam_session_filter_sheet.dart';
import 'package:intl/intl.dart';
import 'widgets/redesigned_exam_session_card.dart';
import '../profile/widgets/bottom_nav_bar.dart';
import 'exam_session_detail_page.dart';

class ExamSessionsPage extends ConsumerStatefulWidget {
  const ExamSessionsPage({super.key});

  @override
  ConsumerState<ExamSessionsPage> createState() => _ExamSessionsPageState();
}

class _ExamSessionsPageState extends ConsumerState<ExamSessionsPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0: Upcoming, 1: All Exams

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examSessionsControllerProvider);
    final controller = ref.read(examSessionsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: _buildContent(state, controller),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final state = ref.watch(examSessionsControllerProvider);
    final controller = ref.read(examSessionsControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Exam Schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showFilterSheet(context, state, controller),
                icon: Icon(
                  Icons.filter_list,
                  color: state.hasActiveFilters ? Colors.yellow : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActiveFilters(state, controller),
          const SizedBox(height: 16),
          _buildToggle(controller),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(
      ExamSessionsState state, ExamSessionsController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Date Filter
          _buildFilterChip(
            icon: Icons.calendar_today,
            label: state.filterDate != null
                ? DateFormat('MMM dd, yyyy').format(state.filterDate!)
                : 'All Dates',
            onTap: () => _selectDate(context, state, controller),
            onClear: state.filterDate != null
                ? () => controller.applyFilters(date: null)
                : null,
          ),
          const SizedBox(width: 8),

          // Subject Filter
          if (state.filterSubjectCode != null) ...[
            _buildFilterChip(
              icon: Icons.book,
              label: state.filterSubjectCode!,
              onTap: () => _showFilterSheet(context, state, controller),
              onClear: () => controller.applyFilters(subjectCode: null),
            ),
            const SizedBox(width: 8),
          ],

          // Proctor Filter
          if (state.filterProctorId != null) ...[
            _buildFilterChip(
              icon: Icons.person,
              label: 'Proctor: ${state.filterProctorId}',
              onTap: () => _showFilterSheet(context, state, controller),
              onClear: () => controller.applyFilters(proctorId: null),
            ),
            const SizedBox(width: 8),
          ],

          // Room Filter
          if (state.filterExamRoomId != null) ...[
            _buildFilterChip(
              icon: Icons.meeting_room,
              label: 'Room: ${state.filterExamRoomId}',
              onTap: () => _showFilterSheet(context, state, controller),
              onClear: () => controller.applyFilters(examRoomId: null),
            ),
            const SizedBox(width: 8),
          ],

          // Search Query
          if (state.searchQuery.isNotEmpty) ...[
            _buildFilterChip(
              icon: Icons.search,
              label: state.searchQuery,
              onTap: () {},
              onClear: () => controller.setSearchQuery(''),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(ExamSessionsController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = 0);
                controller.filterAll();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Upcoming',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 0 ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = 1);
                controller.filterByMe();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'My Exams',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 1 ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      ExamSessionsState state, ExamSessionsController controller) {
    // Show skeleton loading instead of error
    if (state.isLoading || state.error != null) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const ExamSessionCardSkeleton(),
      );
    }

    // Filter and Group Data
    final filteredSessions = state.examSessions.where((data) {
      final session = data['session'] as ExamSession;
      if (_selectedTab == 0) {
        return session.status == ExamSessionStatus.scheduled ||
            session.status == ExamSessionStatus.ongoing;
      }
      return true;
    }).toList();

    if (filteredSessions.isEmpty) {
      return const Center(
        child: Text(
          'No exams found',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Group by Date
    final Map<String, List<dynamic>> groupedSessions = {};
    for (var data in filteredSessions) {
      final session = data['session'] as ExamSession;
      final dateKey = session.examOpenTime != null
          ? DateFormat('MMM dd\nEEEE').format(session.examOpenTime!)
          : 'TBA';

      if (!groupedSessions.containsKey(dateKey)) {
        groupedSessions[dateKey] = [];
      }
      groupedSessions[dateKey]!.add(data);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedSessions.length + 1,
      itemBuilder: (context, index) {
        if (index == groupedSessions.length) {
          return _buildPagination(state, controller);
        }

        final dateKey = groupedSessions.keys.elementAt(index);
        final dateSessions = groupedSessions[dateKey]!;

        final isToday =
            dateKey.contains(DateFormat('MMM dd').format(DateTime.now()));
        final displayDate = isToday
            ? DateFormat('MMM dd').format(DateTime.now()) + '\nToday'
            : dateKey;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  displayDate,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: dateSessions.map((data) {
                  final session = data['session'] as ExamSession;
                  return RedesignedExamSessionCard(
                    session: session,
                    onTap: () => _navigateToDetail(session.id),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPagination(
      ExamSessionsState state, ExamSessionsController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: state.hasPreviousPage
                    ? () => controller.goToPreviousPage()
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: const Color(0xFFFF6B35),
                disabledColor: Colors.grey[300],
              ),
              const SizedBox(width: 16),
              ...List.generate(
                state.totalPages.clamp(0, 5),
                (index) {
                  final pageNumber = index + 1;
                  final isCurrentPage = pageNumber == state.currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        // Add goToPage method if needed
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrentPage
                              ? const Color(0xFFFF6B35)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '$pageNumber',
                            style: TextStyle(
                              color:
                                  isCurrentPage ? Colors.white : Colors.black87,
                              fontWeight: isCurrentPage
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed:
                    state.hasNextPage ? () => controller.goToNextPage() : null,
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFFFF6B35),
                disabledColor: Colors.grey[300],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ExamSessionsState state,
      ExamSessionsController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExamSessionFilterSheet(
        currentStatus: state.filterStatus,
        currentDate: state.filterDate,
        currentSubjectCode: state.filterSubjectCode,
        currentProctorId: state.filterProctorId,
        currentExamRoomId: state.filterExamRoomId,
        onApply: ({status, date, subjectCode, proctorId, examRoomId}) {
          controller.applyFilters(
            status: status,
            date: date,
            subjectCode: subjectCode,
            proctorId: proctorId,
            examRoomId: examRoomId,
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ExamSessionsState state,
      ExamSessionsController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.filterDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      controller.applyFilters(date: picked);
    }
  }

  Future<void> _navigateToDetail(String examSessionId) async {
    // Check user role - only proctor can view detail page
    final authService = DependencyInjection.get<AuthService>();
    final user = await authService.getSavedUserData();
    final role = user?.role?.toUpperCase();

    if (role == 'STUDENT') {
      // Show message that students cannot view detail
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Students cannot view exam session details. Only proctors have access.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExamSessionDetailPage(examSessionId: examSessionId),
      ),
    );
  }
}
