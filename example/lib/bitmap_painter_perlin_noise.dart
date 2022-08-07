import 'dart:math';
import 'dart:ui';

import 'package:bitmap_canvas/bitmap_canvas.dart';
import 'package:fast_noise/fast_noise.dart';

class PerlinNoisePainter implements BitmapPainter {
  final int _perlinNoiseSeed = 1337;
  int _perlinNoiseOctaves = 4;
  double _perlinNoiseFalloff = 0.5;
  PerlinNoise? _perlinNoise;

  double z = 0.0;

  @override
  Future<void> paint(BitmapPaintingContext paintingContext) async {
    await paintingContext.canvas.startBitmapTransaction();

    noiseDetail(octaves: 8);

    const increment = 1.5;
    double x = 0;
    double y = 0;
    for (int col = 0; col < paintingContext.size.width; col += 1) {
      for (int row = 0; row < paintingContext.size.height; row += 1) {
        // final grayAmount = s.random(0, 256).floor();

        final perlinNoiseValue = noise(x: x, y: y, z: z);
        final grayAmount = (((perlinNoiseValue + 1.0) / 2.0) * 255).round();

        final color = Color.fromARGB(255, grayAmount, grayAmount, grayAmount);

        paintingContext.canvas.set(x: col, y: row, color: color);

        y += increment;
      }
      x += increment;
      y = 0;
    }

    await paintingContext.canvas.endBitmapTransaction();

    z += 50 / max(paintingContext.timeSinceLastFrame.inMilliseconds, 1);
  }

  void noiseDetail({
    int? octaves,
    double? falloff,
  }) {
    _perlinNoiseOctaves = octaves ?? 4;
    _perlinNoiseFalloff = falloff ?? 0.5;

    _initializePerlinNoise();
  }

  double noise({
    required double x,
    double y = 0,
    double z = 0,
  }) {
    if (_perlinNoise == null) {
      _initializePerlinNoise();
    }

    return _perlinNoise!.getPerlin3(x, y, z);
  }

  void _initializePerlinNoise() {
    _perlinNoise = PerlinNoise(
      seed: _perlinNoiseSeed,
      octaves: _perlinNoiseOctaves,
      gain: _perlinNoiseFalloff,
    );
  }
}
