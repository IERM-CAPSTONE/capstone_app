import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../../../data/services/face_registration_service.dart';
import '../../../core/services/glasses_detection_service.dart';
import 'register_state.dart';

final registerFaceControllerProvider =
    StateNotifierProvider<RegisterFaceController, RegisterFaceState>((ref) {
  return RegisterFaceController();
});

class RegisterFaceController extends StateNotifier<RegisterFaceState> {
  FaceDetector? _faceDetector;
  Timer? _detectionTimer;
  bool _isProcessing = false;
  bool _isCapturing = false;
  CameraImage? _lastImage;
  final _glassesService = GlassesDetectionService();
  int _frameCounter = 0; // Đếm frames để skip
  int _poseStableCount = 0; // Đếm số lần pose ổn định
  static const int _requiredStableFrames = 3; // Cần 3 lần ổn định mới chụp

  // Blink detection
  bool _blinkDetected = false;
  bool _wasEyesOpen = true;
  int _blinkCount = 0;
  static const int _requiredBlinks = 1; // Cần nhấp nháy ít nhất 1 lần

  // Ngưỡng góc quay đầu - Giảm để dễ bắt hơn
  static const double _hMin = 15.0; // LEFT/RIGHT: quay trái/phải ít nhất 15°
  static const double _vUpMin = 10.0; // UP: ngửa đầu ít nhất 10°
  static const double _vDownMin = 10.0; // DOWN: cúi đầu ít nhất 10°
  static const double _centerThreshold =
      10.0; // CENTER: cho phép lệch ±10°

  // AES Encryption Key (must be 32 characters for AES-256)
  // IMPORTANT: In production, store this key securely (e.g., env variables, secure storage)
  final String _encryptionKey = 'MySecureKey123456789012345678901'; // 32 chars

  RegisterFaceController() : super(const RegisterFaceState());

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _faceDetector?.close();
    _glassesService.dispose();
    state.cameraController?.dispose();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true, // Bật để có blink detection
          enableTracking: false,
          enableLandmarks: true, // CẦN BẬT để tính head pose chính xác
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      await _glassesService.loadModel();

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.low, // Giữ low, không có veryLow
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();

      state = state.copyWith(
        cameraController: controller,
        status: FaceScanStatus.scanning,
        instructionMessage:
            RegisterFaceState.getPoseInstruction(HeadPose.center),
      );

      controller.startImageStream((image) {
        _lastImage = image;
      });

