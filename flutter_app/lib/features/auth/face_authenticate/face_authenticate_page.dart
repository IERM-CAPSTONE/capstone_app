import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'face_authenticate_controller.dart';
import 'face_authenticate_state.dart';
import '../../../l10n/generated/app_localizations.dart';

class FaceAuthenticatePage extends ConsumerStatefulWidget {
  final String? examSessionId;
  const FaceAuthenticatePage({super.key, this.examSessionId});

  @override
  ConsumerState<FaceAuthenticatePage> createState() =>
      _FaceAuthenticatePageState();
}

class _FaceAuthenticatePageState extends ConsumerState<FaceAuthenticatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(faceAuthenticateControllerProvider.notifier)
          .initializeCamera(examSessionId: widget.examSessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faceAuthenticateControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    // If success/failed, show result screen like register_face
    if (state.status == FaceAuthenticateStatus.authenticated) {
      return _buildSuccessScreen(context, state, l10n);
    }

    if (state.status == FaceAuthenticateStatus.failed ||
        state.status == FaceAuthenticateStatus.error) {
      return _buildErrorScreen(context, state, l10n);
    }

    if (state.status == FaceAuthenticateStatus.authenticating) {
      return _buildProcessingScreen(context, l10n.authenticatingFace);
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

            // Blink Animation (unique to authentication)
            if (state.status == FaceAuthenticateStatus.livenessCheck)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: _BlinkGuidance(l10n: l10n),
                ),
              ),

            _InstructionWidget(l10n: l10n),
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

  Widget _buildSuccessScreen(BuildContext context, FaceAuthenticateState state,
      AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              Text(l10n.authSuccessful,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundOrange,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.appBarOrange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      state.studentName ?? 'Anonymous Student',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.appBarOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.studentId}: ${state.studentCode ?? l10n.tba}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (state.confidence != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.confidenceLabel(
                            (state.confidence! * 100).toStringAsFixed(1)),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.complete,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, FaceAuthenticateState state,
      AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 100),
              const SizedBox(height: 24),
              Text(l10n.authFailedTitle,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                _getLocalizedError(state.errorMessage, l10n),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(faceAuthenticateControllerProvider.notifier)
                      .retry(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appBarOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.retry),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.backToMenu,
                    style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedError(String? error, AppLocalizations l10n) {
    if (error == null) return l10n.authFailed;

    // Check for specific backend error messages and map them
    if (error.contains('does not belong to this exam room')) {
      return l10n.notInExamRoom;
    }

    if (error.contains('Face not recognized')) {
      return l10n.faceNotRecognized;
    }

    return error;
  }
}

class _CameraPreviewWidget extends ConsumerWidget {
  const _CameraPreviewWidget();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(
        faceAuthenticateControllerProvider.select((s) => s.cameraController));
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
        ref.watch(faceAuthenticateControllerProvider.select((s) => s.status));

    // Valid if face is detected or in liveness check
    bool isValid = status == FaceAuthenticateStatus.faceDetected ||
        status == FaceAuthenticateStatus.livenessCheck ||
        status == FaceAuthenticateStatus.authenticating;

    return CustomPaint(
      painter: SimpleOvalPainter(isValid: isValid),
    );
  }
}

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget();
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 32),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _InstructionWidget extends ConsumerWidget {
  final AppLocalizations l10n;
  const _InstructionWidget({required this.l10n});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(faceAuthenticateControllerProvider);

    IconData icon = Icons.face;
    Color color = Colors.white;

    if (state.status == FaceAuthenticateStatus.faceDetected ||
        state.status == FaceAuthenticateStatus.authenticating) {
      icon = Icons.check_circle;
      color = Colors.greenAccent;
    } else if (state.status == FaceAuthenticateStatus.livenessCheck) {
      icon = Icons.remove_red_eye;
      color = Colors.orangeAccent;
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
            _getInstructionMessage(state, l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getInstructionMessage(
      FaceAuthenticateState state, AppLocalizations l10n) {
    if (state.status == FaceAuthenticateStatus.scanning) {
      return l10n.putFaceInFrame;
    }
    if (state.status == FaceAuthenticateStatus.faceDetected) {
      if (state.poseStableCount > 0) {
        return l10n.holdStill(
            state.poseStableCount, state.requiredStableFrames);
      }
      return l10n.lookStraight;
    }
    if (state.status == FaceAuthenticateStatus.livenessCheck) {
      return l10n.blinkToAuthenticate;
    }
    if (state.status == FaceAuthenticateStatus.authenticating) {
      return l10n.authenticatingFace;
    }
    if (state.status == FaceAuthenticateStatus.authenticated) {
      return l10n.authSuccessful;
    }
    return '';
  }
}

class SimpleOvalPainter extends CustomPainter {
  final bool isValid;
  SimpleOvalPainter({required this.isValid});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    final center = Offset(size.width / 2, size.height * 0.42);
    final ovalRect = Rect.fromCenter(
        center: center, width: size.width * 0.75, height: size.width * 1.05);
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
          ..color = isValid ? Colors.greenAccent : Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5);
  }

  @override
  bool shouldRepaint(SimpleOvalPainter old) => old.isValid != isValid;
}

class _BlinkGuidance extends StatefulWidget {
  final AppLocalizations l10n;
  const _BlinkGuidance({required this.l10n});

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
      child: Container(
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
              widget.l10n.blinkToContinue,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
