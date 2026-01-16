import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exam_room.dart';
import '../../data/repositories/exam_room_repository.dart';
import 'exam_rooms_state.dart';

class ExamRoomsController extends StateNotifier<ExamRoomsState> {
  final ExamRoomRepository _repository;

  ExamRoomsController(this._repository) : super(const ExamRoomsState()) {
    loadExamRooms();
  }

  Future<void> loadExamRooms() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getExamRooms(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.filterStatus,
        date: state.filterDate,
        timeSlot: state.filterTimeSlot,
        page: state.currentPage,
        itemsPerPage: state.itemsPerPage,
      );
      
      state = state.copyWith(
        examRooms: result['items'] as List<ExamRoom>,
        totalItems: result['totalItems'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load exam rooms: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadExamRooms();
  }

  void applyFilters({
    ExamStatus? status,
    DateTime? date,
    String? timeSlot,
  }) {
    state = state.copyWith(
      filterStatus: status,
      filterDate: date,
      filterTimeSlot: timeSlot,
      currentPage: 1,
    );
    loadExamRooms();
  }

  void clearFilters() {
    state = state.copyWith(clearFilters: true, currentPage: 1);
    loadExamRooms();
  }

  void goToNextPage() {
    if (state.hasNextPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadExamRooms();
    }
  }

  void goToPreviousPage() {
    if (state.hasPreviousPage) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      loadExamRooms();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page);
      loadExamRooms();
    }
  }

  void refresh() {
    state = state.copyWith(currentPage: 1);
    loadExamRooms();
  }
}

final examRoomRepositoryProvider = Provider<ExamRoomRepository>((ref) {
  return ExamRoomRepository();
});

final examRoomsControllerProvider =
    StateNotifierProvider<ExamRoomsController, ExamRoomsState>((ref) {
  final repository = ref.watch(examRoomRepositoryProvider);
  return ExamRoomsController(repository);
});
