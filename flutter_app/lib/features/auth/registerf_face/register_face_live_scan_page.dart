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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerFaceControllerProvider.notifier).initializeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerFaceControllerProvider);

    // Auto-navigation or auto-response based on state
    if (state.status == FaceScanStatus.completed) {
      return _buildCompletedScreen(context);
    }

    if (state.status == FaceScanStatus.error) {
      return _buildErrorScreen(context, state.errorMessage ?? "Unknown error");
    }

    if (state.status == FaceScanStatus.capturing) {
      return _buildProcessingScreen(context, state.instructionMessage);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RepaintBoundary(child: _CameraPreviewWidget()),
            const _OvalOverlayWidget(),
            const _HeaderWidget(),
            const _InstructionWidget(),
            const _GlassesWarningWidget(),

            // Debug button for testing (Quick re-submit)
            if (state.capturedImages.length == 5)
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  backgroundColor: Colors.redAccent,
                  onPressed: () => ref
                      .read(registerFaceControllerProvider.notifier)
                      .registerFace(
                        '',
                        debugImages: state.capturedImages,
                      ),
                  label: const Text('DEBUG: Gửi lại ảnh cũ'),
                  icon: const Icon(Icons.bug_report),
                ),
              ),
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
            Text(message,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 80),
              const SizedBox(height: 24),
              const Text('Lỗi đăng ký!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(registerFaceControllerProvider.notifier)
                      .initializeCamera(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appBarOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Thử lại từ đầu'),
                ),
              ),
              const SizedBox(height: 12),
              // Nút test nhanh khi có dữ liệu cũ
              if (ref
                      .read(registerFaceControllerProvider)
                      .capturedImages
                      .length ==
                  5)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(registerFaceControllerProvider.notifier)
                        .registerFace(
                          'STU_RETRY_${DateTime.now().millisecondsSinceEpoch}',
                        ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.appBarOrange),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Thử gửi lại dữ liệu cũ'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text('Đăng ký thành công!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Dữ liệu khuôn mặt đã được cập nhật.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appBarOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text('Hoàn tất'),
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
        registerFaceControllerProvider.select((s) => s.cameraController));
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
    final status =
        ref.watch(registerFaceControllerProvider.select((s) => s.status));
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
        registerFaceControllerProvider.select((s) => s.capturedPoses.length));
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
                color: Colors.black45, borderRadius: BorderRadius.circular(20)),
            child: Text('$count/5',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
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
                color: color, fontSize: 20, fontWeight: FontWeight.bold),
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
        center: center, width: size.width * 0.72, height: size.width * 1.0);
    final ovalPath = Path()..addOval(ovalRect);

    canvas.drawPath(
        Path.combine(
            PathOperation.difference,
            Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
            ovalPath),
        paint);
    canvas.drawOval(
        ovalRect,
        Paint()
          ..color = isValid ? Colors.green : Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0);
  }

  @override
  bool shouldRepaint(SimpleOvalPainter old) => old.isValid != isValid;
}

class _GlassesWarningWidget extends ConsumerWidget {
  const _GlassesWarningWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWearingGlasses = ref.watch(
        registerFaceControllerProvider.select((s) => s.isWearingGlasses));

    if (!isWearingGlasses) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.black, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Phát hiện đang đeo kính',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Text(
                    'Vui lòng tháo kính để đảm bảo độ chính xác khi điểm danh.',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
