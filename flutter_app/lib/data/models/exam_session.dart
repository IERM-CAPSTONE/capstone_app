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
  final String? examCode;
  final String? openCode;
  final String? roomNumber;
  final DateTime? examOpenTime;
  final DateTime? examCloseTime;
  final ExamSessionStatus status;
  final List<String> examType;
  final String? semester;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? proctorName;
  final String? hallInvigilatorName;
  final int? maxRows;
  final int? maxColumns;
  final int? totalSeats;
  final bool isArchived;

  ExamSession({
    required this.id,
    this.examRoomId,
    this.proctorId,
    this.hallInvigilatorId,
    this.subjectCode,
    this.examCode,
    this.openCode,
    this.roomNumber,
    this.examOpenTime,
    this.examCloseTime,
    required this.status,
    this.examType = const [],
    this.semester,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.proctorName,
    this.hallInvigilatorName,
    this.maxRows,
    this.maxColumns,
    this.totalSeats,
    this.isArchived = false,
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

  factory PaginatedExamSessionResponse.fromJson(Map<String, dynamic> json) {
    int parseToInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PaginatedExamSessionResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => ExamSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: parseToInt(json['total']),
      page: parseToInt(json['page']),
      limit: parseToInt(json['limit']),
      totalPages: parseToInt(json['totalPages']),
    );
  }

  Map<String, dynamic> toJson() => _$PaginatedExamSessionResponseToJson(this);
}
