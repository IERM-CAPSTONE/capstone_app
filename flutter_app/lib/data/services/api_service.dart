import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/user_model.dart';
import '../models/exam_session.dart';
import '../models/exam_room.dart';
import '../models/student_exam.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // User endpoints
  @GET('/users/me')
  Future<UserModel> getCurrentUser();

  @PUT('/users/me')
  Future<UserModel> updateUser(@Body() Map<String, dynamic> userData);

  // Exam Sessions endpoints
  @GET('/exam-sessions')
  Future<PaginatedExamSessionResponse> getExamSessions(
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('subjectCode') String? subjectCode,
    @Query('examRoomId') String? examRoomId,
    @Query('proctorId') String? proctorId,
    @Query('studentId') String? studentId,
    @Query('date') String? date,
  );

  @GET('/exam-sessions/{id}')
  Future<ExamSession> getExamSession(@Path('id') String id);

  // Student Exams endpoints
  @GET('/student-exams')
  Future<PaginatedStudentExamResponse> getStudentExams(
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('examSessionId') String? examSessionId,
    @Query('studentId') String? studentId,
    @Query('status') String? status,
  );

  @GET('/student-exams/{id}')
  Future<StudentExam> getStudentExam(@Path('id') String id);

  // Users
  @GET('/users')
  Future<PaginatedUserResponse> getUsers(
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('role') String? role,
    @Query('search') String? search,
  );

  @GET('/users/proctors')
  Future<PaginatedUserResponse> getProctors(
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('search') String? search,
  );

  // Exam Rooms
  @GET('/exam-rooms')
  Future<PaginatedExamRoomResponse> getExamRooms(
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('roomNumber') String? roomNumber,
  );
}
