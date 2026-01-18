import '../models/exam_session.dart';
import '../models/student_exam.dart';
import '../services/api_service.dart';

/// Repository for exam sessions data using real API
class ExamSessionRepository {
  final ApiService _apiService;

  ExamSessionRepository(this._apiService);

  /// Get all exam sessions with optional filters
  Future<Map<String, dynamic>> getExamSessions({
    String? search,
    String? status,
    DateTime? date,
    String? timeSlot,
    int page = 1,
    int itemsPerPage = 10,
  }) async {
    try {
      final response = await _apiService.getExamSessions(
        page,
        itemsPerPage,
        search, // Using search as subjectCode filter
        null, // examRoomId
        null, // proctorId
      );

      // Apply additional client-side filters if needed
      var sessions = response.data;

      // Filter by status if provided
      if (status != null && status.isNotEmpty) {
        sessions = sessions.where((session) {
          final sessionStatus = session.statusLabel.toLowerCase();
          final filterStatus = status.toLowerCase();
          return sessionStatus.contains(filterStatus);
        }).toList();
      }

      // Filter by date if provided
      if (date != null) {
        sessions = sessions.where((session) {
          if (session.date == null) return false;
          return session.date!.year == date.year &&
              session.date!.month == date.month &&
              session.date!.day == date.day;
        }).toList();
      }

      // Filter by time slot if provided
      if (timeSlot != null && timeSlot.isNotEmpty) {
        sessions = sessions.where((session) {
          return session.timeSlot == timeSlot;
        }).toList();
      }

      // For each session, get student count
      final sessionsWithCounts = await Future.wait(
        sessions.map((session) async {
          final studentCount = await _getStudentCount(session.id);
          return {
            'session': session,
            'totalStudents': studentCount['total'] ?? 0,
            'presentStudents': studentCount['present'] ?? 0,
          };
        }),
      );

      return {
        'items': sessionsWithCounts,
        'totalItems': response.total,
        'currentPage': response.page,
        'itemsPerPage': response.limit,
      };
    } catch (e) {
      throw Exception('Failed to load exam sessions: $e');
    }
  }

  /// Get exam session by ID
  Future<Map<String, dynamic>?> getExamSessionById(String id) async {
    try {
      final session = await _apiService.getExamSession(id);
      final studentCount = await _getStudentCount(id);

      return {
        'session': session,
        'totalStudents': studentCount['total'] ?? 0,
        'presentStudents': studentCount['present'] ?? 0,
      };
    } catch (e) {
      return null;
    }
  }

  /// Get students in an exam session
  Future<List<StudentExam>> getExamStudents(String examSessionId) async {
    try {
      final response = await _apiService.getStudentExams(
        1, // page
        100, // limit - get all students for this session
        examSessionId,
        null, // studentId
        null, // status
      );
      return response.data;
    } catch (e) {
      return [];
    }
  }

  /// Helper method to get student count for a session
  Future<Map<String, int>> _getStudentCount(String examSessionId) async {
    try {
      final response = await _apiService.getStudentExams(
        1, // page
        1000, // high limit to get count
        examSessionId,
        null, // studentId
        null, // status
      );

      final total = response.total;
      final present = response.data
          .where((student) =>
              student.status == StudentExamStatus.checkedIn ||
              student.status == StudentExamStatus.checkedOut)
          .length;

      return {
        'total': total,
        'present': present,
      };
    } catch (e) {
      return {
        'total': 0,
        'present': 0,
      };
    }
  }
}
