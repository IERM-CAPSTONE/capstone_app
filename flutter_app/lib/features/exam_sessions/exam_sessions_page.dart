import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exam_session.dart';
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
import '../auth/registerf_face/exam_officer_student_face_register_page.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class ExamSessionsPage extends ConsumerStatefulWidget {
  const ExamSessionsPage({super.key});

  @override
  ConsumerState<ExamSessionsPage> createState() => _ExamSessionsPageState();
}

class _ExamSessionsPageState extends ConsumerState<ExamSessionsPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedParentTab = 0; // 0: My Exams, 1: All Exams
  int _selectedChildTab = 1; // 0: Today, 1: This Week, 2: All, 3: Past
  String? _userRole;

  bool get _isExamOfficer => _userRole == 'exam_officer';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final authService = DependencyInjection.get<AuthService>();
    final user = await authService.getSavedUserData();
    if (mounted) {
      setState(() {
        _userRole = user?.role?.toLowerCase();
      });
    }
  }

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
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
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
              const SizedBox(width: 8),
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
                onPressed: () => _showFilterSheet(context, state, controller),
                icon: Icon(
                  Icons.filter_list,
                  color: state.hasActiveFilters ? Colors.yellow : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Only show Parent Toggle if role is NOT proctor, student, or it_support
          if (_userRole != 'proctor' && _userRole != 'student' && _userRole != 'it_support') ...[
            _buildParentToggle(controller, l10n),
            const SizedBox(height: 12),
          ],
          if (_isExamOfficer) ...[
            _buildExamOfficerFaceEntry(context),
            const SizedBox(height: 12),
          ],
          _buildToggle(controller, l10n),
          const SizedBox(height: 16),
          _buildActiveFilters(state, controller, l10n),
        ],
      ),
    );
  }

  Widget _buildExamOfficerFaceEntry(BuildContext context) {
    final isVietnamese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.face_retouching_natural,
              color: AppColors.appBarOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVietnamese
                      ? 'Đăng ký khuôn mặt sinh viên'
                      : 'Register student face',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isVietnamese
                      ? 'Luồng riêng cho khảo thí nhập mã sinh viên và bắt đầu quét.'
                      : 'Dedicated flow for exam officers to enter a student code and start scanning.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExamOfficerStudentFaceRegisterPage(),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.appBarOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: Text(isVietnamese ? 'Mở' : 'Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildParentToggle(
      ExamSessionsController controller, AppLocalizations l10n) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildParentTabItem(0, l10n.myExams, () {
            setState(() => _selectedParentTab = 0);
            _applyCurrentFilters(controller);
          }),
          _buildParentTabItem(1, l10n.generalSchedule, () {
            setState(() => _selectedParentTab = 1);
            _applyCurrentFilters(controller);
          }),
        ],
      ),
    );
  }

  Widget _buildParentTabItem(int index, String label, VoidCallback onTap) {
    final bool isSelected = _selectedParentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  void _applyCurrentFilters(ExamSessionsController controller) {
    final bool onlyMy = _selectedParentTab == 0;
    switch (_selectedChildTab) {
      case 0:
        controller.applyFilters(
            date: DateTime.now(), clearFilters: true, onlyMyExams: onlyMy);
        break;
      case 1:
        // This Week
        controller.applyFilters(clearFilters: true, onlyMyExams: onlyMy);
        break;
      case 2:
        // All
        controller.applyFilters(clearFilters: true, onlyMyExams: onlyMy);
        break;
      case 3:
        // Past
        controller.applyFilters(clearFilters: true, onlyMyExams: onlyMy);
        break;
    }
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
              label: '${l10n.status}: ${state.filterExamType}',
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabItem(0, l10n.today, () {
            setState(() => _selectedChildTab = 0);
            _applyCurrentFilters(controller);
          }),
          _buildTabItem(1, l10n.thisWeek, () {
            setState(() => _selectedChildTab = 1);
            _applyCurrentFilters(controller);
          }),
          _buildTabItem(2, l10n.all, () {
            setState(() => _selectedChildTab = 2);
            _applyCurrentFilters(controller);
          }),
          _buildTabItem(3, l10n.past, () {
            setState(() => _selectedChildTab = 3);
            _applyCurrentFilters(controller);
          }),
        ],
      ),
    );
  }
 
  Widget _buildTabItem(int index, String label, VoidCallback onTap) {
    final bool isSelected = _selectedChildTab == index;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ExamSessionsState state,
      ExamSessionsController controller, AppLocalizations l10n) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const ExamSessionCardSkeleton(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter and Group Data
    final filteredSessions = state.examSessions;

    if (filteredSessions.isEmpty) {
      return Center(
        child: Text(
          l10n.noExamsFound,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Group by Date
    final locale = Localizations.localeOf(context).languageCode;
    final Map<String, List<dynamic>> groupedSessions = {};
    for (var data in filteredSessions) {
      final session = data['session'] as ExamSession;
      final dateKey = session.examOpenTime != null
          ? DateFormat('MMM dd\nEEEE', locale).format(session.examOpenTime!)
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

        final isToday = dateKey.contains(
            DateFormat('MMM dd', locale).format(DateTime.now()));
        final displayDate = isToday
            ? '${DateFormat('MMM dd', locale).format(DateTime.now())}\n${l10n.today}'
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
                    userRole: _userRole,
                    onTap: () => _navigateToDetail(session, l10n),
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
      ExamSession session, AppLocalizations l10n) async {
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
            ExamSessionDetailPage(
              examSessionId: session.id,
              initialSession: session,
            ),
      ),
    );
  }
}
