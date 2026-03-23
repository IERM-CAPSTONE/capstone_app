import 'package:json_annotation/json_annotation.dart';

part 'student_exam.g.dart';

enum StudentExamStatus {
  @JsonValue('REGISTERED')
  registered,
  @JsonValue('CHECKEDIN')
  checkedIn,
  @JsonValue('CHECKEDOUT')
  checkedOut,
  @JsonValue('MOVED')
  moved,
  @JsonValue('REMOVED')
  removed,
}

@JsonSerializable()
class StudentExam {
  final String id;
  final String examSessionId;
  final String studentId;
  final String? seatNumber; // Changed from int? to String?
  final StudentExamStatus status;
  final String? currentLocation;
  final String? identityId;
  final bool isMatched;
  final DateTime? checkinTime;
  final DateTime? checkoutTime;
  final bool isValid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? studentName;
  final String? studentCode;
  final String? studentAvatarUrl;
  final Map<String, dynamic>? rawStudent;

  StudentExam({
    required this.id,
    required this.examSessionId,
    required this.studentId,
    this.seatNumber,
    required this.status,
    this.currentLocation,
    this.identityId,
    required this.isMatched,
    this.checkinTime,
    this.checkoutTime,
    required this.isValid,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.studentCode,
    this.studentAvatarUrl,
    this.rawStudent,
  });

  factory StudentExam.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final student = json['student'] as Map<String, dynamic>?;

    return StudentExam(
      id: json['id'] as String? ?? '',
      examSessionId: json['examSessionId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      seatNumber: json['seatNumber']?.toString(),
      status: StudentExamStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toUpperCase() ==
            (json['status'] as String? ?? '').toUpperCase(),
        orElse: () => StudentExamStatus.registered,
      ),
      currentLocation: json['currentLocation'] as String?,
      identityId: json['identityId'] as String?,
      isMatched: json['isMatched'] as bool? ?? false,
      checkinTime: parseDate(json['checkinTime']),
      checkoutTime: parseDate(json['checkoutTime']),
      isValid: json['isValid'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
      studentName: json['studentName'] as String? ??
          student?['fullName'] as String?,
      studentCode: json['studentCode'] as String? ??
          student?['code'] as String?,
      studentAvatarUrl: json['studentAvatarUrl'] as String? ??
          json['avatarUrl'] as String? ??
          student?['avatarUrl'] as String?,
      rawStudent: student,
    );
  }

  Map<String, dynamic> toJson() => _$StudentExamToJson(this);

  bool get isPresent =>
      status == StudentExamStatus.checkedIn ||
      status == StudentExamStatus.checkedOut;

  bool get isAbsent =>
      status == StudentExamStatus.registered && checkinTime == null;
}

@JsonSerializable()
class PaginatedStudentExamResponse {
  final List<StudentExam> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedStudentExamResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedStudentExamResponse.fromJson(Map<String, dynamic> json) {
    // Ensure proper type conversion for integer fields
    int parseToInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PaginatedStudentExamResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => StudentExam.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: parseToInt(json['total']),
      page: parseToInt(json['page']),
      limit: parseToInt(json['limit']),
      totalPages: parseToInt(json['totalPages']),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': data,
        'total': total,
        'page': page,
        'limit': limit,
        'totalPages': totalPages,
      };
}
