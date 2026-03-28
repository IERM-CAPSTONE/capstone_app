import 'package:camera/camera.dart';

enum ProctorFaceCheckInStatus {
  scanning,
  livenessCheck,
  faceDetected,
  checkingIn,
  success,
  failed,
  error,
}

class ProctorFaceCheckInState {
  final CameraController? cameraController;
  final ProctorFaceCheckInStatus status;
  final String instructionMessage;
  final String? errorMessage;
  final int stableCount;
  final int requiredStableFrames;
  final double? confidence;

  const ProctorFaceCheckInState({
    this.cameraController,
    this.status = ProctorFaceCheckInStatus.scanning,
    this.instructionMessage = '',
    this.errorMessage,
    this.stableCount = 0,
    this.requiredStableFrames = 3,
    this.confidence,
  });

  ProctorFaceCheckInState copyWith({
    CameraController? cameraController,
    ProctorFaceCheckInStatus? status,
    String? instructionMessage,
    String? errorMessage,
    int? stableCount,
    int? requiredStableFrames,
    double? confidence,
    bool clearError = false,
  }) {
    return ProctorFaceCheckInState(
      cameraController: cameraController ?? this.cameraController,
      status: status ?? this.status,
      instructionMessage: instructionMessage ?? this.instructionMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      stableCount: stableCount ?? this.stableCount,
      requiredStableFrames: requiredStableFrames ?? this.requiredStableFrames,
      confidence: confidence ?? this.confidence,
    );
  }
}
