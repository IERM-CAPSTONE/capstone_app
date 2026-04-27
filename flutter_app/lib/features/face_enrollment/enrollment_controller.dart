import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../config/dependency_injection.dart';
import '../../data/services/face_enrollment_service.dart';
import 'enrollment_state.dart';

export 'enrollment_state.dart';

part 'enrollment_controller.g.dart';

@riverpod
class EnrollmentController extends _$EnrollmentController {
  late final FaceEnrollmentService _service;

  @override
  EnrollmentState build() {
    _service = DependencyInjection.get<FaceEnrollmentService>();
    return const EnrollmentState();
  }

  Future<void> issueOtp(String studentCode, {String? studentName}) async {
    state = state.copyWith(status: EnrollmentStatus.loading);
    try {
      final response = await _service.issueOtp(studentCode);
      if (response.success) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        state = state.copyWith(
          status: EnrollmentStatus.otpIssued,
          otp: data['otp']?.toString(),
          studentCode: data['studentCode']?.toString() ?? studentCode,
          expiresAt: data['expiresAt']?.toString(),
          studentName: studentName,
          errorMessage: null,
        );
        // Reset to initial after a short delay so the loading state in UI clears
        // and doesn't block subsequent OTP requests if needed
        Future.delayed(const Duration(milliseconds: 500), () {
          if (state.status == EnrollmentStatus.otpIssued) {
            state = state.copyWith(status: EnrollmentStatus.initial);
          }
        });
      } else {
        state = state.copyWith(
          status: EnrollmentStatus.error,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: EnrollmentStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(status: EnrollmentStatus.verifyingOtp);
    try {
      final response = await _service.verifyOtp(otp);
      if (response.success) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        state = state.copyWith(
          status: EnrollmentStatus.otpVerified,
          studentCode: data['studentCode']?.toString(),
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: EnrollmentStatus.error,
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: EnrollmentStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void startWaiting({required String enrollmentId}) {
    state = state.copyWith(
      status: EnrollmentStatus.waitingForApproval,
      enrollmentId: enrollmentId,
      errorMessage: null,
    );
  }

  void markApproved() {
    state = state.copyWith(status: EnrollmentStatus.approved);
  }

  void markRejected(String? reason) {
    state = state.copyWith(
      status: EnrollmentStatus.rejected,
      errorMessage: reason,
    );
  }
}
