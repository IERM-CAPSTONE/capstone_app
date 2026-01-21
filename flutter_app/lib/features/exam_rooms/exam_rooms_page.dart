import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/exam_session.dart';
import '../../data/models/user_model.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../../core/routes/app_routes.dart';
import 'exam_sessions_controller.dart';
import 'exam_sessions_state.dart';
import 'package:intl/intl.dart';
import 'widgets/redesigned_exam_session_card.dart';
import '../profile/widgets/bottom_nav_bar.dart';
import 'exam_room_detail_page.dart';

class ExamRoomsPage extends ConsumerStatefulWidget {
  const ExamRoomsPage({super.key});

  @override
  ConsumerState<ExamRoomsPage> createState() => _ExamRoomsPageState();
}

class _ExamRoomsPageState extends ConsumerState<ExamRoomsPage> {
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
                  color: Color(0xFFF5F5F5), // Light grey background
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
              const SizedBox(width: 24), // Balance the back button
            ],
          ),
          const SizedBox(height: 24),
          _buildToggle(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Light translucent bg
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
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
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? const Color(0xFFFF6B35) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'All Exams',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
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



  Widget _buildContent(ExamSessionsState state, ExamSessionsController controller) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: Colors.red)),
      );
    }

    // Filter and Group Data
    final filteredSessions = state.examSessions.where((data) {
      final session = data['session'] as ExamSession;
      if (_selectedTab == 0) {
        // Upcoming: Scheduled or Ongoing
        return session.status == ExamSessionStatus.scheduled || 
               session.status == ExamSessionStatus.ongoing;
      }
      return true; // All Exams
    }).toList();

    if (filteredSessions.isEmpty) {
      return const Center(
        child: Text(
          'No exams found',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    
    // Sort logic (if not already sorted by backend)
    // filteredSessions.sort(...) 

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
      itemCount: groupedSessions.length + 1, // +1 for pagination loader/buttons
      itemBuilder: (context, index) {
        if (index == groupedSessions.length) {
          return _buildPagination(state, controller);
        }

        final dateKey = groupedSessions.keys.elementAt(index);
        final dateSessions = groupedSessions[dateKey]!;

        // Check if date is today
        final isToday = dateKey.contains(DateFormat('MMM dd').format(DateTime.now()));
        final displayDate = isToday 
            ? DateFormat('MMM dd').format(DateTime.now()) + '\nToday'
            : dateKey;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header Column
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
            // Cards Column
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

  Widget _buildPagination(ExamSessionsState state, ExamSessionsController controller) {
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
                      onTap: () => controller.goToPage(pageNumber),
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
                              color: isCurrentPage ? Colors.white : Colors.black87,
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
                onPressed: state.hasNextPage
                    ? () => controller.goToNextPage()
                    : null,
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



  void _navigateToDetail(String examRoomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamRoomDetailPage(examRoomId: examRoomId),
      ),
    );
  }
}
