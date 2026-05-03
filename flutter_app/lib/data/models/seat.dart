import 'student_exam.dart';
import 'exam_seat_record.dart';

enum SeatStatus {
  available,
  present,
  absent,
  locked;

  String toJson() => name;
  static SeatStatus fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'present':
        return SeatStatus.present;
      case 'absent':
        return SeatStatus.absent;
      case 'locked':
        return SeatStatus.locked;
      case 'occupied':
      case 'assigned':
        return SeatStatus.absent;
      case 'available':
      default:
        return SeatStatus.available;
    }
  }
}

class Seat {
  final String id;
  final int row;
  final int column;
  final int stt;
  final String? seatNumber;
  final SeatStatus status;
  final StudentExam? studentExam;

  Seat({
    required this.id,
    required this.row,
    required this.column,
    required this.stt,
    this.seatNumber,
    required this.status,
    this.studentExam,
  });

  factory Seat.fromJson(Map<String, dynamic> json) => Seat(
        id: json['id'] as String,
        row: json['row'] as int,
        column: json['column'] as int,
        stt: json['stt'] as int? ?? 0,
        seatNumber: json['seatNumber'] as String?,
        status: SeatStatus.fromJson(json['status'] as String),
        studentExam: json['studentExam'] != null
            ? StudentExam.fromJson(json['studentExam'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'row': row,
        'column': column,
        'seatNumber': seatNumber,
        'status': status.toJson(),
        'studentExam': studentExam?.toJson(),
      };

  bool get isAvailable => status == SeatStatus.available;
  bool get isPresent => status == SeatStatus.present;
  bool get isAbsent => status == SeatStatus.absent;
  bool get isLocked => status == SeatStatus.locked;

  String get displayNumber => seatNumber ?? '${row + 1}-${column + 1}';
}

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

  factory SeatingPlan.fromJson(Map<String, dynamic> json) => SeatingPlan(
        rows: json['rows'] as int,
        columns: json['columns'] as int,
        totalSeats: json['totalSeats'] as int,
        seats: (json['seats'] as List<dynamic>)
            .map((e) => Seat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'rows': rows,
        'columns': columns,
        'totalSeats': totalSeats,
        'seats': seats.map((e) => e.toJson()).toList(),
      };

  /// Create seating plan from exam session and student exams
  factory SeatingPlan.fromExamData({
    required int maxRows,
    required int maxColumns,
    required int totalSeats,
    required List<StudentExam> studentExams,
    List<ExamSeatRecord> examSeats = const [],
    String? selectedExamPartCode,
  }) {
    final List<Seat> seats = [];

    // Build ordered seat numbers (row-major) for numeric seatNumber mapping
    final List<String> orderedSeatNumbers = [];
    for (int row = 0; row < maxRows; row++) {
      for (int col = 0; col < maxColumns; col++) {
        orderedSeatNumbers.add('${row + 1}-${col + 1}');
      }
    }

    String? normalizeSeatNumber(String? seatNumber) {
      if (seatNumber == null || seatNumber.trim().isEmpty) return null;
      final trimmed = seatNumber.trim();
      final numeric = int.tryParse(trimmed);
      if (numeric != null) {
        final index = numeric - 1;
        if (index >= 0 && index < orderedSeatNumbers.length) {
          return orderedSeatNumbers[index];
        }
      }
      return trimmed;
    }

    // Create a map of seatNumber -> StudentExam for legacy/fallback lookup
    final Map<String, StudentExam> studentBySeat = {};
    for (var student in studentExams) {
      final normalizedSeat = normalizeSeatNumber(student.seatNumber);
      if (normalizedSeat != null) {
        studentBySeat[normalizedSeat] = student;
      }
    }

    final Map<String, ExamSeatRecord> backendSeatByPosition = {};
    for (final seat in examSeats) {
      // Backend coordinates are one-based in most sessions; keep both keys
      // to stay compatible with older zero-based data if present.
      backendSeatByPosition['${seat.row}-${seat.col}'] = seat;
      backendSeatByPosition['${seat.row + 1}-${seat.col + 1}'] = seat;
    }

    final Map<String, ExamSeatRecord> backendSeatById = {
      for (final seat in examSeats) seat.id: seat,
    };

    final Map<String, StudentExam> studentBySeatPosition = {};
    for (final student in studentExams) {
      final seatPosition = student.seatPosition?.trim();
      if (seatPosition == null || seatPosition.isEmpty) continue;
      final backendSeat = backendSeatById[seatPosition];
      if (backendSeat == null) continue;
      final key = '${backendSeat.row}-${backendSeat.col}';
      studentBySeatPosition[key] = student;
      studentBySeatPosition['${backendSeat.row + 1}-${backendSeat.col + 1}'] =
          student;
    }

    SeatStatus resolveStatus(ExamSeatRecord? backendSeat, StudentExam? student) {
      final backendStatus = backendSeat?.status.trim().toLowerCase();
      switch (backendStatus) {
        case 'locked':
          return SeatStatus.locked;
        case 'present':
          return SeatStatus.present;
        case 'absent':
          return SeatStatus.absent;
        case 'assigned':
          return student != null ? SeatStatus.absent : SeatStatus.available;
        case 'available':
        default:
          if (student == null) {
            return SeatStatus.available;
          }
          if (selectedExamPartCode != null &&
              selectedExamPartCode.trim().isNotEmpty) {
            final part = student.findPartByCode(selectedExamPartCode);
            if (student.status == StudentExamStatus.removed) {
              return SeatStatus.absent;
            }
            if (part?.isCheckedIn == true) {
              return SeatStatus.present;
            }
            return SeatStatus.absent;
          }
          if (student.hasAnyCheckedInPart ||
              student.status == StudentExamStatus.checkedIn ||
              student.status == StudentExamStatus.checkedOut) {
            return SeatStatus.present;
          }
          if (student.status == StudentExamStatus.registered ||
              student.status == StudentExamStatus.removed) {
            return SeatStatus.absent;
          }
          return SeatStatus.absent;
      }
    }

    // Generate all seats
    for (int row = 0; row < maxRows; row++) {
      for (int col = 0; col < maxColumns; col++) {
        final seatNumber = '${row + 1}-${col + 1}';
        final backendSeat = backendSeatByPosition[seatNumber];
        final id = backendSeat?.id ?? 'seat_${row}_$col';

        // Check if this seat has a student
        StudentExam? studentExam;
        SeatStatus status = resolveStatus(backendSeat, null);

        // Prefer authoritative seatPosition mapping, then fallback to seatNumber
        studentExam = studentBySeatPosition[seatNumber];
        studentExam ??= studentBySeat[seatNumber];

        if (studentExam != null) {
          status = resolveStatus(backendSeat, studentExam);
        }

        final stt = (row * maxColumns) + col + 1;

        seats.add(Seat(
          id: id,
          row: row,
          column: col,
          stt: stt,
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
  int get presentCount =>
      seats.where((s) => s.status == SeatStatus.present).length;
  int get absentCount =>
      seats.where((s) => s.status == SeatStatus.absent).length;
  int get lockedCount =>
      seats.where((s) => s.status == SeatStatus.locked).length;
}
