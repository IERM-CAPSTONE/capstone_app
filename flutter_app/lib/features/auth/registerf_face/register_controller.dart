import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../../../config/dependency_injection.dart';
import '../../../core/services/glasses_detection_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/face_registration_service.dart';
import '../../../data/services/socket_service.dart';
import 'register_state.dart';

final registerFaceControllerProvider = StateNotifierProvider.autoDispose<
    RegisterFaceController, RegisterFaceState>((ref) {
  return RegisterFaceController();
});

class RegisterFaceController extends StateNotifier<RegisterFaceState> {
  FaceDetector? _faceDetector;
  Timer? _detectionTimer;
  bool _isProcessing = false;
  bool _isCapturing = false;
  CameraImage? _lastImage;
  final _glassesService = GlassesDetectionService();
  int _poseStableCount = 0;
  static const Duration _detectionInterval = Duration(milliseconds: 250);
  static const int _requiredStableFrames = 2;

  // Blink detection
  bool _blinkDetected = false;
  int _blinkCount = 0;
  int _eyesClosedFrames = 0;
  int _eyesReopenedFrames = 0;
  bool _blinkClosingPhase = false;
  static const int _requiredBlinks = 1;
  static const int _requiredClosedFrames = 1;
  static const int _requiredReopenedFrames = 1;

  // Head pose thresholds
  static const double _hMin = 12.0;
  static const double _vUpMin = 3.0;
  static const double _vDownMin = 5.0;
  static const double _centerThreshold = 12.0;

