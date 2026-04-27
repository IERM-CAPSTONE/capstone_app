import 'package:camera/camera.dart';

enum FaceScanStatus {
  scanning,
  faceDetected,
  poseValid,
  capturing,
  completed,
  error
}

enum HeadPose { center, left, right, up, down }

class RegisteredStudentInfo {
  final String? id;
  final String? code;
  final String? fullName;
  final bool created;

  const RegisteredStudentInfo({
    this.id,
    this.code,
    this.fullName,
    this.created = false,
  });

  factory RegisteredStudentInfo.fromJson(Map<String, dynamic> json) {
    return RegisteredStudentInfo(
      id: json['id']?.toString(),
      code: json['code']?.toString(),
      fullName: json['fullName']?.toString(),
      created: json['created'] == true,
    );
  }
}

class RegisterFaceState {
  final CameraController? cameraController;
  final FaceScanStatus status;
  final String instructionMessage;
  final String? errorMessage;
  final HeadPose currentPose;
  final List<HeadPose> capturedPoses;
  final Map<HeadPose, String> capturedImages;
  final bool isWearingGlasses;
  final String? targetStudentCode;
  final String? otp;
  final String? retentionPolicy;
  final String? pendingEnrollmentId;
  final RegisteredStudentInfo? registeredStudent;

  const RegisterFaceState({
    this.cameraController,
    this.status = FaceScanStatus.scanning,
    this.instructionMessage = 'Vui lòng đưa mặt vào khung hình',
    this.errorMessage,
    this.currentPose = HeadPose.center,
    this.capturedPoses = const [],
    this.capturedImages = const {},
    this.isWearingGlasses = false,
    this.targetStudentCode,
    this.otp,
    this.retentionPolicy,
    this.pendingEnrollmentId,
    this.registeredStudent,
  });

  RegisterFaceState copyWith({
    Object? cameraController = _unset,
    FaceScanStatus? status,
    String? instructionMessage,
    Object? errorMessage = _unset,
    HeadPose? currentPose,
    List<HeadPose>? capturedPoses,
    Map<HeadPose, String>? capturedImages,
    bool? isWearingGlasses,
    Object? targetStudentCode = _unset,
    Object? otp = _unset,
    Object? retentionPolicy = _unset,
    Object? pendingEnrollmentId = _unset,
    Object? registeredStudent = _unset,
  }) {
    return RegisterFaceState(
      cameraController: identical(cameraController, _unset)
          ? this.cameraController
          : cameraController as CameraController?,
      status: status ?? this.status,
      instructionMessage: instructionMessage ?? this.instructionMessage,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      currentPose: currentPose ?? this.currentPose,
      capturedPoses: capturedPoses ?? this.capturedPoses,
      capturedImages: capturedImages ?? this.capturedImages,
      isWearingGlasses: isWearingGlasses ?? this.isWearingGlasses,
      targetStudentCode: identical(targetStudentCode, _unset)
          ? this.targetStudentCode
          : targetStudentCode as String?,
      otp: identical(otp, _unset) ? this.otp : otp as String?,
      retentionPolicy: identical(retentionPolicy, _unset)
          ? this.retentionPolicy
          : retentionPolicy as String?,
      pendingEnrollmentId: identical(pendingEnrollmentId, _unset)
          ? this.pendingEnrollmentId
          : pendingEnrollmentId as String?,
      registeredStudent: identical(registeredStudent, _unset)
          ? this.registeredStudent
          : registeredStudent as RegisteredStudentInfo?,
    );
  }

  static String getPoseInstruction(HeadPose pose) {
    switch (pose) {
      case HeadPose.center:
        return 'Nhìn thẳng vào camera';
      case HeadPose.left:
        return 'Quay đầu sang trái';
      case HeadPose.right:
        return 'Quay đầu sang phải';
      case HeadPose.up:
        return 'Ngước đầu lên trên';
      case HeadPose.down:
        return 'Cúi đầu xuống dưới';
    }
  }
}

const Object _unset = Object();
