enum EnrollmentStatus {
  initial,
  loading,
  verifyingOtp,
  otpIssued,
  otpVerified,
  waitingForApproval,
  approved,
  rejected,
  error,
}

class EnrollmentState {
  final EnrollmentStatus status;
  final String? otp;
  final String? studentCode;
  final String? enrollmentId;
  final String? errorMessage;
  final String? expiresAt;
  final String? studentName;

  const EnrollmentState({
    this.status = EnrollmentStatus.initial,
    this.otp,
    this.studentCode,
    this.enrollmentId,
    this.errorMessage,
    this.expiresAt,
    this.studentName,
  });

  EnrollmentState copyWith({
    EnrollmentStatus? status,
    Object? otp = _unset,
    Object? studentCode = _unset,
    Object? enrollmentId = _unset,
    Object? errorMessage = _unset,
    Object? expiresAt = _unset,
    Object? studentName = _unset,
  }) {
    return EnrollmentState(
      status: status ?? this.status,
      otp: identical(otp, _unset) ? this.otp : otp as String?,
      studentCode: identical(studentCode, _unset)
          ? this.studentCode
          : studentCode as String?,
      enrollmentId: identical(enrollmentId, _unset)
          ? this.enrollmentId
          : enrollmentId as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      expiresAt:
          identical(expiresAt, _unset) ? this.expiresAt : expiresAt as String?,
      studentName: identical(studentName, _unset)
          ? this.studentName
          : studentName as String?,
    );
  }
}

const Object _unset = Object();
