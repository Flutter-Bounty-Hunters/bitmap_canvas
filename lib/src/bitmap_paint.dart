import 'dart:ui';

import 'package:bitmap_canvas/bitmap_canvas.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' hide Image;

import 'bitmap_canvas.dart';

/// A widget that displays a bitmap that you paint with a [BitmapPainter].
///
/// The [BitmapPaint] widget is very similar to a traditional [CustomPaint]
/// widget, except a [BitmapPaint] delegates painting to a [BitmapPainter].
/// A [BitmapPainter] uses a [BitmapCanvas], which supports traditional
/// [Canvas] operations, as well as bitmap operations, like setting and
/// getting individual pixel colors.
class BitmapPaint extends StatefulWidget {
  const BitmapPaint({
    Key? key,
    required this.painter,
    required this.size,
    this.playbackMode = PlaybackMode.play,
  }) : super(key: key);

  /// Painting delegate, which paints the pixels that are displayed
  /// by this [BitmapPaint].
  final BitmapPainter painter;

  /// The size of the painting that's displayed in this [BitmapPaint].
  ///
  /// Every time the [size] changes, the underlying bitmap caches are
  /// regenerated to fit the new size. This is a costly operation. Therefore,
  /// you should only change a [BitmapPaint]'s [size] when absolutely
  /// necessary.
  final Size size;

  /// The playback mode for the [BitmapPaint], e.g., paint a single frame,
  /// paint continuously, or pause painting.
  final PlaybackMode playbackMode;

  @override
  State createState() => _BitmapPaintState();
}

class _BitmapPaintState extends State<BitmapPaint> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastFrameTime = Duration.zero;

  late BitmapCanvas _bitmapCanvas;
  Image? _currentImage;

  @override
  void initState() {
    super.initState();

    _bitmapCanvas = BitmapCanvas(size: widget.size);

    _ticker = createTicker(_onTick);
    if (widget.playbackMode != PlaybackMode.pause) {
      _startTicking();
    }
  }

  @override
  void didUpdateWidget(BitmapPaint oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.playbackMode != oldWidget.playbackMode) {
      if (widget.playbackMode == PlaybackMode.play && !_ticker.isTicking) {
        _startTicking();
      } else if (widget.playbackMode != PlaybackMode.play && _ticker.isTicking) {
        _ticker.stop();
      }
    }

    if (widget.size != oldWidget.size) {
      _bitmapCanvas = BitmapCanvas(size: widget.size);

      // We always want to repaint at least one frame when the size
      // changes, because the new size is incompatible with our last
      // image size.
      if (!_ticker.isTicking) {
        _startTicking();
      }
      // TODO: write a test that makes sure a singleFrame playback mode repaints when size changes
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startTicking() {
    _lastFrameTime = Duration.zero;
    _ticker.start();
  }

  bool _isPainting = false;
  Future<void> _onTick(elapsedTime) async {
    if (_isPainting) {
      return;
    }
    _isPainting = true;

    if (widget.playbackMode != PlaybackMode.play) {
      // The playback mode is either "single frame" or "paused".
      // Either way, we don't want to paint another frame after
      // this one.
      _ticker.stop();
    }

    print("Widget: _onTick(): $elapsedTime. BitmapCanvas: ${_bitmapCanvas.hashCode}");
    if (_bitmapCanvas.isDrawing) {
      print("Widget: - drawing in progress. Ignoring.");
      return;
    }

    print("Widget: starting recording");
    _bitmapCanvas.startRecording();

    print("Widget: painting a frame");
    // Ask our delegate to paint a frame. This call may take a while.
    await widget.painter.paint(
      BitmapPaintingContext(
        canvas: _bitmapCanvas,
        size: widget.size,
        elapsedTime: elapsedTime,
        timeSinceLastFrame: elapsedTime - _lastFrameTime,
      ),
    );

    print("Widget: finishing recording");
    await _bitmapCanvas.finishRecording();

    if (mounted) {
      setState(() {
        _lastFrameTime = elapsedTime;
        _currentImage = _bitmapCanvas.publishedImage;
        _isPainting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _currentImage != null
        ? SizedBox.fromSize(
            size: widget.size,
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: SizedBox(
                width: _currentImage!.width.toDouble(),
                height: _currentImage!.height.toDouble(),
                child: RepaintBoundary(
                  child: RawImage(
                    image: _currentImage,
                  ),
                ),
              ),
            ),
          )
        : SizedBox.fromSize(size: widget.size);
  }
}

class BitmapPainter {
  const BitmapPainter.fromCallback(this._paint);

  final Future<void> Function(BitmapPaintingContext)? _paint;

  Future<void> paint(BitmapPaintingContext paintingContext) async {
    if (_paint == null) {
      return;
    }

    _paint!(paintingContext);
  }
}

class BitmapPaintingContext {
  BitmapPaintingContext({
    required this.canvas,
    required this.size,
    required this.elapsedTime,
    required this.timeSinceLastFrame,
  });

  final BitmapCanvas canvas;
  final Size size;
  final Duration elapsedTime;
  final Duration timeSinceLastFrame;
}

/// The playback mode for a [BitmapPaint] widget.
enum PlaybackMode {
  /// Renders only a single frame.
  singleFrame,

  /// Continuously renders frames.
  play,

  /// Doesn't render any frames.
  pause,
}
