import 'package:json_annotation/json_annotation.dart';

part 'exam_session.g.dart';

enum ExamSessionStatus {
  @JsonValue('Scheduled')
  scheduled,
  @JsonValue('Ongoing')
  ongoing,
  @JsonValue('Ended')
  ended,
}

@JsonSerializable()
class ExamSession {
  final String id;
  final String? examRoomId;
  final String? proctorId;
  final String? hallInvigilatorId;
  final String? subjectCode;
  final DateTime? examOpenTime;
  final DateTime? examCloseTime;
  final ExamSessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamSession({
    required this.id,
    this.examRoomId,
    this.proctorId,
    this.hallInvigilatorId,
    this.subjectCode,
    this.examOpenTime,
    this.examCloseTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExamSession.fromJson(Map<String, dynamic> json) =>
      _$ExamSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ExamSessionToJson(this);

  String get statusLabel {
    switch (status) {
      case ExamSessionStatus.scheduled:
        return 'Scheduled';
      case ExamSessionStatus.ongoing:
        return 'In Progress';
      case ExamSessionStatus.ended:
        return 'Completed';
    }
  }

  String get title => subjectCode ?? 'Unknown Subject';

  String get timeSlot {
    if (examOpenTime == null) return 'TBA';
    final hour = examOpenTime!.hour;
    final minute = examOpenTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  DateTime? get date => examOpenTime;
}

@JsonSerializable()
class PaginatedExamSessionResponse {
  final List<ExamSession> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedExamSessionResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedExamSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$PaginatedExamSessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaginatedExamSessionResponseToJson(this);
}
