import '../models/exam_session.dart';
import '../models/student_exam.dart';
import '../models/user_model.dart';
import '../models/exam_room.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

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
    String? proctorId,
    String? studentId,
    String? subjectCode,
    String? examRoomId,
    int page = 1,
    int itemsPerPage = 10,
  }) async {
    try {
      final dateStr =
          date != null ? DateFormat('yyyy-MM-dd').format(date) : null;

      final response = await _apiService.getExamSessions(
        page,
        itemsPerPage,
        subjectCode ?? search, // Using subjectCode or search
        examRoomId, // examRoomId
        proctorId, // proctorId
        studentId, // studentId
        dateStr, // PASS DATE TO BACKEND
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

      // Filter by time slot if provided
      if (timeSlot != null && timeSlot.isNotEmpty) {
        sessions = sessions.where((session) {
          return session.timeSlot == timeSlot;
        }).toList();
      }

      /*
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
      */

      final sessionsWithCounts = sessions
          .map((session) => {
                'session': session,
                'totalStudents':
                    0, // Should be returned by backend for efficiency
                'presentStudents': 0,
              })
          .toList();

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

  /// Get list of proctors
  Future<List<UserModel>> getProctors() async {
    try {
      final response = await _apiService.getProctors(1, 100, null);
      return response.data;
    } catch (e) {
      return [];
    }
  }

  /// Get list of exam rooms
  Future<List<ExamRoom>> getRooms() async {
    try {
      final response = await _apiService.getExamRooms(1, 100, null);
      return response.data;
    } catch (e) {
      return [];
    }
  }

  /// Get exam session by ID
  Future<Map<String, dynamic>?> getExamSessionById(String id) async {
    try {
      // Call API and let it deserialize
      final session = await _apiService.getExamSession(id);

      return {
        'session': session,
        'totalStudents': 0, // Will be calculated from student list
        'presentStudents': 0,
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
        1000, // limit - Increase from 100 to 1000 to ensure all students are fetched
        examSessionId,
        null, // studentId
        null, // status
      );
      return response.data;
    } catch (e) {
      return [];
    }
  }
}