      _detectionTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        _processLatestImage();
      });
    } catch (e) {
      state = state.copyWith(
        status: FaceScanStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _processLatestImage() {
    if (_isProcessing || _isCapturing || _lastImage == null) return;

    // Skip frames để giảm tải - chỉ xử lý mỗi 3 frames
    _frameCounter++;
    if (_frameCounter % 3 != 0) return;

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

        // Detect blink cho liveness check (chỉ ở pose CENTER)
        if (state.currentPose == HeadPose.center) {
          _detectBlink(face);
        }

        final isWearingGlasses = _detectGlasses(face);
        final poseMatched = _checkPoseMatch(state.currentPose, headY, headX);

        if (poseMatched) {
          // Nếu là pose CENTER, yêu cầu blink trước
          if (state.currentPose == HeadPose.center && !_blinkDetected) {
            state = state.copyWith(
              status: FaceScanStatus.faceDetected,
              instructionMessage: '👁️ Nhấp nháy mắt $_blinkCount/$_requiredBlinks lần',
              isWearingGlasses: isWearingGlasses,
            );
            return; // Chưa cho phép tiếp tục
          }

          _poseStableCount++;

          String message = '✓ Giữ yên... $_poseStableCount/$_requiredStableFrames';
          if (state.currentPose == HeadPose.center && _blinkDetected) {
            message = '✓ Liveness OK! Giữ yên... $_poseStableCount/$_requiredStableFrames';
          }

          state = state.copyWith(
            status: FaceScanStatus.poseValid,
            instructionMessage: message,
            isWearingGlasses: isWearingGlasses,
          );

          // Chỉ chụp khi đã giữ pose ổn định đủ lâu
          if (_poseStableCount >= _requiredStableFrames) {
            _poseStableCount = 0; // Reset
            await _captureCurrentPose();
          }
        } else {
          // Reset counter khi pose không đúng
          _poseStableCount = 0;

          String instruction =
              RegisterFaceState.getPoseInstruction(state.currentPose);
          if (state.currentPose == HeadPose.up) {
            instruction += ' (Ngửea đầu ra sau)';
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
    // Tắt phát hiện kính vì backend Python xử lý tốt người đeo kính
    // và việc phát hiện ở frontend không chính xác khi tắt classification
    return false;
  }

  void _detectBlink(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;

    // Mắt mở: probability > 0.7
    // Mắt nhắm: probability < 0.3
    const eyeClosedThreshold = 0.3;
    const eyeOpenThreshold = 0.7;

    if (avgEyeOpen > eyeOpenThreshold) {
      _wasEyesOpen = true;
    } else if (avgEyeOpen < eyeClosedThreshold && _wasEyesOpen) {
      // Phát hiện blink: mắt mở → nhắm
      _blinkCount++;
      _wasEyesOpen = false;
      debugPrint('Blink detected! Count: $_blinkCount');

      if (_blinkCount >= _requiredBlinks) {
        _blinkDetected = true;
      }
    }
  }

  bool _checkPoseMatch(HeadPose requiredPose, double eulerY, double eulerX) {
    switch (requiredPose) {
      case HeadPose.center:
        return eulerY.abs() < _centerThreshold &&
            eulerX.abs() < _centerThreshold;
      case HeadPose.left:
        // Front camera mirror: người quay trái → Y dương (phải trong ảnh)
        return eulerY > _hMin;
      case HeadPose.right:
        // Front camera mirror: người quay phải → Y âm (trái trong ảnh)
        return eulerY < -_hMin;
      case HeadPose.up:
        return eulerX < -_vUpMin;
      case HeadPose.down:
        return eulerX > _vDownMin;
    }
  }

  Future<void> _captureCurrentPose() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      _detectionTimer?.cancel();
      await state.cameraController?.stopImageStream();

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
          instructionMessage: 'Đã hoàn thành chụp 5 góc!',
        );
      } else {
        final nextPose = _getNextPose(newCapturedPoses);
        
        // Reset blink detection cho pose CENTER mới
        if (nextPose == HeadPose.center) {
          _blinkDetected = false;
          _blinkCount = 0;
          _wasEyesOpen = true;
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
    state.cameraController?.startImageStream((image) {
      _lastImage = image;
    });
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _processLatestImage();
    });
  }

  HeadPose _getNextPose(List<HeadPose> captured) {
    for (final pose in HeadPose.values) {
      if (!captured.contains(pose)) return pose;
    }
    return HeadPose.center;
  }

  Future<void> registerFace(String studentId) async {
    state = state.copyWith(
        status: FaceScanStatus.capturing,
        instructionMessage: 'Đang đăng ký...');

    try {
      // Encrypt images before sending
      final encryptedImages = <HeadPose, String>{};
      for (final entry in state.capturedImages.entries) {
        final encryptedData = await _encryptImage(entry.value);
        encryptedImages[entry.key] = encryptedData;
      }

      final service = FaceRegistrationService();
      final result = await service.registerFace(
        capturedImages: encryptedImages, // Send encrypted data
        studentId: studentId,
        isEncrypted: true, // Flag to indicate data is encrypted
      );

      if (result['status'] == 'success') {
        state = state.copyWith(status: FaceScanStatus.completed);
      } else {
        state = state.copyWith(
          status: FaceScanStatus.error,
          errorMessage: result['message'] ?? 'Đăng ký thất bại',
        );
      }
    } catch (e) {
      state = state.copyWith(
          status: FaceScanStatus.error, errorMessage: e.toString());
    }
  }

  /// Encrypts image file using AES-256 and returns Base64 encoded string
  Future<String> _encryptImage(String imagePath) async {
    try {
      // Read image bytes
      final imageBytes = await File(imagePath).readAsBytes();
      
      // Create AES key and IV
      final key = encrypt.Key.fromUtf8(_encryptionKey);
      final iv = encrypt.IV.fromLength(16);
      
      // Create encrypter
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Encrypt the image bytes
      final encrypted = encrypter.encryptBytes(imageBytes, iv: iv);
      
      // Return Base64 encoded encrypted data
      return encrypted.base64;
    } catch (e) {
      debugPrint('Error encrypting image: $e');
      rethrow;
    }
  }

  /// Generate SHA-256 hash for data integrity verification
  String _generateHash(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
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
