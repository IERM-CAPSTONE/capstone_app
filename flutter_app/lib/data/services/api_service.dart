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

  // Auth endpoints
  @POST('/auth/login')
  Future<Map<String, dynamic>> login(@Body() Map<String, dynamic> credentials);

  @POST('/auth/register')
  Future<Map<String, dynamic>> register(@Body() Map<String, dynamic> userData);

  @POST('/auth/logout')
  Future<void> logout();

  // User endpoints
  @GET('/users/me')
  Future<UserModel> getCurrentUser();

  @PUT('/users/me')
  Future<UserModel> updateUser(@Body() Map<String, dynamic> userData);

  // Attendance endpoints
  @POST('/attendance/check-in')
  Future<Map<String, dynamic>> checkIn(@Body() Map<String, dynamic> data);

  @GET('/attendance/history')
  Future<List<Map<String, dynamic>>> getAttendanceHistory();

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
    @Query('fromDate') String? fromDate,
    @Query('toDate') String? toDate,
    @Query('examType') String? examType,
    @Query('campus') String? campus,
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

  // Device Applications
  @POST('/device-applications/register')
  Future<Map<String, dynamic>> registerDeviceApplication(
    @Body() Map<String, dynamic> payload,
  );

  @GET('/device-applications/me')
  Future<List<Map<String, dynamic>>> getMyDeviceApplications();

  @DELETE('/device-applications/{id}')
  Future<void> deleteDeviceApplication(@Path('id') String id);

  // Devices
  @GET('/devices/me')
  Future<List<Map<String, dynamic>>> getMyDevices();
}
