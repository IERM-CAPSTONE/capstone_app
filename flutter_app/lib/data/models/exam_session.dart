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
  final DateTime? proctorCheckedInAt;
  @JsonKey(unknownEnumValue: ExamSessionStatus.scheduled)
  final ExamSessionStatus status;
  final List<String> examType;
  final String? semester;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? proctorName;
  final String? hallInvigilatorName;
  final String? hallInvigilatorUsername;
  final int? maxRows;
  final int? maxColumns;
  final int? totalSeats;
  final bool isArchived;
  final String? campus;

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
    this.proctorCheckedInAt,
    required this.status,
    this.examType = const [],
    this.semester,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.proctorName,
    this.hallInvigilatorName,
    this.hallInvigilatorUsername,
    this.maxRows,
    this.maxColumns,
    this.totalSeats,
    this.isArchived = false,
    this.campus,
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

    // Scheduling times are stored/used as Vietnam local wall-clock times.
    // Some backends may serialize them with a trailing `Z` even though the
    // raw digits should still be interpreted as local time, not converted.
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) {
        return DateTime(
          value.year,
          value.month,
          value.day,
          value.hour,
          value.minute,
          value.second,
          value.millisecond,
          value.microsecond,
        );
      }
      try {
        final raw = value.toString().trim();
        final normalized = raw
            .replaceFirst('T', ' ')
            .replaceAll(RegExp(r'Z$'), '')
            .replaceAll(RegExp(r'[+-]\d{2}:?\d{2}$'), '');
        final match = RegExp(
          r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})(?::(\d{2}))?(?:\.(\d{1,6}))?$',
        ).firstMatch(normalized);

        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          final hour = int.parse(match.group(4)!);
          final minute = int.parse(match.group(5)!);
          final second = int.parse(match.group(6) ?? '0');
          final fractional = (match.group(7) ?? '').padRight(6, '0');
          final millisecond =
              fractional.isEmpty ? 0 : int.parse(fractional.substring(0, 3));
          final microsecond =
              fractional.isEmpty ? 0 : int.parse(fractional.substring(3, 6));

          return DateTime(
            year,
            month,
            day,
            hour,
            minute,
            second,
            millisecond,
            microsecond,
          );
        }

        final parsed = DateTime.parse(raw);
        return parsed.isUtc ? parsed.toLocal() : parsed;
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
      proctorCheckedInAt: parseDate(json['proctorCheckedInAt']),
      status: status,
      examType: parseList(json['examType'] ?? json['examTypes'] ?? json['examPart']),
      semester: _parseSemester(json),
      note: json['note']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      proctorName: _parseUserName(json['proctor']) ?? json['proctorName']?.toString(),
      hallInvigilatorName: _parseUserName(json['hallInvigilator']) ?? json['hallInvigilatorName']?.toString(),
      hallInvigilatorUsername: (json['hallInvigilator'] as Map<String, dynamic>?)?['username']?.toString()
          ?? json['hallInvigilatorUsername']?.toString(),
      maxRows: (json['maxRows'] as num?)?.toInt(),
      maxColumns: (json['maxColumns'] as num?)?.toInt(),
      totalSeats: (json['totalSeats'] as num?)?.toInt(),
      isArchived: json['isArchived'] as bool? ?? false,
      campus: json['campus']?.toString(),
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

  bool get isScheduled {
    final now = DateTime.now();
    if (examOpenTime != null) {
      return examOpenTime!.isAfter(now);
    }
    return status == ExamSessionStatus.scheduled ||
        status == ExamSessionStatus.scheduledLower;
  }

  bool get isOngoing {
    final now = DateTime.now();
    if (examOpenTime != null && examCloseTime != null) {
      return !examOpenTime!.isAfter(now) && !examCloseTime!.isBefore(now);
    }
    return status == ExamSessionStatus.ongoing ||
        status == ExamSessionStatus.ongoingLower;
  }

  bool get isEnded {
    final now = DateTime.now();
    if (examCloseTime != null) {
      return examCloseTime!.isBefore(now);
    }
    return status == ExamSessionStatus.ended ||
        status == ExamSessionStatus.endedLower;
  }
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
