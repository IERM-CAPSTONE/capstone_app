import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  final String title;

  const CameraPage({
    super.key,
    this.title = 'Chụp ảnh',
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Ưu tiên camera sau
      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile picture = await _controller!.takePicture();
      if (!mounted) return;

      // Hiển thị xem trước ảnh đã chụp
      final bool? result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _PreviewPage(file: File(picture.path)),
        ),
      );

      if (result == true && mounted) {
        Navigator.of(context).pop(picture);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // Overlay khung ngắm (Viewfinder overlay)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double height = constraints.maxHeight;
                final double vWidth = width * 0.85;
                final double vHeight = vWidth * 0.75;
                final double left = (width - vWidth) / 2;
                final double top = (height - vHeight) / 2;

                final Color overlayColor = Colors.black.withOpacity(0.5);

                return Stack(
                  children: [
                    // Phía trên khung ngắm
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: top,
                      child: Container(color: overlayColor),
                    ),
                    // Phía dưới khung ngắm
                    Positioned(
                      top: top + vHeight,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(color: overlayColor),
                    ),
                    // Phía bên trái khung ngắm
                    Positioned(
                      top: top,
                      left: 0,
                      width: left,
                      height: vHeight,
                      child: Container(color: overlayColor),
                    ),
                    // Phía bên phải khung ngắm
                    Positioned(
                      top: top,
                      right: 0,
                      width: left,
                      height: vHeight,
                      child: Container(color: overlayColor),
                    ),
                    // Viền khung ngắm
                    Positioned(
                      top: top,
                      left: left,
                      width: vWidth,
                      height: vHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Text hướng dẫn
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: const Text(
              'Đặt sự cố vào giữa khung hình',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 4, color: Colors.black54),
                ],
              ),
            ),
          ),

          // Nút chụp (Shutter button)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isTakingPicture
                          ? const Padding(
                              padding: EdgeInsets.all(15.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);

    final double width = size.width;
    final double height = size.height;
    final double viewfinderWidth = width * 0.85;
    final double viewfinderHeight = viewfinderWidth * 0.75;
    final double cornerRadius = 16.0;

    final rect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: viewfinderWidth,
      height: viewfinderHeight,
    );

    final viewfinderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)));

    // Vẽ lớp phủ mờ bên ngoài
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, width, height)),
        viewfinderPath,
      ),
      paint,
    );

    // Vẽ viền khung ngắm
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
        borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _PreviewPage extends StatelessWidget {
  final File file;

  const _PreviewPage({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Xem trước'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.file(file),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            color: Colors.black87,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Chụp lại'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316), // Màu chủ đạo của app
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Sử dụng ảnh'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
