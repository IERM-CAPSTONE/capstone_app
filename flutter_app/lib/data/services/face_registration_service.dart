import 'dart:io';
import 'package:dio/dio.dart';
import '../../config/env.dart';
import '../../features/auth/registerf_face/register_state.dart';

class FaceRegistrationService {
  final Dio _dio;

  FaceRegistrationService()
      : _dio = Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  /// Đăng ký khuôn mặt mới với mã hóa AES
  /// Gửi dữ liệu đã mã hóa dưới dạng JSON
  Future<Map<String, dynamic>> registerFace({
    required Map<HeadPose, String> capturedImages,
    required String studentId,
    bool isEncrypted = true,
  }) async {
    try {
      // Prepare encrypted images map (key: pose name, value: encrypted base64)
      final encryptedImagesMap = <String, String>{};
      for (var entry in capturedImages.entries) {
        final poseName = entry.key.name; // center, left, right, up, down
        encryptedImagesMap[poseName] = entry.value; // Already encrypted by controller
      }

      final requestData = {
        'studentId': studentId,
        'encryptedImages': encryptedImagesMap,
        'isEncrypted': isEncrypted,
      };

      final response = await _dio.post(
        '/face-recognition/register',
        data: requestData,
        options: Options(contentType: 'application/json'),
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ?? 'Lỗi kết nối Server',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Xác thực khuôn mặt với mã hóa AES
  Future<Map<String, dynamic>> authenticateFace({
    required String encryptedImage,
    bool isEncrypted = true,
  }) async {
    try {
      final requestData = {
        'encryptedImage': encryptedImage,
        'isEncrypted': isEncrypted,
      };

      final response = await _dio.post(
        '/face-recognition/authenticate',
        data: requestData,
        options: Options(contentType: 'application/json'),
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ?? 'Lỗi kết nối Server',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Legacy: Nhận diện điểm danh (Gửi 1 file Binary - Tốc độ cao)
  /// Giữ lại để tương thích với code cũ
  Future<Map<String, dynamic>> identifyFace({
    required String imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image':
            await MultipartFile.fromFile(imagePath, filename: 'identify.jpg'),
      });

      final response = await _dio.post(
        '/api/student-exams/identify',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ?? 'Lỗi kết nối Server',
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
