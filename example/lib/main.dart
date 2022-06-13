import 'dart:math';

import 'package:bitmap_canvas/bitmap_canvas.dart';
import 'package:flutter/material.dart';

// TODO: If I change the scale of the BitmapPaint and hot reload, the
// scale doesn't update. I have to hot restart.

// TODO: add option to pause rendering when the widget is off-screen.
// Use visibility_detector 0.3.3

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Wrap(
            spacing: 48,
            runSpacing: 48,
            children: [
              for (int i = 0; i < 5; i += 1) //
                const BitmapCanvasDemo(),
            ],
          ),
        ),
      ),
    ),
  );
}

class BitmapCanvasDemo extends StatefulWidget {
  const BitmapCanvasDemo({Key? key}) : super(key: key);

  @override
  State createState() => _BitmapCanvasDemoState();
}

class _BitmapCanvasDemoState extends State<BitmapCanvasDemo> implements BitmapPainter {
  final _frameTimes = <Duration>[];
  int _frameRate = 0;

  @override
  Future<void> paint(BitmapPaintingContext paintingContext) async {
    if (mounted) {
      setState(() {
        _frameTimes.add(paintingContext.timeSinceLastFrame);
        final millisPerFrame =
            _frameTimes.fold<double>(0, (sum, frameTime) => sum + frameTime.inMilliseconds) / _frameTimes.length;
        if (millisPerFrame > 0) {
          _frameRate = (1000 / millisPerFrame).floor();
        }
      });
    }

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

    // Draw bars at top and bottom
    canvas.drawRect(Offset.zero & Size(size.width, 10), Paint()..color = Colors.black);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 10, size.width, 10), Paint()..color = Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BitmapPaint(
          size: const Size(100, 100),
          painter: this,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black.withOpacity(0.5),
            child: Text(
              "$_frameRate FPS",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
