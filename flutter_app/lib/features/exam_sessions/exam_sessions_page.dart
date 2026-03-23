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
import '../../l10n/generated/app_localizations.dart';
import '../../core/providers/language_provider.dart';
import '../../core/constants/app_colors.dart';

class ExamSessionsPage extends ConsumerStatefulWidget {
  const ExamSessionsPage({super.key});

  @override
  ConsumerState<ExamSessionsPage> createState() => _ExamSessionsPageState();
}

class _ExamSessionsPageState extends ConsumerState<ExamSessionsPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0: Today, 1: This week, 2: All, 3: Past

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examSessionsControllerProvider);
    final controller = ref.read(examSessionsControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
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
                  child: _buildContent(state, controller, l10n),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
              Expanded(
                child: Center(
                  child: Text(
                    l10n.examSchedule,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showLanguageBottomSheet(context, ref),
                icon: const Icon(Icons.language, color: Colors.white),
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
          _buildActiveFilters(state, controller, l10n),
          const SizedBox(height: 16),
          _buildToggle(controller, l10n),
        ],
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(languageProvider);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                title: Text(l10n.vietnamese),
                trailing: currentLocale.languageCode == 'vi'
                    ? const Icon(Icons.check, color: AppColors.appBarOrange)
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('vi');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: Text(l10n.english),
                trailing: currentLocale.languageCode == 'en'
                    ? const Icon(Icons.check, color: AppColors.appBarOrange)
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('en');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFilters(ExamSessionsState state,
      ExamSessionsController controller, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [

          // Subject Filter
          if (state.filterSubjectCode != null) ...[
            _buildFilterChip(
              icon: Icons.book,
              label: state.filterSubjectCode!,
              onTap: () => _showFilterSheet(context, state, controller),
              onClear: () => controller.applyFilters(clearSubjectCode: true),
            ),
            const SizedBox(width: 8),
          ],

          // Exam Type Filter
          if (state.filterExamType != null) ...[
            _buildFilterChip(
              icon: Icons.tag,
              label: 'Type: ${state.filterExamType}',
              onTap: () => _showFilterSheet(context, state, controller),
              onClear: () => controller.applyFilters(clearExamType: true),
            ),
            const SizedBox(width: 8),
          ],

          // Campus Filter
          if (state.filterCampus != null) ...[
            _buildFilterChip(
              icon: Icons.location_on,
              label: 'Campus: ${state.filterCampus}',
              onTap: () => _showFilterSheet(context, state, controller),
              onClear: () => controller.applyFilters(clearCampus: true),
            ),
            const SizedBox(width: 8),
          ],

          // Date Range Filter
          if (state.filterFromDate != null || state.filterToDate != null) ...[
            _buildFilterChip(
              icon: Icons.date_range,
              label: _formatDateRange(state.filterFromDate, state.filterToDate),
              onTap: () => _showFilterSheet(context, state, controller),
              onClear: () => controller.applyFilters(
                clearFromDate: true,
                clearToDate: true,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Room Filter
          if (state.filterExamRoomId != null) ...[
            _buildFilterChip(
              icon: Icons.meeting_room,
              label: l10n.roomLabel(state.filterExamRoomId!),
              onTap: () => _showFilterSheet(context, state, controller),
              onClear: () => controller.applyFilters(clearExamRoomId: true),
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

  String _formatDateRange(DateTime? from, DateTime? to) {
    final formatter = DateFormat('MMM dd');
    if (from != null && to != null) {
      return '${formatter.format(from)} - ${formatter.format(to)}';
    }
    if (from != null) {
      return 'From ${formatter.format(from)}';
    }
    if (to != null) {
      return 'To ${formatter.format(to)}';
    }
    return 'Date Range';
  }

  Widget _buildToggle(
      ExamSessionsController controller, AppLocalizations l10n) {
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
                controller.filterToday();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.today,
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
                controller.filterThisWeek();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'This Week',
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
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = 2);
                controller.filterAll();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 2 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'All',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 2 ? Colors.black87 : Colors.white,
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
                setState(() => _selectedTab = 3);
                controller.filterPast();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 3 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Past',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 3 ? Colors.black87 : Colors.white,
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

  Widget _buildContent(ExamSessionsState state,
      ExamSessionsController controller, AppLocalizations l10n) {
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
      final examDate = session.examOpenTime;
      final today = DateTime.now();
      if (_selectedTab == 0) {
        if (examDate == null) return false;
        return examDate.year == today.year &&
            examDate.month == today.month &&
            examDate.day == today.day;
      }
      if (_selectedTab == 1) {
        if (examDate == null) return false;
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return examDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            examDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      }
      if (_selectedTab == 3) {
        if (examDate == null) return false;
        final todayStart = DateTime(today.year, today.month, today.day);
        return examDate.isBefore(todayStart);
      }
      return true;
    }).toList();

    if (filteredSessions.isEmpty) {
      return Center(
        child: Text(
          l10n.noExamsFound,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Group by Date
    final Map<String, List<dynamic>> groupedSessions = {};
    for (var data in filteredSessions) {
      final session = data['session'] as ExamSession;
      final dateKey = session.examOpenTime != null
          ? DateFormat('MMM dd\nEEEE').format(session.examOpenTime!)
          : l10n.tba;

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
          return _buildPagination(state, controller, l10n);
        }

        final dateKey = groupedSessions.keys.elementAt(index);
        final dateSessions = groupedSessions[dateKey]!;

        final isToday =
            dateKey.contains(DateFormat('MMM dd').format(DateTime.now()));
        final displayDate = isToday
            ? '${DateFormat('MMM dd').format(DateTime.now())}\n${l10n.today}'
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
                    onTap: () => _navigateToDetail(session.id, l10n),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPagination(ExamSessionsState state,
      ExamSessionsController controller, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            l10n.pageOf(state.currentPage, state.totalPages),
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
              ...() {
                final totalPages = state.totalPages;
                final currentPage = state.currentPage;

                // Simple sliding window logic: show up to 5 pages around the current page
                int startPage = (currentPage - 2).clamp(1, totalPages);
                int endPage = (startPage + 4).clamp(1, totalPages);

                // Adjust startPage if we're near the end to keep 5 items visible if possible
                if (endPage - startPage < 4) {
                  startPage = (endPage - 4).clamp(1, totalPages);
                }

                final List<int> pageNumbers = [];
                for (int i = startPage; i <= endPage; i++) {
                  pageNumbers.add(i);
                }

                return pageNumbers.map((pageNumber) {
                  final isCurrentPage = pageNumber == currentPage;
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
                });
              }(),
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
        currentFromDate: state.filterFromDate,
        currentToDate: state.filterToDate,
        currentSubjectCode: state.filterSubjectCode,
        currentExamType: state.filterExamType,
        currentCampus: state.filterCampus,
        currentExamRoomId: state.filterExamRoomId,
        onApply: ({
          status,
          date,
          fromDate,
          toDate,
          subjectCode,
          examType,
          campus,
          examRoomId,
          clearFilters = false,
        }) {
          controller.applyFilters(
            status: status,
            date: date,
            fromDate: fromDate,
            toDate: toDate,
            subjectCode: subjectCode,
            examType: examType,
            campus: campus,
            examRoomId: examRoomId,
            clearFilters: clearFilters,
          );
        },
      ),
    );
  }


  Future<void> _navigateToDetail(
      String examSessionId, AppLocalizations l10n) async {
    // Check user role - only proctor can view detail page
    final authService = DependencyInjection.get<AuthService>();
    final user = await authService.getSavedUserData();
    final role = user?.role?.toUpperCase();

    if (role == 'STUDENT') {
      // Show message that students cannot view detail
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.studentAccessDenied),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
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
