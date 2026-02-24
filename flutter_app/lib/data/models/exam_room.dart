import 'package:json_annotation/json_annotation.dart';

part 'exam_room.g.dart';

enum ExamStatus {
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('Available')
  available,
  @JsonValue('Scheduled')
  scheduledPascal,
  @JsonValue('InProgress')
  inProgressPascal,
  @JsonValue('Completed')
  completedPascal,
}

@JsonSerializable()
class ExamRoom {
  final String id;
  final String? title;
  final String? roomNumber;
  final String? description;
  final DateTime? date;
  final String? timeSlot;
  @JsonKey(unknownEnumValue: ExamStatus.available)
  final ExamStatus? status;
  final int? totalStudents;
  final int? presentStudents;
  final int? capacity;
  final String? location;
  final double? averageScore;

  ExamRoom({
    required this.id,
    this.title = '',
    this.roomNumber,
    this.description,
    DateTime? date,
    this.timeSlot = '',
    this.status = ExamStatus.scheduled,
    this.totalStudents = 0,
    this.presentStudents = 0,
    this.capacity,
    this.location,
    this.averageScore,
  }) : date = date ?? DateTime.now();

  factory ExamRoom.fromJson(Map<String, dynamic> json) =>
      _$ExamRoomFromJson(json);

  Map<String, dynamic> toJson() => _$ExamRoomToJson(this);

  String get displayName => roomNumber ?? title ?? 'Room $id';

  String get statusLabel {
    switch (status) {
      case ExamStatus.scheduled:
      case ExamStatus.scheduledPascal:
        return 'Scheduled';
      case ExamStatus.inProgress:
      case ExamStatus.inProgressPascal:
        return 'In Progress';
      case ExamStatus.completed:
      case ExamStatus.completedPascal:
        return 'Completed';
      case ExamStatus.available:
        return 'Available';
      default:
        return 'Unknown';
    }
  }

  String get attendanceText => '$presentStudents/$totalStudents';
}

@JsonSerializable()
class PaginatedExamRoomResponse {
  final List<ExamRoom> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedExamRoomResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedExamRoomResponse.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PaginatedExamRoomResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => ExamRoom.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: parseToInt(json['total']),
      page: parseToInt(json['page']),
      limit: parseToInt(json['limit']),
      totalPages: parseToInt(json['totalPages']),
    );
  }

  Map<String, dynamic> toJson() => _$PaginatedExamRoomResponseToJson(this);
}
