import 'package:camera/camera.dart';

enum FaceAuthenticateStatus {
  scanning,
  faceDetected,
  livenessCheck,
  authenticating,
  authenticated,
  failed,
  error
}

class FaceAuthenticateState {
  final CameraController? cameraController;
  final FaceAuthenticateStatus status;
  final String instructionMessage;
  final String? errorMessage;
  final double? confidence;
  final String? studentId;
  final String? studentCode;
  final String? studentName;

  const FaceAuthenticateState({
    this.cameraController,
    this.status = FaceAuthenticateStatus.scanning,
    this.instructionMessage = 'Vui lòng đưa mặt vào khung hình',
    this.errorMessage,
    this.confidence,
    this.studentId,
    this.studentCode,
    this.studentName,
  });

  FaceAuthenticateState copyWith({
    CameraController? cameraController,
    FaceAuthenticateStatus? status,
    String? instructionMessage,
    String? errorMessage,
    double? confidence,
    String? studentId,
    String? studentCode,
    String? studentName,
  }) {
    return FaceAuthenticateState(
      cameraController: cameraController ?? this.cameraController,
      status: status ?? this.status,
      instructionMessage: instructionMessage ?? this.instructionMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      confidence: confidence ?? this.confidence,
      studentId: studentId ?? this.studentId,
      studentCode: studentCode ?? this.studentCode,
      studentName: studentName ?? this.studentName,
    );
  }
}
