import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exam_session_repository.dart';
import '../../data/services/api_service.dart';
import '../../config/env.dart';
import 'package:dio/dio.dart';
import 'exam_sessions_state.dart';

class ExamSessionsController extends StateNotifier<ExamSessionsState> {
  final ExamSessionRepository _repository;

  ExamSessionsController(this._repository) : super(const ExamSessionsState()) {
    loadExamSessions();
  }

  Future<void> loadExamSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getExamSessions(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.filterStatus,
        date: state.filterDate,
        timeSlot: state.filterTimeSlot,
        page: state.currentPage,
        itemsPerPage: state.itemsPerPage,
      );
      
      state = state.copyWith(
        examSessions: result['items'] as List<Map<String, dynamic>>,
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

// Providers
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  
  // Add auth interceptor if needed
  // dio.interceptors.add(AuthInterceptor());
  
  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});

final examSessionRepositoryProvider = Provider<ExamSessionRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ExamSessionRepository(apiService);
});

final examSessionsControllerProvider =
    StateNotifierProvider<ExamSessionsController, ExamSessionsState>((ref) {
  final repository = ref.watch(examSessionRepositoryProvider);
  return ExamSessionsController(repository);
});
