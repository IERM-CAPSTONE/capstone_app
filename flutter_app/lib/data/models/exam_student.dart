import 'package:json_annotation/json_annotation.dart';

part 'exam_student.g.dart';

enum AttendanceStatus {
  @JsonValue('present')
  present,
  @JsonValue('absent')
  absent,
  @JsonValue('pending')
  pending,
}

@JsonSerializable()
class ExamStudent {
  final String id;
  final String name;
  final String studentId;
  final int? score;
  final AttendanceStatus attendanceStatus;
  final DateTime? checkInTime;
  final String? avatarUrl;

  ExamStudent({
    required this.id,
    required this.name,
    required this.studentId,
    this.score,
    required this.attendanceStatus,
    this.checkInTime,
    this.avatarUrl,
  });

  factory ExamStudent.fromJson(Map<String, dynamic> json) =>
      _$ExamStudentFromJson(json);

  Map<String, dynamic> toJson() => _$ExamStudentToJson(this);

  String get scoreText => score != null ? '$score' : '-';
  
  bool get isPresent => attendanceStatus == AttendanceStatus.present;
  bool get isAbsent => attendanceStatus == AttendanceStatus.absent;
}
