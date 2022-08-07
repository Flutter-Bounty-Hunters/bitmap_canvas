import 'dart:math';

import 'package:bitmap_canvas/bitmap_canvas.dart';
import 'package:flutter/material.dart';

class NoiseBitmapPainter implements BitmapPainter {
  @override
  Future<void> paint(BitmapPaintingContext paintingContext) async {
    final canvas = paintingContext.canvas;
    final size = paintingContext.size;
    final random = Random();
    await canvas.startBitmapTransaction();
    for (int x = 0; x < size.width; x += 1) {
      for (int y = 0; y < size.height; y += 1) {
        canvas.set(x: x, y: y, color: HSVColor.fromAHSV(1.0, 0, 0, random.nextDouble()).toColor());
      }
    }
    await canvas.endBitmapTransaction();
  }
}
