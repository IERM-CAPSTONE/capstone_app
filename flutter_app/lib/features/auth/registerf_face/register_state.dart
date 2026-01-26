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
    this.instructionMessage = 'Vui lòng đưa mặt vào khung hình',
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
