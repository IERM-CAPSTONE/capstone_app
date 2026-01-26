import 'package:json_annotation/json_annotation.dart';
import 'student_exam.dart';

part 'seat.g.dart';

enum SeatStatus {
  @JsonValue('available')
  available,
  @JsonValue('occupied')
  occupied,
  @JsonValue('present')
  present,
  @JsonValue('absent')
  absent,
}

@JsonSerializable()
class Seat {
  final String id;
  final int row;
  final int column;
  final String? seatNumber;
  final SeatStatus status;
  final StudentExam? studentExam;

  Seat({
    required this.id,
    required this.row,
    required this.column,
    this.seatNumber,
    required this.status,
    this.studentExam,
  });

  factory Seat.fromJson(Map<String, dynamic> json) => _$SeatFromJson(json);

  Map<String, dynamic> toJson() => _$SeatToJson(this);

  bool get isAvailable => status == SeatStatus.available;
  bool get isOccupied => status == SeatStatus.occupied;
  bool get isPresent => status == SeatStatus.present;
  bool get isAbsent => status == SeatStatus.absent;

  String get displayNumber => seatNumber ?? '${row + 1}-${column + 1}';
}

@JsonSerializable()
class SeatingPlan {
  final int rows;
  final int columns;
  final int totalSeats;
  final List<Seat> seats;

  SeatingPlan({
    required this.rows,
    required this.columns,
    required this.totalSeats,
    required this.seats,
  });

  factory SeatingPlan.fromJson(Map<String, dynamic> json) =>
      _$SeatingPlanFromJson(json);

  Map<String, dynamic> toJson() => _$SeatingPlanToJson(this);

  /// Create seating plan from exam session and student exams
  factory SeatingPlan.fromExamData({
    required int maxRows,
    required int maxColumns,
    required int totalSeats,
    required List<StudentExam> studentExams,
  }) {
    final List<Seat> seats = [];

    // Create a map of seatNumber -> StudentExam for quick lookup
    final Map<String, StudentExam> studentBySeat = {};
    for (var student in studentExams) {
      if (student.seatNumber != null) {
        studentBySeat[student.seatNumber!] = student;  // seatNumber is now String
      }
    }

    // Generate all seats
    for (int row = 0; row < maxRows; row++) {
      for (int col = 0; col < maxColumns; col++) {
        final seatNumber = '${row + 1}-${col + 1}';
        final id = 'seat_${row}_$col';

        // Check if this seat has a student
        StudentExam? studentExam;
        SeatStatus status = SeatStatus.available;

        // Try to find student by seat number
        if (studentBySeat.containsKey(seatNumber)) {
          studentExam = studentBySeat[seatNumber];
          
          // Determine status based on student exam status
          if (studentExam != null) {
            if (studentExam.status == StudentExamStatus.checkedIn ||
                studentExam.status == StudentExamStatus.checkedOut) {
              status = SeatStatus.present;
            } else if (studentExam.status == StudentExamStatus.registered) {
              status = SeatStatus.occupied;
            } else if (studentExam.status == StudentExamStatus.removed) {
              status = SeatStatus.absent;
            }
          }
        }

        seats.add(Seat(
          id: id,
          row: row,
          column: col,
          seatNumber: seatNumber,
          status: status,
          studentExam: studentExam,
        ));
      }
    }

    return SeatingPlan(
      rows: maxRows,
      columns: maxColumns,
      totalSeats: totalSeats,
      seats: seats,
    );
  }

  Seat? getSeatAt(int row, int column) {
    try {
      return seats.firstWhere(
        (seat) => seat.row == row && seat.column == column,
      );
    } catch (e) {
      return null;
    }
  }

  int get availableCount =>
      seats.where((s) => s.status == SeatStatus.available).length;
  int get occupiedCount =>
      seats.where((s) => s.status == SeatStatus.occupied).length;
  int get presentCount =>
      seats.where((s) => s.status == SeatStatus.present).length;
  int get absentCount =>
      seats.where((s) => s.status == SeatStatus.absent).length;
}
