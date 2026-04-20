import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import 'register_controller.dart';
import 'register_state.dart';

class RegisterFaceLiveScanPage extends ConsumerStatefulWidget {
  const RegisterFaceLiveScanPage({super.key});

  @override
  ConsumerState<RegisterFaceLiveScanPage> createState() =>
      _RegisterFaceLiveScanPageState();
}

class _RegisterFaceLiveScanPageState
    extends ConsumerState<RegisterFaceLiveScanPage> {
  Future<void> _shutdownCamera() async {
    await ref.read(registerFaceControllerProvider.notifier).shutdown();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerFaceControllerProvider.notifier).initializeCamera();
    });
  }

  @override
  void dispose() {
    _shutdownCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerFaceControllerProvider, (previous, next) {
      if (next.status == FaceScanStatus.completed &&
          previous?.status != FaceScanStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    });

    final state = ref.watch(registerFaceControllerProvider);

    if (state.status == FaceScanStatus.completed) {
      return _buildCompletedScreen(context);
    }

    if (state.status == FaceScanStatus.error) {
      return _buildErrorScreen(context);
    }

    if (state.status == FaceScanStatus.capturing) {
      return _buildProcessingScreen(context, state.instructionMessage);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: const [
            RepaintBoundary(child: _CameraPreviewWidget()),
            _OvalOverlayWidget(),
            _HeaderWidget(),
            _InstructionWidget(),
            _GlassesWarningWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingScreen(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.appBarOrange),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith('vi');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 80),
              const SizedBox(height: 24),
              Text(
                isVietnamese
                    ? 'L\u1ed7i \u0111\u0103ng k\u00fd!'
                    : 'Registration failed!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isVietnamese
                    ? '\u0110\u0103ng k\u00fd khu\u00f4n m\u1eb7t kh\u00f4ng th\u00e0nh c\u00f4ng. Vui l\u00f2ng th\u1eed l\u1ea1i t\u1eeb \u0111\u1ea7u.'
                    : 'Face registration was unsuccessful. Please try again from the beginning.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appBarOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(
                    isVietnamese
                        ? 'Th\u1eed l\u1ea1i t\u1eeb \u0111\u1ea7u'
                        : 'Start over',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedScreen(BuildContext context) {
    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith('vi');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            Text(
              isVietnamese
                  ? '\u0110\u0103ng k\u00fd th\u00e0nh c\u00f4ng!'
                  : 'Registration successful!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              isVietnamese
                  ? 'D\u1eef li\u1ec7u khu\u00f4n m\u1eb7t \u0111\u00e3 \u0111\u01b0\u1ee3c c\u1eadp nh\u1eadt.'
                  : 'Your facial data has been updated.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appBarOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: Text(isVietnamese ? 'Ho\u00e0n t\u1ea5t' : 'Complete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewWidget extends ConsumerWidget {
  const _CameraPreviewWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(
      registerFaceControllerProvider.select((s) => s.cameraController),
    );
    if (controller != null && controller.value.isInitialized) {
      return Center(child: CameraPreview(controller));
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}

class _OvalOverlayWidget extends ConsumerWidget {
  const _OvalOverlayWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      registerFaceControllerProvider.select((s) => s.status),
    );
    return CustomPaint(
      painter: SimpleOvalPainter(isValid: status == FaceScanStatus.poseValid),
    );
  }
}

class _HeaderWidget extends ConsumerWidget {
  const _HeaderWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      registerFaceControllerProvider.select((s) => s.capturedPoses.length),
    );
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count/5',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionWidget extends ConsumerWidget {
  const _InstructionWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerFaceControllerProvider);

    IconData icon = Icons.face;
    Color color = Colors.white;
    if (state.status == FaceScanStatus.poseValid) {
      icon = Icons.check_circle;
      color = Colors.greenAccent;
    } else {
      switch (state.currentPose) {
        case HeadPose.left:
          icon = Icons.arrow_back;
          break;
        case HeadPose.right:
          icon = Icons.arrow_forward;
          break;
        case HeadPose.up:
          icon = Icons.arrow_upward;
          break;
        case HeadPose.down:
          icon = Icons.arrow_downward;
          break;
        case HeadPose.center:
          icon = Icons.center_focus_strong;
          break;
      }
    }

    return Positioned(
      bottom: 60,
      left: 40,
      right: 40,
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Text(
            state.instructionMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleOvalPainter extends CustomPainter {
  final bool isValid;

  SimpleOvalPainter({required this.isValid});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final center = Offset(size.width / 2, size.height * 0.4);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.72,
      height: size.width * 1.0,
    );
    final ovalPath = Path()..addOval(ovalRect);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        ovalPath,
      ),
      paint,
    );
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = isValid ? Colors.green : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant SimpleOvalPainter oldDelegate) =>
      oldDelegate.isValid != isValid;
}

class _GlassesWarningWidget extends ConsumerWidget {
  const _GlassesWarningWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWearingGlasses = ref.watch(
      registerFaceControllerProvider.select((s) => s.isWearingGlasses),
    );

    if (!isWearingGlasses) {
      return const SizedBox.shrink();
    }

    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith('vi');

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_off, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isVietnamese
                    ? 'Vui l\u00f2ng th\u00e1o k\u00ednh \u0111\u1ec3 h\u1ec7 th\u1ed1ng nh\u1eadn di\u1ec7n ch\u00ednh x\u00e1c h\u01a1n.'
                    : 'Please remove your glasses so the system can detect your face more accurately.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