  RegisterFaceController() : super(const RegisterFaceState());

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _faceDetector?.close();
    _glassesService.dispose();
    state.cameraController?.dispose();
    try {
      final socketService = DependencyInjection.get<SocketService>();
      socketService.unsubscribe('face_registered');
    } catch (_) {}
    super.dispose();
  }

  Future<void> initializeCamera() async {
    try {
      _detectionTimer?.cancel();
      await state.cameraController?.dispose();
      _lastImage = null;
      _isProcessing = false;
      _isCapturing = false;
      _poseStableCount = 0;

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableTracking: false,
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      await _glassesService.loadModel();

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
      _resetBlinkDetection();

      state = state.copyWith(
        cameraController: controller,
        status: FaceScanStatus.scanning,
        instructionMessage:
            RegisterFaceState.getPoseInstruction(HeadPose.center),
      );

      controller.startImageStream((image) {
        _lastImage = image;
      });

      _detectionTimer = Timer.periodic(_detectionInterval, (_) {
        _processLatestImage();
      });

      final authService = DependencyInjection.get<AuthService>();
      final token = authService.getToken();
      final user = await authService.getSavedUserData();
      if (token != null && user?.id != null) {
        final socketService = DependencyInjection.get<SocketService>();
        socketService.initAndJoin(
          token: token,
          userId: user!.id!,
          campus: user.code,
        );
        socketService.subscribe('face_registered', (data) {
          debugPrint('Real-time event received: $data');
          if (data['status'] == 'success') {
            state = state.copyWith(status: FaceScanStatus.completed);
          }
        });
      }
    } catch (e, st) {
      debugPrint('Register camera init error: $e');
      debugPrint('$st');
      state = state.copyWith(
        status: FaceScanStatus.error,
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
        _poseStableCount = 0;
        if (state.currentPose == HeadPose.center) {
          _resetBlinkDetection();
        }
        if (state.status != FaceScanStatus.scanning) {
          state = state.copyWith(
            status: FaceScanStatus.scanning,
            instructionMessage: 'Không tìm thấy khuôn mặt',
          );
        }
      } else {
        final face = faces.first;
        final headY = face.headEulerAngleY ?? 0;
        final headX = face.headEulerAngleX ?? 0;

        if (state.currentPose == HeadPose.center) {
          _detectBlink(face);
        }

        final isWearingGlasses = _detectGlasses(face);
        final poseMatched = _checkPoseMatch(state.currentPose, headY, headX);

        if (poseMatched) {
          if (state.currentPose == HeadPose.center && !_blinkDetected) {
            state = state.copyWith(
              status: FaceScanStatus.faceDetected,
              instructionMessage:
                  'Nháy mắt $_blinkCount/$_requiredBlinks lần',
              isWearingGlasses: isWearingGlasses,
            );
            return;
          }

          _poseStableCount++;

          String message =
              'Giữ yên... $_poseStableCount/$_requiredStableFrames';
          if (state.currentPose == HeadPose.center && _blinkDetected) {
            message =
                'Liveness OK! Giữ yên... $_poseStableCount/$_requiredStableFrames';
          }

          state = state.copyWith(
            status: FaceScanStatus.poseValid,
            instructionMessage: message,
            isWearingGlasses: isWearingGlasses,
          );

          if (_poseStableCount >= _requiredStableFrames) {
            _poseStableCount = 0;
            await _captureCurrentPose();
          }
        } else {
          _poseStableCount = 0;

          String instruction =
              RegisterFaceState.getPoseInstruction(state.currentPose);
          if (state.currentPose == HeadPose.up) {
            instruction += ' (Ngửa đầu ra sau)';
          }

          state = state.copyWith(
            status: FaceScanStatus.faceDetected,
            instructionMessage: instruction,
            isWearingGlasses: isWearingGlasses,
          );
        }
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  bool _detectGlasses(Face face) {
    return false;
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
          debugPrint('Blink detected! Count: $_blinkCount');
        }
      } else {
        _eyesClosedFrames = 0;
        _eyesReopenedFrames = 0;
      }
      return;
    }

    _eyesReopenedFrames = 0;
  }

  bool _checkPoseMatch(HeadPose requiredPose, double eulerY, double eulerX) {
    switch (requiredPose) {
      case HeadPose.center:
        return eulerY.abs() < _centerThreshold &&
            eulerX.abs() < _centerThreshold;
      case HeadPose.left:
        return eulerY > _hMin;
      case HeadPose.right:
        return eulerY < -_hMin;
      case HeadPose.up:
        return eulerX > _vUpMin;
      case HeadPose.down:
        return eulerX < -_vDownMin;
    }
  }

  Future<void> _captureCurrentPose() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      _detectionTimer?.cancel();
      await Future.delayed(const Duration(milliseconds: 100));

      final XFile? photo = await state.cameraController?.takePicture();
      if (photo == null) {
        _restartDetection();
        return;
      }

      final newCapturedPoses = [...state.capturedPoses, state.currentPose];
      final newCapturedImages =
          Map<HeadPose, String>.from(state.capturedImages);
      newCapturedImages[state.currentPose] = photo.path;

      if (newCapturedPoses.length >= HeadPose.values.length) {
        state = state.copyWith(
          status: FaceScanStatus.completed,
          capturedPoses: newCapturedPoses,
          capturedImages: newCapturedImages,
          instructionMessage: 'Đang tự động gửi dữ liệu...',
        );

        registerFace('');
      } else {
        final nextPose = _getNextPose(newCapturedPoses);

        if (nextPose == HeadPose.center) {
          _resetBlinkDetection();
        }

        state = state.copyWith(
          status: FaceScanStatus.scanning,
          capturedPoses: newCapturedPoses,
          capturedImages: newCapturedImages,
          currentPose: nextPose,
          instructionMessage: RegisterFaceState.getPoseInstruction(nextPose),
        );
        _restartDetection();
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      _isCapturing = false;
    }
  }

  void _restartDetection() {
    _isCapturing = false;
    if (state.cameraController != null &&
        !state.cameraController!.value.isStreamingImages) {
      state.cameraController?.startImageStream((image) {
        _lastImage = image;
      });
    }

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

  HeadPose _getNextPose(List<HeadPose> captured) {
    for (final pose in HeadPose.values) {
      if (!captured.contains(pose)) return pose;
    }
    return HeadPose.center;
  }

  Future<void> registerFace(String studentId,
      {Map<HeadPose, String>? debugImages}) async {
    final imagesToProcess = debugImages ?? state.capturedImages;

    state = state.copyWith(
        status: FaceScanStatus.capturing,
        instructionMessage: 'Đang đăng ký lên Server...');

    try {
      final processedImages = <HeadPose, String>{};
      for (final entry in imagesToProcess.entries) {
        final base64Data = await _processImage(entry.value);
        processedImages[entry.key] = base64Data;
      }

      final service = DependencyInjection.get<FaceRegistrationService>();
      final result = await service.registerFace(
        capturedImages: processedImages,
        studentId: studentId,
        isEncrypted: false,
      );

      final actualData = result['data'] ?? {};

      if (actualData['status'] == 'success') {
        state = state.copyWith(status: FaceScanStatus.completed);
      } else {
        state = state.copyWith(
          status: FaceScanStatus.error,
          errorMessage: actualData['message'] ?? 'Server error',
          capturedImages: imagesToProcess,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: FaceScanStatus.error,
        errorMessage: e.toString(),
        capturedImages: imagesToProcess,
      );
    }
  }

  Future<String> _processImage(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      Uint8List dataToSend;
      if (decodedImage != null) {
        dataToSend =
            Uint8List.fromList(img.encodeJpg(decodedImage, quality: 70));
        debugPrint(
            'Compressed image: ${imageBytes.length} -> ${dataToSend.length} bytes');
      } else {
        dataToSend = imageBytes;
      }

      return base64Encode(dataToSend);
    } catch (e) {
      debugPrint('Error processing image: $e');
      rethrow;
    }
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
}
