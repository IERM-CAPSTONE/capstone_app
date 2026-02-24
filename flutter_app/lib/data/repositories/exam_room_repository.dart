import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exam_room.dart';
import '../models/exam_student.dart';
import '../models/student_exam.dart';

final examRoomRepositoryProvider = Provider((ref) => ExamRoomRepository());

/// Mock repository for exam rooms data
class ExamRoomRepository {
  /// Get all exam rooms with optional filters
  Future<Map<String, dynamic>> getExamRooms({
    String? search,
    ExamStatus? status,
    DateTime? date,
    String? timeSlot,
    int page = 1,
    int itemsPerPage = 4,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    var rooms = _mockExamRooms;

    // Apply filters
    if (search != null && search.isNotEmpty) {
      rooms = rooms
          .where((room) =>
              room.title?.toLowerCase().contains(search.toLowerCase()) ?? false)
          .toList();
    }

    if (status != null) {
      rooms = rooms.where((room) => room.status == status).toList();
    }

    if (date != null) {
      rooms = rooms
          .where((room) =>
              room.date?.year == date.year &&
              room.date?.month == date.month &&
              room.date?.day == date.day)
          .toList();
    }

    if (timeSlot != null && timeSlot.isNotEmpty) {
      rooms = rooms.where((room) => room.timeSlot == timeSlot).toList();
    }

    // Calculate pagination
    final totalItems = rooms.length;
    final startIndex = (page - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, totalItems);

    // Get paginated items
    final paginatedRooms = rooms.sublist(
      startIndex.clamp(0, totalItems),
      endIndex,
    );

    return {
      'items': paginatedRooms,
      'totalItems': totalItems,
      'currentPage': page,
      'itemsPerPage': itemsPerPage,
    };
  }

  /// Get exam room by ID
  Future<ExamRoom?> getExamRoomById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockExamRooms.firstWhere((room) => room.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get students in an exam room
  Future<List<ExamStudent>> getExamStudents(String examRoomId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockStudents[examRoomId] ?? [];
  }

  /// Get student exams by exam session ID (for seating plan)
  Future<List<StudentExam>> getExamStudentsBySessionId(
      String examSessionId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Mock data: Create student exams with seat numbers
    return [
      StudentExam(
        id: '1',
        examSessionId: examSessionId,
        studentId: 'S001',
        seatNumber: '1',
        status: StudentExamStatus.checkedIn,
        currentLocation: 'Room 101',
        identityId: 'ID001',
        isMatched: true,
        checkinTime: DateTime.now().subtract(const Duration(hours: 1)),
        checkoutTime: null,
        isValid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      StudentExam(
        id: '2',
        examSessionId: examSessionId,
        studentId: 'S002',
        seatNumber: '2',
        status: StudentExamStatus.registered,
        currentLocation: null,
        identityId: null,
        isMatched: false,
        checkinTime: null,
        checkoutTime: null,
        isValid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      StudentExam(
        id: '3',
        examSessionId: examSessionId,
        studentId: 'S003',
        seatNumber: '7',
        status: StudentExamStatus.checkedIn,
        currentLocation: 'Room 101',
        identityId: 'ID003',
        isMatched: true,
        checkinTime: DateTime.now().subtract(const Duration(minutes: 45)),
        checkoutTime: null,
        isValid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      StudentExam(
        id: '4',
        examSessionId: examSessionId,
        studentId: 'S004',
        seatNumber: '13',
        status: StudentExamStatus.removed,
        currentLocation: null,
        identityId: null,
        isMatched: false,
        checkinTime: null,
        checkoutTime: null,
        isValid: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      StudentExam(
        id: '5',
        examSessionId: examSessionId,
        studentId: 'S005',
        seatNumber: '18',
        status: StudentExamStatus.checkedIn,
        currentLocation: 'Room 101',
        identityId: 'ID005',
        isMatched: true,
        checkinTime: DateTime.now().subtract(const Duration(minutes: 30)),
        checkoutTime: null,
        isValid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      StudentExam(
        id: '6',
        examSessionId: examSessionId,
        studentId: 'S006',
        seatNumber: '24',
        status: StudentExamStatus.registered,
        currentLocation: null,
        identityId: null,
        isMatched: false,
        checkinTime: null,
        checkoutTime: null,
        isValid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Mock data
  static final List<ExamRoom> _mockExamRooms = [
    ExamRoom(
      id: '1',
      title: 'Mathematics Final Exam',
      description: 'Mathematics Room 101',
      date: DateTime(2026, 1, 15),
      timeSlot: '09:00 AM',
      status: ExamStatus.scheduled,
      totalStudents: 45,
      presentStudents: 12,
      capacity: 50,
      location: 'Room 101',
      averageScore: 87.1,
    ),
    ExamRoom(
      id: '2',
      title: 'Physics Midterm',
      description: 'Physics Lab 2',
      date: DateTime(2026, 1, 16),
      timeSlot: '02:00 PM',
      status: ExamStatus.inProgress,
      totalStudents: 38,
      presentStudents: 30,
      capacity: 40,
      location: 'Lab 2',
    ),
    ExamRoom(
      id: '3',
      title: 'Chemistry Quiz',
      description: 'Chemistry Building',
      date: DateTime(2026, 1, 20),
      timeSlot: '10:00 AM',
      status: ExamStatus.completed,
      totalStudents: 32,
      presentStudents: 32,
      capacity: 35,
      location: 'CB-203',
      averageScore: 75.5,
    ),
    ExamRoom(
      id: '4',
      title: 'English Literature Exam',
      description: 'Main Hall',
      date: DateTime(2026, 1, 28),
      timeSlot: '11:00 AM',
      status: ExamStatus.scheduled,
      totalStudents: 42,
      presentStudents: 8,
      capacity: 50,
      location: 'Main Hall',
    ),
    ExamRoom(
      id: '5',
      title: 'Biology Lab Test',
      description: 'Biology Lab 1',
      date: DateTime(2026, 1, 15),
      timeSlot: '01:00 PM',
      status: ExamStatus.scheduled,
      totalStudents: 28,
      presentStudents: 0,
      capacity: 30,
      location: 'Bio Lab 1',
    ),
    ExamRoom(
      id: '6',
      title: 'Computer Science Theory',
      description: 'CS Building A',
      date: DateTime(2026, 1, 17),
      timeSlot: '09:00 AM',
      status: ExamStatus.completed,
      totalStudents: 50,
      presentStudents: 48,
      capacity: 60,
      location: 'CS-A101',
      averageScore: 82.3,
    ),
    ExamRoom(
      id: '7',
      title: 'History Midterm',
      description: 'Humanities Block',
      date: DateTime(2026, 1, 18),
      timeSlot: '10:30 AM',
      status: ExamStatus.inProgress,
      totalStudents: 35,
      presentStudents: 33,
      capacity: 40,
      location: 'HB-205',
    ),
    ExamRoom(
      id: '8',
      title: 'Statistics Final',
      description: 'Math Building',
      date: DateTime(2026, 1, 19),
      timeSlot: '02:00 PM',
      status: ExamStatus.scheduled,
      totalStudents: 40,
      presentStudents: 0,
      capacity: 45,
      location: 'MB-302',
    ),
    ExamRoom(
      id: '9',
      title: 'Web Development Quiz',
      description: 'Computer Lab 3',
      date: DateTime(2026, 1, 21),
      timeSlot: '03:00 PM',
      status: ExamStatus.scheduled,
      totalStudents: 30,
      presentStudents: 0,
      capacity: 35,
      location: 'CL-3',
    ),
    ExamRoom(
      id: '10',
      title: 'Database Management',
      description: 'IT Center',
      date: DateTime(2026, 1, 22),
      timeSlot: '09:00 AM',
      status: ExamStatus.completed,
      totalStudents: 45,
      presentStudents: 44,
      capacity: 50,
      location: 'ITC-201',
      averageScore: 79.8,
    ),
    ExamRoom(
      id: '11',
      title: 'Microeconomics Test',
      description: 'Economics Faculty',
      date: DateTime(2026, 1, 23),
      timeSlot: '11:00 AM',
      status: ExamStatus.inProgress,
      totalStudents: 38,
      presentStudents: 35,
      capacity: 40,
      location: 'EF-104',
    ),
    ExamRoom(
      id: '12',
      title: 'Linear Algebra Final',
      description: 'Mathematics Building',
      date: DateTime(2026, 1, 24),
      timeSlot: '01:00 PM',
      status: ExamStatus.scheduled,
      totalStudents: 42,
      presentStudents: 0,
      capacity: 50,
      location: 'MB-101',
    ),
    ExamRoom(
      id: '13',
      title: 'Digital Marketing Quiz',
      description: 'Business School',
      date: DateTime(2026, 1, 25),
      timeSlot: '10:00 AM',
      status: ExamStatus.completed,
      totalStudents: 36,
      presentStudents: 36,
      capacity: 40,
      location: 'BS-303',
      averageScore: 85.2,
    ),
    ExamRoom(
      id: '14',
      title: 'Software Engineering',
      description: 'Engineering Building',
      date: DateTime(2026, 1, 26),
      timeSlot: '02:30 PM',
      status: ExamStatus.scheduled,
      totalStudents: 48,
      presentStudents: 0,
      capacity: 55,
      location: 'EB-401',
    ),
    ExamRoom(
      id: '15',
      title: 'Organic Chemistry Lab',
      description: 'Chemistry Lab 2',
      date: DateTime(2026, 1, 27),
      timeSlot: '09:00 AM',
      status: ExamStatus.inProgress,
      totalStudents: 25,
      presentStudents: 23,
      capacity: 30,
      location: 'CL2-105',
    ),
    ExamRoom(
      id: '16',
      title: 'Python Programming',
      description: 'Computer Science Lab',
      date: DateTime(2026, 1, 29),
      timeSlot: '11:30 AM',
      status: ExamStatus.scheduled,
      totalStudents: 52,
      presentStudents: 0,
      capacity: 60,
      location: 'CSL-202',
    ),
    ExamRoom(
      id: '17',
      title: 'World Literature Exam',
      description: 'Arts Building',
      date: DateTime(2026, 1, 30),
      timeSlot: '01:00 PM',
      status: ExamStatus.completed,
      totalStudents: 33,
      presentStudents: 32,
      capacity: 35,
      location: 'AB-108',
      averageScore: 78.9,
    ),
    ExamRoom(
      id: '18',
      title: 'Data Structures Final',
      description: 'CS Department',
      date: DateTime(2026, 1, 31),
      timeSlot: '03:00 PM',
      status: ExamStatus.scheduled,
      totalStudents: 47,
      presentStudents: 0,
      capacity: 50,
      location: 'CS-301',
    ),
    ExamRoom(
      id: '19',
      title: 'Financial Accounting',
      description: 'Accounting Department',
      date: DateTime(2026, 2, 1),
      timeSlot: '09:30 AM',
      status: ExamStatus.inProgress,
      totalStudents: 41,
      presentStudents: 38,
      capacity: 45,
      location: 'AD-204',
    ),
    ExamRoom(
      id: '20',
      title: 'Machine Learning Quiz',
      description: 'AI Research Lab',
      date: DateTime(2026, 2, 2),
      timeSlot: '02:00 PM',
      status: ExamStatus.completed,
      totalStudents: 28,
      presentStudents: 27,
      capacity: 30,
      location: 'AIL-401',
      averageScore: 88.5,
    ),
  ];

  static final Map<String, List<ExamStudent>> _mockStudents = {
    '1': [
      ExamStudent(
        id: '1',
        name: 'Alice Johnson',
        studentId: '2121001234',
        score: 95,
        attendanceStatus: AttendanceStatus.present,
        checkInTime: DateTime(2026, 1, 15, 8, 55),
      ),
      ExamStudent(
        id: '2',
        name: 'Bob Smith',
        studentId: '2121001235',
        score: 92,
        attendanceStatus: AttendanceStatus.present,
        checkInTime: DateTime(2026, 1, 15, 8, 58),
      ),
      ExamStudent(
        id: '3',
        name: 'Charlie Brown',
        studentId: '2121001236',
        score: null,
        attendanceStatus: AttendanceStatus.absent,
      ),
      ExamStudent(
        id: '4',
        name: 'Diana Prince',
        studentId: '2121001237',
        score: 88,
        attendanceStatus: AttendanceStatus.present,
        checkInTime: DateTime(2026, 1, 15, 9, 2),
      ),
      ExamStudent(
        id: '5',
        name: 'Eve Adams',
        studentId: '2121001238',
        score: 91,
        attendanceStatus: AttendanceStatus.present,
      ),
      ExamStudent(
        id: '6',
        name: 'Frank Miller',
        studentId: '2121001239',
        score: 85,
        attendanceStatus: AttendanceStatus.present,
      ),
      ExamStudent(
        id: '7',
        name: 'Grace Lee',
        studentId: '2121001240',
        score: 94,
        attendanceStatus: AttendanceStatus.present,
      ),
      ExamStudent(
        id: '8',
        name: 'Henry Wilson',
        studentId: '2121001241',
        score: 89,
        attendanceStatus: AttendanceStatus.present,
      ),
      ExamStudent(
        id: '9',
        name: 'Ivy Chen',
        studentId: '2121001242',
        score: 93,
        attendanceStatus: AttendanceStatus.present,
      ),
      ExamStudent(
        id: '10',
        name: 'Jack Davis',
        studentId: '2121001243',
        score: 87,
        attendanceStatus: AttendanceStatus.present,
      ),
    ],
  };
}
