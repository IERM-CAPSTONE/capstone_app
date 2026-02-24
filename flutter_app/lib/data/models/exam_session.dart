import 'package:json_annotation/json_annotation.dart';

part 'exam_session.g.dart';

enum ExamSessionStatus {
  @JsonValue('Scheduled')
  scheduled,
  @JsonValue('Ongoing')
  ongoing,
  @JsonValue('Ended')
  ended,
  @JsonValue('scheduled')
  scheduledLower,
  @JsonValue('ongoing')
  ongoingLower,
  @JsonValue('ended')
  endedLower,
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
  @JsonKey(unknownEnumValue: ExamSessionStatus.scheduled)
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

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    // Helper to parse list of strings
    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) return [value];
      return [];
    }

    // Capture the generated result first
    final session = _$ExamSessionFromJson(json);

    // Manually override examType to ensure it's captured from 'examType' or 'examTypes'
    final rawExamType = json['examType'] ?? json['examTypes'];

    if (rawExamType != null) {
      return ExamSession(
        id: session.id,
        examRoomId: session.examRoomId,
        proctorId: session.proctorId,
        hallInvigilatorId: session.hallInvigilatorId,
        subjectCode: session.subjectCode,
        examCode: session.examCode,
        openCode: session.openCode,
        roomNumber: session.roomNumber,
        examOpenTime: session.examOpenTime,
        examCloseTime: session.examCloseTime,
        status: session.status,
        examType: parseList(rawExamType),
        semester: session.semester,
        note: session.note,
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        proctorName: session.proctorName,
        hallInvigilatorName: session.hallInvigilatorName,
        maxRows: session.maxRows,
        maxColumns: session.maxColumns,
        totalSeats: session.totalSeats,
        isArchived: session.isArchived,
      );
    }

    return session;
  }

  Map<String, dynamic> toJson() => _$ExamSessionToJson(this);

  String get statusLabel {
    switch (status) {
      case ExamSessionStatus.scheduled:
      case ExamSessionStatus.scheduledLower:
        return 'Scheduled';
      case ExamSessionStatus.ongoing:
      case ExamSessionStatus.ongoingLower:
        return 'In Progress';
      case ExamSessionStatus.ended:
      case ExamSessionStatus.endedLower:
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

  bool get isScheduled =>
      status == ExamSessionStatus.scheduled ||
      status == ExamSessionStatus.scheduledLower;

  bool get isOngoing =>
      status == ExamSessionStatus.ongoing ||
      status == ExamSessionStatus.ongoingLower;

  bool get isEnded =>
      status == ExamSessionStatus.ended ||
      status == ExamSessionStatus.endedLower;
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

    // Backend may wrap pagination info in a 'meta' object
    final meta = json['meta'] as Map<String, dynamic>?;

    return PaginatedExamSessionResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => ExamSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: parseToInt(meta != null ? meta['total'] : json['total']),
      page: parseToInt(meta != null ? meta['page'] : json['page']),
      limit: parseToInt(meta != null ? meta['limit'] : json['limit']),
      totalPages:
          parseToInt(meta != null ? meta['totalPages'] : json['totalPages']),
    );
  }

  Map<String, dynamic> toJson() => _$PaginatedExamSessionResponseToJson(this);
}
