import '../models/exam_session.dart';
import '../models/attendance_snapshot.dart';
import '../models/student_exam.dart';
import '../models/subject_part_option.dart';
import '../models/user_model.dart';
import '../models/exam_room.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// Repository for exam sessions data using real API
class ExamSessionRepository {
  final ApiService _apiService;
  final Dio _dio;

  ExamSessionRepository(this._apiService, this._dio);

  /// Get all exam sessions with optional filters
  Future<Map<String, dynamic>> getExamSessions({
    String? search,
    String? status,
    DateTime? date,
    DateTime? fromDate,
    DateTime? toDate,
    String? timeSlot,
    String? proctorId,
    String? hallInvigilatorId,
    String? studentId,
    String? subjectCode,
    String? examRoomId,
    String? examType,
    String? campus,
    int page = 1,
    int itemsPerPage = 10,
  }) async {
    try {
      final dateStr =
          date != null ? DateFormat('yyyy-MM-dd').format(date) : null;
      final fromDateStr =
          fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate) : null;
      final toDateStr =
          toDate != null ? DateFormat('yyyy-MM-dd').format(toDate) : null;

      final response = await _apiService.getExamSessions(
        page,
        itemsPerPage,
        subjectCode ?? search, // Using subjectCode or search
        examRoomId, // examRoomId
        proctorId, // proctorId
        studentId, // studentId
        dateStr, // PASS DATE TO BACKEND
        fromDateStr,
        toDateStr,
        examType,
        campus,
        hallInvigilatorId,
      );

      // Apply additional client-side filters if needed
      var sessions = response.data;

      // Filter by proctor/hall invigilator if provided (Client-side fallback)
      if (proctorId != null && proctorId.isNotEmpty) {
        sessions = sessions.where((session) {
          return session.proctorId == proctorId ||
              session.hallInvigilatorId == proctorId;
        }).toList();
      }
      
      if (hallInvigilatorId != null && hallInvigilatorId.isNotEmpty) {
        sessions = sessions.where((session) {
          return session.hallInvigilatorId == hallInvigilatorId;
        }).toList();
      }
 
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
        'totalItems': sessions.length, // Reflect filtered results
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

  Future<AttendanceSnapshot?> getLatestStudentAttendanceSnapshot({
    required String examSessionId,
    required String studentId,
    String? examPartCode,
  }) async {
    try {
      final response = await _dio.get(
        '/face-recognition/attendance-snapshots',
        queryParameters: {
          'page': 1,
          'limit': 10,
          'examSessionId': examSessionId,
          'actorType': 'STUDENT',
          'matchedUserId': studentId,
        },
      );

      final payload = response.data;
      final data = payload is Map<String, dynamic> ? payload['data'] : null;
      final rawItems = data is List
          ? data
          : data is Map<String, dynamic>
              ? data['data']
              : const [];
      final snapshots = (rawItems as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AttendanceSnapshot.fromJson)
          .toList();

      if (snapshots.isEmpty) return null;

      final normalizedPart = examPartCode?.trim().toUpperCase();
      if (normalizedPart != null && normalizedPart.isNotEmpty) {
        for (final snapshot in snapshots) {
          if ((snapshot.examPartCode ?? '').trim().toUpperCase() ==
              normalizedPart) {
            return snapshot;
          }
        }
      }

      return snapshots.first;
    } catch (e) {
      return null;
    }
  }

  Future<List<SubjectPartOption>> getSubjectParts(String subjectCode) async {
    final normalizedCode = subjectCode.trim();
    if (normalizedCode.isEmpty) return [];

    try {
      final response = await _dio.get(
        '/subjects',
        queryParameters: {
          'page': 1,
          'limit': 100,
          'search': normalizedCode,
        },
      );

      final payload = response.data;
      final items = payload is Map<String, dynamic>
          ? (payload['data'] as List<dynamic>? ?? const [])
          : const <dynamic>[];

      for (final item in items.whereType<Map<String, dynamic>>()) {
        final code = item['code']?.toString().trim().toUpperCase();
        if (code == normalizedCode.toUpperCase()) {
          final parts = item['parts'] as List<dynamic>? ?? const [];
          return parts
              .whereType<Map<String, dynamic>>()
              .map(SubjectPartOption.fromJson)
              .where((part) => part.code.isNotEmpty)
              .toList();
        }
      }

      return [];
    } catch (_) {
      return [];
    }
  }
}
