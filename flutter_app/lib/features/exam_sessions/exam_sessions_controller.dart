import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exam_session_repository.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';
import '../../config/dependency_injection.dart';
import 'exam_sessions_state.dart';

class ExamSessionsController extends StateNotifier<ExamSessionsState> {
  final ExamSessionRepository _repository;
  final AuthService _authService;

  ExamSessionsController(this._repository, this._authService) : super(const ExamSessionsState()) {
    loadExamSessions();
  }

  Future<void> loadExamSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      print('📋 Loading exam sessions...');

      // Get current user to filter by role
      final currentUser = await _authService.getSavedUserData();
      String? filterStudentId;
      String? filterProctorId;

      if (currentUser != null) {
        final userRole = currentUser.role?.toUpperCase();
        if (userRole == 'STUDENT') {
          filterStudentId = currentUser.id;
          print('👤 Filtering as STUDENT: $filterStudentId');
        } else if (userRole == 'PROCTOR') {
          filterProctorId = currentUser.id;
          print('👤 Filtering as PROCTOR: $filterProctorId');
        }
      }
      
      final result = await _repository.getExamSessions(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.filterStatus,
        date: state.filterDate,
        timeSlot: state.filterTimeSlot,
        page: state.currentPage,
        itemsPerPage: state.itemsPerPage,
        studentId: filterStudentId,
        proctorId: filterProctorId,
      );
      
      print('✅ Loaded ${(result['items'] as List).length} sessions');
      
      state = state.copyWith(
        examSessions: result['items'] as List<Map<String, dynamic>>,
        totalItems: result['totalItems'] as int,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Error loading exam sessions: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load exam sessions: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadExamSessions();
  }

  void applyFilters({
    String? status,
    DateTime? date,
    String? timeSlot,
  }) {
    state = state.copyWith(
      filterStatus: status,
      filterDate: date,
      filterTimeSlot: timeSlot,
      currentPage: 1,
    );
    loadExamSessions();
  }

  void clearFilters() {
    state = state.copyWith(clearFilters: true, currentPage: 1);
    loadExamSessions();
  }

  void goToNextPage() {
    if (state.hasNextPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadExamSessions();
    }
  }

  void goToPreviousPage() {
    if (state.hasPreviousPage) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      loadExamSessions();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page);
      loadExamSessions();
    }
  }

  void refresh() {
    state = state.copyWith(currentPage: 1);
    loadExamSessions();
  }
}

// Provider - gets shared ApiService from DependencyInjection
final examSessionsControllerProvider =
    StateNotifierProvider.autoDispose<ExamSessionsController, ExamSessionsState>((ref) {
  final apiService = DependencyInjection.get<ApiService>();
  final authService = DependencyInjection.get<AuthService>();
  final repository = ExamSessionRepository(apiService);
  
  print('🏗️ Creating ExamSessionsController');
  
  return ExamSessionsController(repository, authService);
});
