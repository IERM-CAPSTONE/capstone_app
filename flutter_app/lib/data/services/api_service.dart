import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/user_model.dart';
import '../models/exam_session.dart';
import '../models/exam_room.dart';
import '../models/student_exam.dart';
import '../models/ticket_model.dart';
import '../models/api_response.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // Auth endpoints
  @POST('/auth/login')
  Future<ApiResponse> login(@Body() Map<String, dynamic> credentials);

  @POST('/auth/register')
  Future<ApiResponse> register(@Body() Map<String, dynamic> userData);

  @POST('/auth/logout')
  Future<void> logout();

  // User endpoints
  @GET('/users/me')
  Future<UserModel> getCurrentUser();

  @PUT('/users/me')
  Future<ApiResponse> updateUser(@Body() Map<String, dynamic> userData);

  // Attendance endpoints
  @POST('/attendance/check-in')
  Future<ApiResponse> checkIn(@Body() Map<String, dynamic> data);

  @GET('/attendance/history')
  Future<ApiResponse> getAttendanceHistory();

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
    @Query('hallInvigilatorId') String? hallInvigilatorId,
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

  // Tickets
  @POST('/tickets')
  Future<ApiResponse> createTicket(
    @Body() Map<String, dynamic> payload,
  );

  @GET('/tickets')
  Future<TicketListResponse> getMyTickets();

  @GET('/tickets/{id}')
  Future<TicketModel> getTicketById(@Path('id') String id);

  @PATCH('/tickets/{id}/process')
  Future<ApiResponse> processTicket(
    @Path('id') String id,
    @Body() Map<String, dynamic> payload,
  );

  @POST('/tickets/{id}/comments')
  Future<ApiResponse> commentTicket(
    @Path('id') String id,
    @Body() Map<String, dynamic> payload,
  );

  // Device Applications
  @POST('/device-applications/register')
  Future<ApiResponse> registerDeviceApplication(
    @Body() Map<String, dynamic> payload,
  );

  @GET('/device-applications/me')
  Future<ApiResponse> getMyDeviceApplications();

  @DELETE('/device-applications/{id}')
  Future<void> deleteDeviceApplication(@Path('id') String id);

  // Devices
  @GET('/devices/me')
  Future<ApiResponse> getMyDevices();

  // Notifications
  @GET('/notifications')
  Future<ApiResponse> getNotifications();

  @PATCH('/notifications/{id}/read')
  Future<ApiResponse> markNotificationRead(@Path('id') String id);
}
