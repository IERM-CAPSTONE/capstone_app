import 'package:json_annotation/json_annotation.dart';

part 'exam_room.g.dart';

enum ExamStatus {
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
}

@JsonSerializable()
class ExamRoom {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final String timeSlot; // e.g., "09:00 AM"
  final ExamStatus status;
  final int totalStudents;
  final int presentStudents;
  final int? capacity;
  final String? location;
  final double? averageScore;

  ExamRoom({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.totalStudents,
    this.presentStudents = 0,
    this.capacity,
    this.location,
    this.averageScore,
  });

  factory ExamRoom.fromJson(Map<String, dynamic> json) =>
      _$ExamRoomFromJson(json);

  Map<String, dynamic> toJson() => _$ExamRoomToJson(this);

  String get statusLabel {
    switch (status) {
      case ExamStatus.scheduled:
        return 'Scheduled';
      case ExamStatus.inProgress:
        return 'In Progress';
      case ExamStatus.completed:
        return 'Completed';
    }
  }

  String get attendanceText => '$presentStudents/$totalStudents';
}
