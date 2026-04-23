import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import 'proctor_face_checkin_controller.dart';
import 'proctor_face_checkin_state.dart';

class ProctorFaceCheckInPage extends ConsumerStatefulWidget {
  const ProctorFaceCheckInPage({
    super.key,
    required this.examSessionId,
  });

  final String examSessionId;

  @override
  ConsumerState<ProctorFaceCheckInPage> createState() =>
      _ProctorFaceCheckInPageState();
}

class _ProctorFaceCheckInPageState
    extends ConsumerState<ProctorFaceCheckInPage> {
  Future<void> _shutdownCamera() async {
    await ref
        .read(
            proctorFaceCheckInControllerProvider(widget.examSessionId).notifier)
        .shutdown();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(proctorFaceCheckInControllerProvider(widget.examSessionId)
              .notifier)
          .initializeCamera();
    });
  }

  @override
  void dispose() {
    _shutdownCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = proctorFaceCheckInControllerProvider(widget.examSessionId);
    final state = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      if (next.status == ProctorFaceCheckInStatus.success &&
          previous?.status != ProctorFaceCheckInStatus.success) {
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    });

    if (state.status == ProctorFaceCheckInStatus.success) {
      return _buildResultScreen(
        success: true,
        title: _text(
          context,
          vi: 'Điểm danh giám thị thành công',
          en: 'Proctor check-in successful',
        ),
        message: _text(
          context,
          vi: 'Đã ghi nhận giám thị vào phòng thi.',
          en: 'The proctor has been marked as present in the exam room.',
        ),
      );
    }

    if (state.status == ProctorFaceCheckInStatus.failed ||
        state.status == ProctorFaceCheckInStatus.error) {
      return _buildErrorScreen(context, state);
    }

    if (state.status == ProctorFaceCheckInStatus.checkingIn) {
      return _buildProcessingScreen(
        _text(
          context,
          vi: 'Đang xác thực giám thị...',
          en: 'Verifying proctor...',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CameraPreviewWidget(examSessionId: widget.examSessionId),
            const _OvalOverlayWidget(),
            _HeaderWidget(
              title: _text(
                context,
                vi: 'Giám thị vào phòng thi',
                en: 'Proctor exam-room check-in',
              ),
            ),
            if (state.status == ProctorFaceCheckInStatus.livenessCheck)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: _BlinkHint(
                    text: state.instructionMessage.isNotEmpty
                        ? state.instructionMessage
                        : _text(
                            context,
                            vi: 'Nháy mắt để tiếp tục',
                            en: 'Blink to continue',
                          ),
                  ),
                ),
              ),
            _InstructionWidget(state: state),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingScreen(String message) {
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

  Widget _buildResultScreen({
    required bool success,
    required String title,
    required String message,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: success ? Colors.green : Colors.red,
                size: 96,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
    BuildContext context,
    ProctorFaceCheckInState state,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 100),
              const SizedBox(height: 24),
              Text(
                _text(
                  context,
                  vi: 'Điểm danh giám thị thất bại',
                  en: 'Proctor check-in failed',
                ),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ??
                    _text(
                      context,
                      vi: 'Vui lòng thử lại.',
                      en: 'Please try again.',
                    ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(proctorFaceCheckInControllerProvider(
                              widget.examSessionId)
                          .notifier)
                      .retry(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appBarOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(_text(context, vi: 'Thử lại', en: 'Retry')),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(_text(context, vi: 'Quay lại', en: 'Back')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _text(BuildContext context, {required String vi, required String en}) {
    final isVietnamese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');
    return isVietnamese ? vi : en;
  }
}

class _CameraPreviewWidget extends ConsumerWidget {
  const _CameraPreviewWidget({required this.examSessionId});

  final String examSessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(
      proctorFaceCheckInControllerProvider(examSessionId)
          .select((s) => s.cameraController),
    );
    if (controller != null && controller.value.isInitialized) {
      return Center(child: CameraPreview(controller));
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}

class _OvalOverlayWidget extends StatelessWidget {
  const _OvalOverlayWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OvalPainter(),
    );
  }
}

class _OvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    final center = Offset(size.width / 2, size.height * 0.42);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.75,
      height: size.width * 1.05,
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
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _InstructionWidget extends StatelessWidget {
  const _InstructionWidget({required this.state});

  final ProctorFaceCheckInState state;

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    switch (state.status) {
      case ProctorFaceCheckInStatus.scanning:
        message = state.instructionMessage.isNotEmpty
            ? state.instructionMessage
            : _text(
                context,
                vi: 'Đưa khuôn mặt vào khung hình',
                en: 'Put your face in the frame',
              );
        icon = Icons.face;
        color = Colors.white;
        break;
      case ProctorFaceCheckInStatus.livenessCheck:
        message = state.instructionMessage.isNotEmpty
            ? state.instructionMessage
            : _text(
                context,
                vi: 'Nháy mắt để xác nhận',
                en: 'Blink to verify',
              );
        icon = Icons.remove_red_eye;
        color = Colors.orangeAccent;
        break;
      case ProctorFaceCheckInStatus.faceDetected:
        message = state.instructionMessage.isNotEmpty
            ? state.instructionMessage
            : _text(
                context,
                vi: 'Giữ yên /',
                en: 'Hold still ${state.stableCount}/${state.requiredStableFrames}',
              );
        icon = Icons.check_circle;
        color = Colors.greenAccent;
        break;
      default:
        message = '';
        icon = Icons.face;
        color = Colors.white;
    }

    return Positioned(
      bottom: 80,
      left: 40,
      right: 40,
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _text(BuildContext context, {required String vi, required String en}) {
    final isVietnamese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');
    return isVietnamese ? vi : en;
  }
}

class _BlinkHint extends StatelessWidget {
  const _BlinkHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.orangeAccent, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_red_eye,
              color: Colors.orangeAccent, size: 28),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
