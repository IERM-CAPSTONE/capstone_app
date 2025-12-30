import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/user_model.dart';

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
}

