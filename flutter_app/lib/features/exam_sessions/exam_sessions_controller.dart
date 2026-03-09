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
        timeSlot: state.filterTimeSlot,
        page: state.currentPage,
        itemsPerPage: state.itemsPerPage,
        studentId: filterStudentId,
        proctorId: state.filterProctorId,
        subjectCode: state.filterSubjectCode,
        examRoomId: state.filterExamRoomId,
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
    String? timeSlot,
    String? subjectCode,
    String? proctorId,
    String? examRoomId,
    bool clearFilters = false,
  }) {
    state = state.copyWith(
      filterStatus: status,
      filterDate: date,
      filterTimeSlot: timeSlot,
      filterSubjectCode: subjectCode,
      filterProctorId: proctorId,
      filterExamRoomId: examRoomId,
      clearFilters: clearFilters,
      currentPage: 1,
    );
    loadExamSessions();
  }

  Future<void> filterByMe() async {
    final currentUser = await _authService.getSavedUserData();
    if (currentUser != null) {
      applyFilters(proctorId: currentUser.id, clearFilters: true);
    }
  }

  void filterAll() {
    applyFilters(proctorId: null, clearFilters: true);
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
