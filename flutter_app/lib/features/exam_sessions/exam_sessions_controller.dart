import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exam_session_repository.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';
import '../../config/dependency_injection.dart';
import 'exam_sessions_state.dart';

class ExamSessionsController extends StateNotifier<ExamSessionsState> {
  final ExamSessionRepository _repository;
  final AuthService _authService;

  ExamSessionsController(this._repository, this._authService)
      : super(const ExamSessionsState()) {
    _initDefaults();
  }

  Future<void> _initDefaults() async {
    // Call loadExamSessions immediately in parallel with other initializations
    loadExamSessions();

    // Fetch proctors
    state = state.copyWith(isLoadingProctors: true, availableProctors: []);
    _repository.getProctors().then((proctors) {
      state = state.copyWith(
        availableProctors: proctors,
        isLoadingProctors: false,
      );
    }).catchError((e) {
      state = state.copyWith(isLoadingProctors: false);
    });

    // Fetch rooms
    state = state.copyWith(isLoadingRooms: true);
    _repository.getRooms().then((rooms) {
      state = state.copyWith(availableRooms: rooms, isLoadingRooms: false);
    }).catchError((e) {
      state = state.copyWith(isLoadingRooms: false);
    });
  }

  Future<void> loadExamSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Get current user to filter by student role if needed
      final currentUser = await _authService.getSavedUserData();
      String? filterStudentId;
      if (currentUser != null && currentUser.role?.toUpperCase() == 'STUDENT') {
        filterStudentId = currentUser.id;
      }

      final result = await _repository.getExamSessions(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.filterStatus,
        date: state.filterDate,
        fromDate: state.filterFromDate,
        toDate: state.filterToDate,
        timeSlot: state.filterTimeSlot,
        page: state.currentPage,
        itemsPerPage: state.itemsPerPage,
        studentId: filterStudentId,
        proctorId: state.filterProctorId,
        subjectCode: state.filterSubjectCode,
        examRoomId: state.filterExamRoomId,
        examType: state.filterExamType,
        campus: state.filterCampus,
      );

      final items = result['items'] as List;

      state = state.copyWith(
        examSessions: items.cast<Map<String, dynamic>>(),
        totalItems: result['totalItems'] as int,
        isLoading: false,
      );
    } catch (e) {
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
    DateTime? fromDate,
    DateTime? toDate,
    String? timeSlot,
    String? subjectCode,
    String? examType,
    String? campus,
    String? proctorId,
    String? examRoomId,
    bool clearFilters = false,
    bool clearSubjectCode = false,
    bool clearExamType = false,
    bool clearCampus = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearExamRoomId = false,
  }) {
    state = state.copyWith(
      filterStatus: status,
      filterDate: date,
      filterFromDate: fromDate,
      filterToDate: toDate,
      filterTimeSlot: timeSlot,
      filterSubjectCode: subjectCode,
      filterExamType: examType,
      filterCampus: campus,
      filterProctorId: proctorId,
      filterExamRoomId: examRoomId,
      clearFilters: clearFilters,
      clearSubjectCode: clearSubjectCode,
      clearExamType: clearExamType,
      clearCampus: clearCampus,
      clearFromDate: clearFromDate,
      clearToDate: clearToDate,
      clearExamRoomId: clearExamRoomId,
      currentPage: 1,
    );
    loadExamSessions();
  }

  void filterToday() {
    applyFilters(date: DateTime.now(), clearFilters: true);
  }

  void filterThisWeek() {
    applyFilters(clearFilters: true);
  }

  void filterPast() {
    applyFilters(clearFilters: true);
  }

  void filterAll() {
    applyFilters(clearFilters: true);
  }

  Future<void> clearFilters() async {
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
final examSessionsControllerProvider = StateNotifierProvider.autoDispose<
    ExamSessionsController, ExamSessionsState>((ref) {
  final apiService = DependencyInjection.get<ApiService>();
  final authService = DependencyInjection.get<AuthService>();
  final repository = ExamSessionRepository(apiService);

  return ExamSessionsController(repository, authService);
});
