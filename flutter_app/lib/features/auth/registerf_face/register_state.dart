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

class RegisterFaceState {
  final CameraController? cameraController;
  final FaceScanStatus status;
  final String instructionMessage;
  final String? errorMessage;
  final HeadPose currentPose;
  final List<HeadPose> capturedPoses;
  final Map<HeadPose, String> capturedImages;
  final bool isWearingGlasses;

  const RegisterFaceState({
    this.cameraController,
    this.status = FaceScanStatus.scanning,
    this.instructionMessage = 'Vui l\u00f2ng \u0111\u01b0a m\u1eb7t v\u00e0o khung h\u00ecnh',
    this.errorMessage,
    this.currentPose = HeadPose.center,
    this.capturedPoses = const [],
    this.capturedImages = const {},
    this.isWearingGlasses = false,
  });

  RegisterFaceState copyWith({
    CameraController? cameraController,
    FaceScanStatus? status,
    String? instructionMessage,
    String? errorMessage,
    HeadPose? currentPose,
    List<HeadPose>? capturedPoses,
    Map<HeadPose, String>? capturedImages,
    bool? isWearingGlasses,
  }) {
    return RegisterFaceState(
      cameraController: cameraController ?? this.cameraController,
      status: status ?? this.status,
      instructionMessage: instructionMessage ?? this.instructionMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPose: currentPose ?? this.currentPose,
      capturedPoses: capturedPoses ?? this.capturedPoses,
      capturedImages: capturedImages ?? this.capturedImages,
      isWearingGlasses: isWearingGlasses ?? this.isWearingGlasses,
    );
  }

  static String getPoseInstruction(HeadPose pose) {
    switch (pose) {
      case HeadPose.center:
        return 'Nh\u00ecn th\u1eb3ng v\u00e0o camera';
      case HeadPose.left:
        return 'Quay \u0111\u1ea7u sang tr\u00e1i';
      case HeadPose.right:
        return 'Quay \u0111\u1ea7u sang ph\u1ea3i';
      case HeadPose.up:
        return 'Ng\u01b0\u1edbc \u0111\u1ea7u l\u00ean tr\u00ean';
      case HeadPose.down:
        return 'C\u00fai \u0111\u1ea7u xu\u1ed1ng d\u01b0\u1edbi';
    }
  }
}
