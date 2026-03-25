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
    DateTime? createdAt,
    DateTime? updatedAt,
    this.proctorName,
    this.hallInvigilatorName,
    this.maxRows,
    this.maxColumns,
    this.totalSeats,
    this.isArchived = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    // Helper to parse list of strings or single string into a list
    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) return [value];
      return [];
    }

    // Helper to parse DateTime safely
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    // Capture the generated result safely if possible, but manually parse critical fields
    final String id = json['id']?.toString() ?? '';
    final ExamSessionStatus status = $enumDecodeNullable(
          _$ExamSessionStatusEnumMap, 
          json['status'],
          unknownValue: ExamSessionStatus.scheduled,
        ) ?? ExamSessionStatus.scheduled;

    return ExamSession(
      id: id,
      examRoomId: json['examRoomId']?.toString(),
      proctorId: json['proctorId']?.toString() ??
          (json['proctor'] as Map<String, dynamic>?)?['id']?.toString(),
      hallInvigilatorId: json['hallInvigilatorId']?.toString() ??
          (json['hallInvigilator'] as Map<String, dynamic>?)?['id']?.toString(),
      subjectCode: json['subjectCode']?.toString(),
      examCode: json['examCode']?.toString(),
      openCode: json['openCode']?.toString(),
      roomNumber: json['roomNumber']?.toString(),
      examOpenTime: parseDate(json['examOpenTime']),
      examCloseTime: parseDate(json['examCloseTime']),
      status: status,
      examType: parseList(json['examType'] ?? json['examTypes'] ?? json['examPart']),
      semester: _parseSemester(json),
      note: json['note']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      proctorName: _parseUserName(json['proctor']) ?? json['proctorName']?.toString(),
      hallInvigilatorName: _parseUserName(json['hallInvigilator']) ?? json['hallInvigilatorName']?.toString(),
      maxRows: (json['maxRows'] as num?)?.toInt(),
      maxColumns: (json['maxColumns'] as num?)?.toInt(),
      totalSeats: (json['totalSeats'] as num?)?.toInt(),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  static String? _parseUserName(dynamic userObj) {
    if (userObj == null) return null;
    if (userObj is Map<String, dynamic>) {
      return (userObj['fullName'] ?? userObj['name'] ?? userObj['username'])
          ?.toString();
    }
    return null;
  }
 
  static String? _parseSemester(Map<String, dynamic> json) {
    // 1. Check direct field names
    final value = json['semesterName'] ??
        json['semester_name'] ??
        json['semesterNameEn'] ??
        json['semesterId'];

    if (value != null) return value.toString();

    // 2. Check if 'semester' is an object and has a 'name' field
    final semesterObj = json['semester'];
    if (semesterObj is Map<String, dynamic>) {
      return (semesterObj['name'] ?? semesterObj['id'])?.toString();
    }

    // 3. Fallback to raw field
    return semesterObj?.toString();
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
