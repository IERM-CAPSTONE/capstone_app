import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'face_authenticate_controller.dart';
import 'face_authenticate_state.dart';

class FaceAuthenticatePage extends ConsumerStatefulWidget {
  const FaceAuthenticatePage({super.key});

  @override
  ConsumerState<FaceAuthenticatePage> createState() =>
      _FaceAuthenticatePageState();
}

class _FaceAuthenticatePageState extends ConsumerState<FaceAuthenticatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(faceAuthenticateControllerProvider.notifier).initializeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faceAuthenticateControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (state.cameraController != null &&
              state.cameraController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / state.cameraController!.value.aspectRatio,
                child: CameraPreview(state.cameraController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.blue)),

          // Oval Overlay
          const _OvalOverlayWidget(),

          // Header
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Blink Guidance Animation
          if (state.status == FaceAuthenticateStatus.livenessCheck)
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 120),
                child: _BlinkGuidance(),
              ),
            ),

          // Bottom Info
          _BottomInfoWidget(state: state),

          // Success/Failed Overlays
          if (state.status == FaceAuthenticateStatus.authenticated)
            _ResultOverlay(
              isSuccess: true,
              studentName: state.studentName,
              studentCode: state.studentCode,
              confidence: state.confidence,
            ),
          if (state.status == FaceAuthenticateStatus.failed)
            const _ResultOverlay(isSuccess: false),
        ],
      ),
    );
  }
}

class _OvalOverlayWidget extends StatelessWidget {
  const _OvalOverlayWidget();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.5),
          BlendMode.srcOut,
        ),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                backgroundBlendMode: BlendMode.dstOut,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.only(bottom: 50),
                height: 380,
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.elliptical(280, 380)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomInfoWidget extends ConsumerWidget {
  final FaceAuthenticateState state;

  const _BottomInfoWidget({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(state.status).withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              state.instructionMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (state.status == FaceAuthenticateStatus.failed ||
              state.status == FaceAuthenticateStatus.error)
            ElevatedButton(
              onPressed: () =>
                  ref.read(faceAuthenticateControllerProvider.notifier).retry(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Thử lại'),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(FaceAuthenticateStatus status) {
    switch (status) {
      case FaceAuthenticateStatus.scanning:
        return Colors.grey;
      case FaceAuthenticateStatus.faceDetected:
        return Colors.blue;
      case FaceAuthenticateStatus.livenessCheck:
        return Colors.orange;
      case FaceAuthenticateStatus.authenticating:
        return Colors.purple;
      case FaceAuthenticateStatus.authenticated:
        return Colors.green;
      case FaceAuthenticateStatus.failed:
        return Colors.red;
      case FaceAuthenticateStatus.error:
        return Colors.red;
    }
  }
}

class _ResultOverlay extends StatelessWidget {
  final bool isSuccess;
  final String? studentName;
  final String? studentCode;
  final double? confidence;

  const _ResultOverlay({
    required this.isSuccess,
    this.studentName,
    this.studentCode,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'XÁC THỰC THÀNH CÔNG' : 'XÁC THỰC THẤT BẠI',
                style: TextStyle(
                  color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (isSuccess) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        studentName ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MSSV: ${studentCode ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                      ),
                      if (confidence != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Độ tin cậy: ${(confidence! * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.greenAccent.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkGuidance extends StatefulWidget {
  const _BlinkGuidance();

  @override
  State<_BlinkGuidance> createState() => _BlinkGuidanceState();
}

class _BlinkGuidanceState extends State<_BlinkGuidance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.remove_red_eye,
            color: Colors.orangeAccent,
            size: 80,
          ),
          SizedBox(height: 8),
          Text(
            'Nháy mắt ngay!',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(1, 1),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
