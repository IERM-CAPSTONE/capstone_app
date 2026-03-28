import 'dart:io';
import 'package:dio/dio.dart';
import '../../features/auth/registerf_face/register_state.dart';

class FaceRegistrationService {
  final Dio _dio;

  FaceRegistrationService(this._dio);

  Future<Map<String, dynamic>> registerFace({
    required Map<HeadPose, String> capturedImages,
    required String studentId,
    bool isEncrypted = true,
  }) async {
    try {
      final encryptedImagesMap = <String, String>{};
      for (final entry in capturedImages.entries) {
        encryptedImagesMap[entry.key.name] = entry.value;
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

  Future<Map<String, dynamic>> authenticateFace({
    required String imageBase64,
    String? examSessionId,
    String? examPartCode,
    bool isEncrypted = false,
  }) async {
    try {
      final requestData = {
        'image': imageBase64,
        'examSessionId': examSessionId,
        'examPartCode': examPartCode,
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

  Future<Map<String, dynamic>> proctorCheckIn({
    required String imageBase64,
    required String examSessionId,
    bool isEncrypted = false,
  }) async {
    try {
      final requestData = {
        'image': imageBase64,
        'examSessionId': examSessionId,
        'isEncrypted': isEncrypted,
      };

      final response = await _dio.post(
        '/face-recognition/proctor-check-in',
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

  Future<Map<String, dynamic>> checkRegistrationStatus(String studentId) async {
    try {
      final response = await _dio.get(
        '/face-recognition/check-registration/$studentId',
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
