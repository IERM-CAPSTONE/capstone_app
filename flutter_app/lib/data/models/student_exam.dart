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
  final int? seatNumber;
  final StudentExamStatus status;
  final String? currentLocation;
  final String? identityId;
  final bool isMatched;
  final DateTime? checkinTime;
  final DateTime? checkoutTime;
  final bool isValid;
  final DateTime createdAt;
  final DateTime updatedAt;

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
  });

  factory StudentExam.fromJson(Map<String, dynamic> json) =>
      _$StudentExamFromJson(json);

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
  @JsonKey(defaultValue: 0)
  final int total;
  @JsonKey(defaultValue: 1)
  final int page;
  @JsonKey(defaultValue: 10)
  final int limit;
  @JsonKey(defaultValue: 0)
  final int totalPages;

  PaginatedStudentExamResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedStudentExamResponse.fromJson(Map<String, dynamic> json) =>
      _$PaginatedStudentExamResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaginatedStudentExamResponseToJson(this);
}
