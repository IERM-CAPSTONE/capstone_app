import '../../data/models/user_model.dart';
import '../../data/models/exam_room.dart';

class ExamSessionsState {
  final List<Map<String, dynamic>>
      examSessions; // Contains session + student counts
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? filterStatus;
  final DateTime? filterDate;
  final String? filterTimeSlot;
  final String? filterSubjectCode;
  final String? filterExamType;
  final String? filterCampus;
  final DateTime? filterFromDate;
  final DateTime? filterToDate;
  final String? filterProctorId;
  final String? filterExamRoomId;
  final List<UserModel> availableProctors;
  final List<ExamRoom> availableRooms;
  final int currentPage;
  final int itemsPerPage;
  final int totalItems;
  final bool isLoadingProctors;
  final bool isLoadingRooms;

  const ExamSessionsState({
    this.examSessions = const [],
    this.isLoading = true,
    this.error,
    this.searchQuery = '',
    this.filterStatus,
    this.filterDate,
    this.filterTimeSlot,
    this.filterSubjectCode,
    this.filterExamType,
    this.filterCampus,
    this.filterFromDate,
    this.filterToDate,
    this.filterProctorId,
    this.filterExamRoomId,
    this.availableProctors = const [],
    this.availableRooms = const [],
    this.currentPage = 1,
    this.itemsPerPage = 10,
    this.totalItems = 0,
    this.isLoadingProctors = false,
    this.isLoadingRooms = false,
  });

  ExamSessionsState copyWith({
    List<Map<String, dynamic>>? examSessions,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? filterStatus,
    DateTime? filterDate,
    String? filterTimeSlot,
    String? filterSubjectCode,
    String? filterExamType,
    String? filterCampus,
    DateTime? filterFromDate,
    DateTime? filterToDate,
    String? filterProctorId,
    String? filterExamRoomId,
    List<UserModel>? availableProctors,
    List<ExamRoom>? availableRooms,
    int? currentPage,
    int? itemsPerPage,
    int? totalItems,
    bool? isLoadingProctors,
    bool? isLoadingRooms,
    bool clearError = false,
    bool clearFilters = false,
    bool clearSubjectCode = false,
    bool clearExamType = false,
    bool clearCampus = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearExamRoomId = false,
  }) {
    return ExamSessionsState(
      examSessions: examSessions ?? this.examSessions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? (clearFilters ? null : this.filterStatus),
      filterDate: filterDate ?? (clearFilters ? null : this.filterDate),
      filterTimeSlot:
          filterTimeSlot ?? (clearFilters ? null : this.filterTimeSlot),
      filterSubjectCode: clearSubjectCode
          ? null
          : filterSubjectCode ?? (clearFilters ? null : this.filterSubjectCode),
      filterExamType: clearExamType
          ? null
          : filterExamType ?? (clearFilters ? null : this.filterExamType),
      filterCampus: clearCampus
          ? null
          : filterCampus ?? (clearFilters ? null : this.filterCampus),
      filterFromDate: clearFromDate
          ? null
          : filterFromDate ?? (clearFilters ? null : this.filterFromDate),
      filterToDate: clearToDate
          ? null
          : filterToDate ?? (clearFilters ? null : this.filterToDate),
      filterProctorId:
          filterProctorId ?? (clearFilters ? null : this.filterProctorId),
      filterExamRoomId: clearExamRoomId
          ? null
          : filterExamRoomId ?? (clearFilters ? null : this.filterExamRoomId),
      availableProctors: availableProctors ?? this.availableProctors,
      availableRooms: availableRooms ?? this.availableRooms,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      totalItems: totalItems ?? this.totalItems,
      isLoadingProctors: isLoadingProctors ?? this.isLoadingProctors,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
    );
  }

  bool get hasActiveFilters =>
      filterStatus != null ||
      filterDate != null ||
      (filterTimeSlot?.isNotEmpty ?? false) ||
      filterSubjectCode != null ||
      filterExamType != null ||
      filterCampus != null ||
      filterFromDate != null ||
      filterToDate != null ||
      filterProctorId != null ||
      filterExamRoomId != null;

  int get totalPages {
    if (totalItems == 0 && examSessions.isNotEmpty) return 1;
    return (totalItems / itemsPerPage).ceil();
  }

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}
