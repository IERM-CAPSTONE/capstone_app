import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

class GlassesDetectionService {
  bool _isModelLoaded = false;

  /// No external model required for heuristic; mark as ready.
  Future<void> loadModel() async {
    _isModelLoaded = true;
    return;
  }

  /// Lightweight heuristic to estimate whether a cropped face image
  /// contains eyeglass frames. Works on the assumption that glasses
  /// produce more strong horizontal/vertical edges in the eye region.
  /// Returns true when glasses are likely present.
  Future<bool> detectGlasses(File faceCrop) async {
    if (!_isModelLoaded) return false;

    try {
      final bytes = await faceCrop.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      final w = image.width;
      final h = image.height;

      // Define approximate eye region (upper-central part of face crop)
      final top = (h * 0.18).toInt().clamp(0, h - 1);
      final bottom = (h * 0.55).toInt().clamp(0, h - 1);
      final left = (w * 0.12).toInt().clamp(0, w - 1);
      final right = (w * 0.88).toInt().clamp(0, w - 1);

      var strongEdgeCount = 0;
      var total = 0;

      const int edgeThreshold = 30; // per-channel intensity diff
      final int edgeThresholdSq = edgeThreshold * edgeThreshold * 2; // gx^2+gy^2

      for (var y = max(1, top); y < min(h - 1, bottom); y++) {
        for (var x = max(1, left); x < min(w - 1, right); x++) {
          total++;

          final pl = image.getPixel(x - 1, y);
          final prp = image.getPixel(x + 1, y);
          final pu = image.getPixel(x, y - 1);
          final pd = image.getPixel(x, y + 1);

          final double il = 0.299 * pl.r + 0.587 * pl.g + 0.114 * pl.b;
          final double ir = 0.299 * prp.r + 0.587 * prp.g + 0.114 * prp.b;
          final double iu = 0.299 * pu.r + 0.587 * pu.g + 0.114 * pu.b;
          final double id = 0.299 * pd.r + 0.587 * pd.g + 0.114 * pd.b;

          final double gx = ir - il;
          final double gy = id - iu;
          final double magSq = gx * gx + gy * gy;

          if (magSq > edgeThresholdSq) {
            strongEdgeCount++;
          }
        }
      }

      if (total == 0) return false;

      final edgeDensity = strongEdgeCount / total;

      // Debug print
      // print('Glasses heuristic: strongEdge=$strongEdgeCount total=$total density=$edgeDensity');

      // Threshold tuned conservatively; increase if too many false positives
      return edgeDensity > 0.06; // ~6% of pixels in eye region are strong edges
    } catch (e) {
      print('❌ Error during glasses detection heuristic: $e');
      return false;
    }
  }

  void dispose() {}
}
