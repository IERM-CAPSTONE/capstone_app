import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../../../data/services/face_registration_service.dart';
import '../../../config/dependency_injection.dart';
import 'face_authenticate_state.dart';

final faceAuthenticateControllerProvider =
    StateNotifierProvider<FaceAuthenticateController, FaceAuthenticateState>(
        (ref) {
  return FaceAuthenticateController();
});

class FaceAuthenticateController extends StateNotifier<FaceAuthenticateState> {
  FaceDetector? _faceDetector;
  Timer? _detectionTimer;
  bool _isProcessing = false;
  bool _isCapturing = false;
  Timer? _timeoutTimer;
  CameraImage? _lastImage;
  int _frameCounter = 0;
  int _poseStableCount = 0;
  static const int _requiredStableFrames = 3;

  // Blink detection (Liveness)
  bool _blinkDetected = false;
  bool _wasEyesOpen = true;
  int _blinkCount = 0;
  static const int _requiredBlinks = 1;

  // Thresholds
  static const double _centerThreshold = 10.0;

  FaceAuthenticateController() : super(const FaceAuthenticateState());

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _detectionTimer?.cancel();
    _faceDetector?.close();
    state.cameraController?.dispose();
    super.dispose();
  }

  Future<void> initializeCamera({
    String? examSessionId,
    String? examPartCode,
  }) async {
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
        throw Exception('No camera available');
      }

      CameraDescription selectedCamera = cameras.first;
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

      // Reset state completely with new controller
      state = FaceAuthenticateState(
        cameraController: controller,
        status: FaceAuthenticateStatus.scanning,
        instructionMessage: '',
        examSessionId: examSessionId,
        examPartCode: examPartCode,
      );

      controller.startImageStream((image) {
        _lastImage = image;
      });

      _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _processLatestImage();
      });

      _startTimeout();
    } catch (e) {
      state = state.copyWith(
        status: FaceAuthenticateStatus.error,
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
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector?.processImage(inputImage);

      if (faces == null || faces.isEmpty) {
        state = state.copyWith(
          status: FaceAuthenticateStatus.scanning,
          instructionMessage: '',
        );
      } else {
        final face = faces.first;
        final headY = face.headEulerAngleY ?? 0;
        final headX = face.headEulerAngleX ?? 0;

        _detectBlink(face);

        final isCenter =
            headY.abs() < _centerThreshold && headX.abs() < _centerThreshold;

        if (isCenter) {
          if (!_blinkDetected) {
            state = state.copyWith(
              status: FaceAuthenticateStatus.livenessCheck,
              instructionMessage: '',
            );
          } else {
            _poseStableCount++;
            state = state.copyWith(
              status: FaceAuthenticateStatus.faceDetected,
              poseStableCount: _poseStableCount,
              requiredStableFrames: _requiredStableFrames,
              instructionMessage: '',
            );

            if (_poseStableCount >= _requiredStableFrames) {
              await _authenticate();
            }
          }
        } else {
          _poseStableCount = 0;
          state = state.copyWith(
            status: FaceAuthenticateStatus.faceDetected,
            instructionMessage: '',
          );
        }
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _detectBlink(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;

    if (avgEyeOpen > 0.8) {
      _wasEyesOpen = true;
    } else if (avgEyeOpen < 0.25 && _wasEyesOpen) {
      _blinkCount++;
      _wasEyesOpen = false;
      debugPrint('Blink detected! Count: $_blinkCount');
      if (_blinkCount >= _requiredBlinks) {
        _blinkDetected = true;
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      _detectionTimer?.cancel();
      _timeoutTimer?.cancel();

      final XFile? photo = await state.cameraController?.takePicture();
      if (photo == null) {
        _isCapturing = false;
        _startDetection();
        return;
      }

      state = state.copyWith(
        status: FaceAuthenticateStatus.authenticating,
        instructionMessage: '',
      );

      final base64Image = await _processImage(photo.path);

      final service = DependencyInjection.get<FaceRegistrationService>();
      final result = await service.authenticateFace(
        imageBase64: base64Image,
        examSessionId: state.examSessionId,
        examPartCode: state.examPartCode,
        isEncrypted: false,
      );

      // Handle NestJS response structure (Double data wrap due to Interceptor)
      final level1Data = result['data'] ?? result;
      final level2Data = (level1Data is Map && level1Data.containsKey('data'))
          ? level1Data['data']
          : level1Data;

      // Improved response handling
      final isSuccess = (result['status'] == 'success' ||
          level1Data['status'] == 'success' ||
          level2Data['status'] == 'success');
      final studentId = level2Data['student_id'] ??
          level2Data['studentId'] ??
          level1Data['student_id'] ??
          level1Data['studentId'];
      final isCorrectRoom =
          level2Data['isCorrectRoom'] ?? level1Data['isCorrectRoom'] ?? true;

      if (isSuccess && studentId != null && isCorrectRoom != false) {
        // RESET all liveness flags immediately on success
        _blinkDetected = false;
        _blinkCount = 0;
        _poseStableCount = 0;

        state = state.copyWith(
          status: FaceAuthenticateStatus.authenticated,
          confidence: level2Data['confidence']?.toDouble() ??
              level1Data['confidence']?.toDouble(),
          studentId: studentId,
          studentCode: level2Data['studentCode'] ?? level1Data['studentCode'],
          studentName: level2Data['studentName'] ?? level1Data['studentName'],
          instructionMessage: '',
        );
      } else {
        // RESET states so next attempt requires blink again
        _blinkDetected = false;
        _blinkCount = 0;

        state = state.copyWith(
          status: FaceAuthenticateStatus.failed,
          studentId: null,
          studentCode: null,
          studentName: null,
          errorMessage: result['message'] ??
              level1Data['message'] ??
              level2Data['message'],
        );
        // Removed _startDetection() to wait for user to click "Retry"
      }
    } catch (e) {
      state = state.copyWith(
        status: FaceAuthenticateStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isCapturing = false;
      _poseStableCount = 0; // Reset counter after attempt
    }
  }

  void _startDetection() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _processLatestImage();
    });
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
    _blinkDetected = false;
    _blinkCount = 0;
    _poseStableCount = 0;
    _wasEyesOpen = true;
    state = state.copyWith(
      status: FaceAuthenticateStatus.scanning,
      instructionMessage: '',
      errorMessage: null,
      studentId: null,
      studentCode: null,
      studentName: null,
    );
    _startTimeout();
    _startDetection();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted &&
          state.status != FaceAuthenticateStatus.authenticated &&
          state.status != FaceAuthenticateStatus.authenticating) {
        _detectionTimer?.cancel();
        state = state.copyWith(
          status: FaceAuthenticateStatus.error,
          errorMessage: 'Timeout (30 seconds). Please try again.',
        );
      }
    });
  }
}
