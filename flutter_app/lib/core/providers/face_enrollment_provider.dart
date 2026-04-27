import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/face_enrollment_service.dart';

final faceEnrollmentServiceProvider = Provider<FaceEnrollmentService>((ref) {
  return DependencyInjection.get<FaceEnrollmentService>();
});
