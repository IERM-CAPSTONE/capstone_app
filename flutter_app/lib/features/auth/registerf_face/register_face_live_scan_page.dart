import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../face_enrollment/enrollment_controller.dart';
import 'register_controller.dart';
import 'register_state.dart';

class RegisterFaceLiveScanPage extends ConsumerStatefulWidget {
  final String? targetStudentCode;
  final String? otp;
  final String? retentionPolicy;
  final bool showCompletionInfo;

  const RegisterFaceLiveScanPage({
    super.key,
    this.targetStudentCode,
    this.otp,
    this.retentionPolicy,
    this.showCompletionInfo = false,
  });

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
      final controller = ref.read(registerFaceControllerProvider.notifier);
      controller.setTargetStudentCode(widget.targetStudentCode);
      if (widget.otp != null && widget.retentionPolicy != null) {
        controller.setSupervisedEnrollmentContext(
          otp: widget.otp!,
          retentionPolicy: widget.retentionPolicy!,
        );
      }
      controller.initializeCamera();
    });
  }

  @override
  void dispose() {
    _shutdownCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerFaceControllerProvider);

    if (state.status == FaceScanStatus.completed) {
      return _buildCompletedScreen(context, state);
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
    final isVietnamese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');

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
                isVietnamese ? 'Lỗi đăng ký!' : 'Registration failed!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isVietnamese
                    ? 'Đăng ký khuôn mặt không thành công. Vui lòng thử lại từ đầu.'
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
                    isVietnamese ? 'Thử lại từ đầu' : 'Start over',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedScreen(BuildContext context, RegisterFaceState state) {
    final isVietnamese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');
    final student = state.registeredStudent;
    final bool isStaffTargeted =
        widget.targetStudentCode != null && widget.targetStudentCode!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                (isStaffTargeted || state.pendingEnrollmentId == null)
                    ? Icons.check_circle
                    : Icons.hourglass_top,
                color: (isStaffTargeted || state.pendingEnrollmentId == null)
                    ? Colors.green
                    : AppColors.appBarOrange,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                isVietnamese
                    ? (isStaffTargeted || state.pendingEnrollmentId == null)
                        ? 'Đăng ký thành công!'
                        : 'Đã gửi yêu cầu duyệt'
                    : (isStaffTargeted || state.pendingEnrollmentId == null)
                        ? 'Registration successful!'
                        : 'Waiting for approval',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isVietnamese
                    ? (isStaffTargeted || state.pendingEnrollmentId == null)
                        ? 'Dữ liệu khuôn mặt đã được cập nhật.'
                        : 'Vui lòng chờ giám thị phê duyệt để hoàn tất.'
                    : (isStaffTargeted || state.pendingEnrollmentId == null)
                        ? 'Face data has been updated.'
                        : 'Please wait for supervisor approval.',
                style: const TextStyle(color: Colors.black54),
              ),
              if (widget.showCompletionInfo && student != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVietnamese ? 'Thông tin' : 'Information',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Code: ${student.code ?? '-'}'),
                      const SizedBox(height: 8),
                      Text('Name: ${student.fullName ?? student.code ?? '-'}'),
                      const SizedBox(height: 8),
                      Text(
                        isVietnamese
                            ? 'Trạng thái: ${student.created ? 'Vừa tạo mới' : 'Đã ghi đè dữ liệu hiện có'}'
                            : 'Status: ${student.created ? 'Created now' : 'Existing data overwritten'}',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  final pendingId = state.pendingEnrollmentId;
                  if (!isStaffTargeted && pendingId != null) {
                    ref
                        .read(enrollmentControllerProvider.notifier)
                        .startWaiting(enrollmentId: pendingId);
                    // No longer showing EnrollmentWaitingPage, stay on completion screen
                    // or pop to root as this registration is now supervised and pending.
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    return;
                  }

                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appBarOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: Text(
                  (isStaffTargeted || state.pendingEnrollmentId == null)
                      ? (isVietnamese ? 'Hoàn tất' : 'Complete')
                      : (isVietnamese ? 'Chờ duyệt' : 'Wait for approval'),
                ),
              ),
            ],
          ),
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
    final targetStudentCode = ref.watch(
      registerFaceControllerProvider.select((s) => s.targetStudentCode),
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
          if (targetStudentCode != null && targetStudentCode.isNotEmpty)
            Expanded(
              child: Text(
                targetStudentCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
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
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
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

    final isVietnamese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_off, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isVietnamese
                    ? 'Vui lòng tháo kính để hệ thống nhận diện chính xác hơn.'
                    : 'Please remove glasses so the system can detect the face more accurately.',
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
