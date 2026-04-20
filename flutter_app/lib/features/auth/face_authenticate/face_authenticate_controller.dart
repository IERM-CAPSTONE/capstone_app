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
  int _poseStableCount = 0;
  static const Duration _detectionInterval = Duration(milliseconds: 180);
  static const int _requiredStableFrames = 2;

  // Blink detection (Liveness)
  bool _blinkDetected = false;
  int _blinkCount = 0;
  int _eyesClosedFrames = 0;
  int _eyesReopenedFrames = 0;
  bool _blinkClosingPhase = false;
  DateTime? _lastBlinkAt;
  static const int _requiredBlinks = 1;
  static const int _requiredClosedFrames = 1;
  static const int _requiredReopenedFrames = 1;

  // Thresholds
  static const double _centerThreshold = 12.0;
  static const double _eyeClosedThreshold = 0.40;
  static const double _eyeOpenThreshold = 0.65;
  static const double _minFaceWidthRatio = 0.26;
  static const double _minFaceHeightRatio = 0.34;
  static const double _maxFaceOffsetXRatio = 0.12;
  static const double _maxFaceOffsetYRatio = 0.18;
  static const double _minEdgePaddingRatio = 0.06;

  FaceAuthenticateController() : super(const FaceAuthenticateState());

  @override
  void dispose() {
    shutdown();
    super.dispose();
  }

  Future<void> shutdown() async {
    _timeoutTimer?.cancel();
    _detectionTimer?.cancel();
    _timeoutTimer = null;
    _detectionTimer = null;
    _lastImage = null;
    _isProcessing = false;
    _isCapturing = false;

    final controller = state.cameraController;
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}

      try {
        await controller.dispose();
      } catch (_) {}
    }

    state = const FaceAuthenticateState();
    _faceDetector?.close();
    _faceDetector = null;
  }

  Future<void> initializeCamera({
    String? examSessionId,
    String? examPartCode,
  }) async {
    try {
      state = FaceAuthenticateState(
        status: FaceAuthenticateStatus.scanning,
        instructionMessage: '',
        examSessionId: examSessionId,
        examPartCode: examPartCode,
      );

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

      _detectionTimer = Timer.periodic(_detectionInterval, (_) {
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
        _resetTrackingState();
        state = state.copyWith(
          status: FaceAuthenticateStatus.scanning,
          instructionMessage: '',
        );
      } else {
        if (faces.length > 1) {
          _resetTrackingState(resetBlink: false);
          state = state.copyWith(
            status: FaceAuthenticateStatus.scanning,
            instructionMessage: 'Chỉ để một khuôn mặt trong khung hình',
          );
          return;
        }

        final face = faces.first;
        if (!_isFaceWellPositioned(face, inputImage.metadata!.size)) {
          _resetTrackingState(resetBlink: false);
          state = state.copyWith(
            status: FaceAuthenticateStatus.faceDetected,
            instructionMessage: 'Đưa mặt vào giữa khung và lại gần hơn',
          );
          return;
        }

        final headY = face.headEulerAngleY ?? 0;
        final headX = face.headEulerAngleX ?? 0;

        _detectBlink(face);

        final isCenter =
            headY.abs() < _centerThreshold && headX.abs() < _centerThreshold;

        if (isCenter) {
          if (!_blinkDetected) {
            _poseStableCount = 0;
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
          _resetTrackingState(resetBlink: false);
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

    if (avgEyeOpen <= _eyeClosedThreshold) {
      _eyesClosedFrames++;
      _eyesReopenedFrames = 0;
      if (_eyesClosedFrames >= _requiredClosedFrames) {
        _blinkClosingPhase = true;
      }
      return;
    }

    if (avgEyeOpen >= _eyeOpenThreshold) {
      if (_blinkClosingPhase) {
        _eyesReopenedFrames++;
        if (_eyesReopenedFrames >= _requiredReopenedFrames) {
          final now = DateTime.now();
          final isCooldownDone = _lastBlinkAt == null ||
              now.difference(_lastBlinkAt!) > const Duration(milliseconds: 800);
          if (isCooldownDone) {
            _blinkCount++;
            _blinkDetected = _blinkCount >= _requiredBlinks;
            _lastBlinkAt = now;
            debugPrint('Blink detected! Count: $_blinkCount');
          }
          _blinkClosingPhase = false;
          _eyesClosedFrames = 0;
          _eyesReopenedFrames = 0;
        }
      } else {
        _eyesClosedFrames = 0;
        _eyesReopenedFrames = 0;
      }
      return;
    }

    _eyesReopenedFrames = 0;
  }

  bool _isFaceWellPositioned(Face face, Size imageSize) {
    final boundingBox = face.boundingBox;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    final widthRatio = boundingBox.width / imageSize.width;
    final heightRatio = boundingBox.height / imageSize.height;
    final centerX = boundingBox.left + (boundingBox.width / 2);
    final centerY = boundingBox.top + (boundingBox.height / 2);
    final offsetXRatio = (centerX - imageSize.width / 2).abs() / imageSize.width;
    final offsetYRatio =
        (centerY - imageSize.height / 2).abs() / imageSize.height;
    final minHorizontalPadding = imageSize.width * _minEdgePaddingRatio;
    final minVerticalPadding = imageSize.height * _minEdgePaddingRatio;
    final isInsideFrame = boundingBox.left >= minHorizontalPadding &&
        boundingBox.top >= minVerticalPadding &&
        boundingBox.right <= imageSize.width - minHorizontalPadding &&
        boundingBox.bottom <= imageSize.height - minVerticalPadding;
    final hasCoreLandmarks =
        leftEye != null && rightEye != null && noseBase != null;

    return hasCoreLandmarks &&
        isInsideFrame &&
        widthRatio >= _minFaceWidthRatio &&
        heightRatio >= _minFaceHeightRatio &&
        offsetXRatio <= _maxFaceOffsetXRatio &&
        offsetYRatio <= _maxFaceOffsetYRatio;
  }

  void _resetTrackingState({bool resetBlink = true}) {
    _poseStableCount = 0;
    if (resetBlink) {
      _blinkDetected = false;
      _blinkCount = 0;
      _lastBlinkAt = null;
    }
    _eyesClosedFrames = 0;
    _eyesReopenedFrames = 0;
    _blinkClosingPhase = false;
  }

  Future<void> _authenticate() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      _detectionTimer?.cancel();
      _timeoutTimer?.cancel();

      final photos = await _captureAuthenticationFrames();
      if (photos.isEmpty) {
        _isCapturing = false;
        _startDetection();
        return;
      }

      state = state.copyWith(
        status: FaceAuthenticateStatus.authenticating,
        instructionMessage: '',
      );

      final processedImages = <String>[];
      for (final photo in photos) {
        processedImages.add(await _processImage(photo.path));
      }
      final base64Image = processedImages.first;

      final service = DependencyInjection.get<FaceRegistrationService>();
      final result = await service.authenticateFace(
        imageBase64: base64Image,
        images: processedImages,
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
        _resetTrackingState();

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
        _resetTrackingState();

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
    _detectionTimer = Timer.periodic(_detectionInterval, (_) {
      _processLatestImage();
    });
  }

  Future<List<XFile>> _captureAuthenticationFrames() async {
    final controller = state.cameraController;
    if (controller == null) return const [];

    final captures = <XFile>[];
    for (var i = 0; i < 2; i++) {
      final photo = await controller.takePicture();
      captures.add(photo);
      if (i < 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    return captures;
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
    _resetTrackingState();
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
