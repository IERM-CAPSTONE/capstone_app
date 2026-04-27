import 'package:dio/dio.dart';

import '../models/api_response.dart';

class FaceEnrollmentService {
  final Dio _dio;

  FaceEnrollmentService(this._dio);

  Future<ApiResponse> issueOtp(String studentCode) async {
    return _post('/face-recognition/enrollment/otp', {
      'studentCode': studentCode,
    });
  }

  Future<ApiResponse> verifyOtp(String otp) async {
    return _post('/face-recognition/enrollment/verify-otp', {'otp': otp});
  }

  Future<ApiResponse> approve(String enrollmentId, [String? note]) async {
    return _post('/face-recognition/enrollment/approve', {
      'enrollmentId': enrollmentId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  Future<ApiResponse> reject(String enrollmentId, [String? reason]) async {
    return _post('/face-recognition/enrollment/reject', {
      'enrollmentId': enrollmentId,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  Future<List<Map<String, dynamic>>> listPending() async {
    final response = await _dio.get('/face-recognition/enrollment/pending');
    return _extractList(response.data)
        .whereType<Map>()
        .map((item) => _normalizePending(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>?> findStudentByCode(String studentCode) async {
    final normalizedCode = studentCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) return null;

    final response = await _dio.get(
      '/users',
      queryParameters: {
        'role': 'STUDENT',
        'search': normalizedCode,
        'limit': 10,
      },
    );

    final list = _extractList(response.data);

    for (final item in list.whereType<Map>()) {
      final student = Map<String, dynamic>.from(item);
      if (student['code']?.toString().toUpperCase() == normalizedCode) {
        return student;
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> findStudentExamByCode(
      String studentCode) async {
    final normalizedCode = studentCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) return null;

    final response = await _dio.get(
      '/student-exams',
      queryParameters: {
        'studentCode': normalizedCode,
        'limit': 1,
      },
    );

    for (final item in _extractList(response.data).whereType<Map>()) {
      final studentExam = Map<String, dynamic>.from(item);
      if (studentExam['studentCode']?.toString().toUpperCase() ==
          normalizedCode) {
        return studentExam;
      }
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> listStudentExamsBySession(
      String examSessionId) async {
    final normalizedSessionId = examSessionId.trim();
    if (normalizedSessionId.isEmpty) return const [];

    final response = await _dio.get(
      '/student-exams',
      queryParameters: {
        'examSessionId': normalizedSessionId,
        'page': 1,
        'limit': 1000,
      },
    );

    return _extractList(response.data)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _normalizePending(Map<String, dynamic> item) {
    final capturedImages = _normalizeCapturedImages(item['capturedImageUrls']);
    final faceImageUrl = _firstNonEmpty([
      item['faceImageUrl'],
      capturedImages['center'],
      ...capturedImages.values,
    ]);

    return {
      ...item,
      'enrollmentId': _firstNonEmpty([item['enrollmentId'], item['id']]) ?? '',
      'studentCode': _firstNonEmpty([item['studentCode'], item['code']]) ?? '',
      'studentName': _firstNonEmpty([item['studentName'], item['fullName'], item['name']]) ?? 'Sinh viên',
      'avatarUrl': _firstNonEmpty([item['avatarUrl']]) ?? '',
      'faceImageUrl': faceImageUrl ?? '',
      'capturedImageUrls': capturedImages,
    };
  }

  Map<String, String> _normalizeCapturedImages(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, imageUrl) => MapEntry(key.toString(), imageUrl?.toString() ?? ''),
      )..removeWhere((_, imageUrl) => imageUrl.trim().isEmpty);
    }
    if (value is List) {
      return {
        for (var i = 0; i < value.length; i++)
          if (value[i]?.toString().trim().isNotEmpty == true)
            i.toString(): value[i].toString(),
      };
    }
    return const {};
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  List _extractList(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data['data'] as List;
    }
    if (data is List) return data;
    return const [];
  }

  Future<ApiResponse> _post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(path, data: data);
      return _toApiResponse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      return ApiResponse(
        data: data,
        success: false,
        statusCode: e.response?.statusCode ?? 500,
        message: data is Map ? data['message']?.toString() : e.message,
      );
    }
  }

  ApiResponse _toApiResponse(dynamic data) {
    if (data is Map<String, dynamic> &&
        data.containsKey('success') &&
        data.containsKey('data')) {
      return ApiResponse.fromJson(data);
    }

    return ApiResponse(
      data: data,
      success: true,
      statusCode: 200,
      message: data is Map ? data['message']?.toString() : null,
    );
  }
}
