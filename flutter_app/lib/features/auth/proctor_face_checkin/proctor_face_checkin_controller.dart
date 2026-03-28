import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../../../config/dependency_injection.dart';
import '../../../data/services/face_registration_service.dart';
import 'proctor_face_checkin_state.dart';

final proctorFaceCheckInControllerProvider = StateNotifierProvider.autoDispose
    .family<ProctorFaceCheckInController, ProctorFaceCheckInState, String>(
  (ref, examSessionId) => ProctorFaceCheckInController(examSessionId),
);

class ProctorFaceCheckInController
    extends StateNotifier<ProctorFaceCheckInState> {
  ProctorFaceCheckInController(this.examSessionId)
      : super(const ProctorFaceCheckInState());

  final String examSessionId;
  FaceDetector? _faceDetector;
  Timer? _detectionTimer;
  Timer? _timeoutTimer;
  CameraImage? _lastImage;
  bool _isProcessing = false;
  bool _isCapturing = false;
  int _frameCounter = 0;
  int _stableCount = 0;
  bool _blinkDetected = false;
  int _blinkCount = 0;
  int _eyesClosedFrames = 0;
  int _eyesReopenedFrames = 0;
  bool _blinkClosingPhase = false;

  static const Duration _detectionInterval = Duration(milliseconds: 250);
  static const int _requiredStableFrames = 3;
  static const int _requiredBlinks = 1;
  static const int _requiredClosedFrames = 1;
  static const int _requiredReopenedFrames = 1;
  static const double _centerThreshold = 10.0;

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _detectionTimer?.cancel();
    _faceDetector?.close();
    state.cameraController?.dispose();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Không tìm thấy camera');
      }

      var selectedCamera = cameras.first;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();

      state = state.copyWith(
        cameraController: controller,
        status: ProctorFaceCheckInStatus.scanning,
        instructionMessage: 'Đưa khuôn mặt vào khung hình',
        requiredStableFrames: _requiredStableFrames,
      );

      controller.startImageStream((image) {
        _lastImage = image;
      });

      _resetBlinkDetection();

      _detectionTimer = Timer.periodic(_detectionInterval, (_) {
        _processLatestImage();
      });

      _startTimeout();
    } catch (e) {
      state = state.copyWith(
        status: ProctorFaceCheckInStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _processLatestImage() {
    if (_isProcessing || _isCapturing || _lastImage == null) return;
    _frameCounter++;
    if (_frameCounter % 2 != 0) return;

    _isProcessing = true;
    _detectFace(_lastImage!);
  }

  Future<void> _detectFace(CameraImage image) async {
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector?.processImage(inputImage);
      if (faces == null || faces.isEmpty) {
        _stableCount = 0;
        _resetBlinkDetection();
        state = state.copyWith(
          status: ProctorFaceCheckInStatus.scanning,
          instructionMessage: 'Đưa khuôn mặt vào khung hình',
          stableCount: 0,
        );
        return;
      }

      final face = faces.first;
      final headY = face.headEulerAngleY ?? 0;
      final headX = face.headEulerAngleX ?? 0;
      _detectBlink(face);

      final isCenter =
          headY.abs() < _centerThreshold && headX.abs() < _centerThreshold;

      if (!isCenter) {
        _stableCount = 0;
        state = state.copyWith(
          status: ProctorFaceCheckInStatus.faceDetected,
          instructionMessage: 'Giữ mặt thẳng và nhìn vào camera',
          stableCount: 0,
        );
        return;
      }

      if (!_blinkDetected) {
        state = state.copyWith(
          status: ProctorFaceCheckInStatus.livenessCheck,
          instructionMessage: 'Nháy mắt $_blinkCount/$_requiredBlinks lần',
        );
        return;
      }

      _stableCount++;
      state = state.copyWith(
        status: ProctorFaceCheckInStatus.faceDetected,
        stableCount: _stableCount,
        requiredStableFrames: _requiredStableFrames,
        instructionMessage: 'Nháy mắt thành công. Giữ yên $_stableCount/$_requiredStableFrames',
      );

      if (_stableCount >= _requiredStableFrames) {
        await _checkIn();
      }
    } catch (e) {
      debugPrint('Proctor face detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _detectBlink(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;

    const eyeClosedThreshold = 0.4;
    const eyeOpenThreshold = 0.65;

    if (avgEyeOpen <= eyeClosedThreshold) {
      _eyesClosedFrames++;
      _eyesReopenedFrames = 0;
      if (_eyesClosedFrames >= _requiredClosedFrames) {
        _blinkClosingPhase = true;
      }
      return;
    }

    if (avgEyeOpen >= eyeOpenThreshold) {
      if (_blinkClosingPhase) {
        _eyesReopenedFrames++;
        if (_eyesReopenedFrames >= _requiredReopenedFrames) {
          _blinkCount++;
          _blinkDetected = _blinkCount >= _requiredBlinks;
          _blinkClosingPhase = false;
          _eyesClosedFrames = 0;
          _eyesReopenedFrames = 0;
          debugPrint('Proctor blink detected. Count: $_blinkCount');
        }
      } else {
        _eyesClosedFrames = 0;
        _eyesReopenedFrames = 0;
      }
      return;
    }

    _eyesReopenedFrames = 0;
  }

  Future<void> _checkIn() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      _detectionTimer?.cancel();
      _timeoutTimer?.cancel();

      final photo = await state.cameraController?.takePicture();
      if (photo == null) {
        _restartDetection();
        return;
      }

      state = state.copyWith(
        status: ProctorFaceCheckInStatus.checkingIn,
        instructionMessage: '',
      );

      final base64Image = await _processImage(photo.path);
      final service = DependencyInjection.get<FaceRegistrationService>();
      final result = await service.proctorCheckIn(
        imageBase64: base64Image,
        examSessionId: examSessionId,
        isEncrypted: false,
      );

      final level1Data = result['data'] ?? result;
      final isSuccess = result['status'] == 'success' ||
          level1Data['status'] == 'success';

      if (isSuccess) {
        state = state.copyWith(
          status: ProctorFaceCheckInStatus.success,
          confidence: (level1Data['confidence'] as num?)?.toDouble(),
        );
      } else {
        state = state.copyWith(
          status: ProctorFaceCheckInStatus.failed,
          errorMessage:
              result['message'] ?? level1Data['message'] ?? 'Điểm danh thất bại',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ProctorFaceCheckInStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isCapturing = false;
      _stableCount = 0;
    }
  }

  Future<String> _processImage(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage != null) {
      final compressed = img.encodeJpg(decodedImage, quality: 75);
      return base64Encode(compressed);
    }
    return base64Encode(imageBytes);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = state.cameraController?.description;
    if (camera == null) return null;

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  void retry() {
    _stableCount = 0;
    _resetBlinkDetection();
    state = state.copyWith(
      status: ProctorFaceCheckInStatus.scanning,
      instructionMessage: 'Đưa khuôn mặt vào khung hình',
      stableCount: 0,
      requiredStableFrames: _requiredStableFrames,
      confidence: null,
      clearError: true,
    );
    _startTimeout();
    _restartDetection();
  }

  void _restartDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(_detectionInterval, (_) {
      _processLatestImage();
    });
  }

  void _resetBlinkDetection() {
    _blinkDetected = false;
    _blinkCount = 0;
    _eyesClosedFrames = 0;
    _eyesReopenedFrames = 0;
    _blinkClosingPhase = false;
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted &&
          state.status != ProctorFaceCheckInStatus.success &&
          state.status != ProctorFaceCheckInStatus.checkingIn) {
        _detectionTimer?.cancel();
        state = state.copyWith(
          status: ProctorFaceCheckInStatus.error,
          errorMessage: 'Hết thời gian quét khuôn mặt. Vui lòng thử lại.',
        );
      }
    });
  }
}
