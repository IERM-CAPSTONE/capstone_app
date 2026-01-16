import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exam_room.dart';

class ExamRoomsState {
  final List<ExamRoom> examRooms;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final ExamStatus? filterStatus;
  final DateTime? filterDate;
  final String? filterTimeSlot;
  final int currentPage;
  final int itemsPerPage;
  final int totalItems;

  const ExamRoomsState({
    this.examRooms = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filterStatus,
    this.filterDate,
    this.filterTimeSlot,
    this.currentPage = 1,
    this.itemsPerPage = 4,
    this.totalItems = 0,
  });

  ExamRoomsState copyWith({
    List<ExamRoom>? examRooms,
    bool? isLoading,
    String? error,
    String? searchQuery,
    ExamStatus? filterStatus,
    DateTime? filterDate,
    String? filterTimeSlot,
    int? currentPage,
    int? itemsPerPage,
    int? totalItems,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return ExamRoomsState(
      examRooms: examRooms ?? this.examRooms,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: clearFilters ? null : (filterStatus ?? this.filterStatus),
      filterDate: clearFilters ? null : (filterDate ?? this.filterDate),
      filterTimeSlot: clearFilters ? null : (filterTimeSlot ?? this.filterTimeSlot),
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  bool get hasActiveFilters =>
      filterStatus != null || filterDate != null || (filterTimeSlot?.isNotEmpty ?? false);

  int get totalPages => (totalItems / itemsPerPage).ceil();
  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}
