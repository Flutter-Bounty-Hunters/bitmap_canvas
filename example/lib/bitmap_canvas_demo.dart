import 'package:bitmap_canvas/bitmap_canvas.dart';
import 'package:flutter/material.dart';

class BitmapCanvasDemo extends StatefulWidget {
  const BitmapCanvasDemo({
    Key? key,
    required this.bitmapPainter,
  }) : super(key: key);

  final BitmapPainter bitmapPainter;

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

    await widget.bitmapPainter.paint(paintingContext);

    // Draw bars at top and bottom
    final canvas = paintingContext.canvas;
    final size = paintingContext.size;
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
          playbackMode: PlaybackMode.continuous,
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
