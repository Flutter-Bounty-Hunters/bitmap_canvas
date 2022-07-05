import 'dart:typed_data';
import 'dart:ui';

import 'package:bitmap_canvas/src/logging.dart';
import 'package:flutter/widgets.dart';

/// A painting canvas that includes standard [Canvas] vector operations,
/// as well as bitmap operations.
///
/// Clients must adhere to the lifecycle contract of this object.
///
/// **Start a new image:**
/// To begin painting a new image, call [startRecording()], which prepares a new
/// image for painting.
///
/// **Paint desired content:**
/// Vector commands run on the GPU. Pixel painting commands run on the CPU.
/// As a result, these commands must be issued in phases.
///
/// When you want to start painting pixels, call [startBitmapTransaction].
///
/// When you want to shift from pixel painting to vector commands, call
/// [endBitmapTransaction].
///
/// **Produce the final image:**
/// To produce an image that you can access, call [finishRecording()]. The resulting image
/// is available in [publishedImage].
///
/// You can display the [publishedImage] in a widget, save it to a file, or
/// send it over the network.
class BitmapCanvas implements Canvas {
  BitmapCanvas({
    required this.size,
  });

  /// The size of the painting region.
  final Size size;

  /// Backs our [Canvas], producing a [Picture], which produces a bitmap image.
  late PictureRecorder _recorder;

  /// Collects traditional Flutter vector operations, which are painted by
  /// Flutter's rendering system.
  ///
  /// Whenever a bitmap operation is performed after a vector operation, this
  /// canvas is rendered to a bitmap, and then the bitmap operation is applied.
  @visibleForTesting
  Canvas get canvas => _canvas;
  late Canvas _canvas;

  /// Whether this canvas is in the process of painting a frame.
  bool get isDrawing => _isDrawing;
  bool _isDrawing = false;

  /// Bitmap cache that's used to paint pixels during a single painting frame.
  ///
  /// This cache is needed because we have to switch from [Canvas] vector
  /// operations to bitmap operations, which requires a place to perform the
  /// bitmap operations.
  Image? _intermediateImage;

  // TODO: document this (we need it for Flutter Processing)
  ByteData? get pixels => _pixels;
  ByteData? _pixels;

  /// Whether our [_canvas] has operations that have yet to be rasterized to
  /// a our [_intermediateImage].
  bool _hasUnappliedCanvasCommands = false;

  /// Informs this [BitmapCanvas] that there is some number
  /// of [Canvas] commands which have not yet been rasterized to
  /// [_intermediateImage].
  void _markHasUnappliedCanvasCommands() => _hasUnappliedCanvasCommands = true;

  /// The latest image to be produced by this [BitmapPaintingContext].
  Image? get publishedImage => _publishedImage;
  Image? _publishedImage;

  /// Starts a new image.
  void startRecording() {
    canvasLifecycleLog.info("Starting a new recording");
    assert(!isDrawing);

    _isDrawing = true;
    _intermediateImage = null;

    _recorder = PictureRecorder();
    _canvas = Canvas(_recorder);

    // Re-paint the previous frame so that new operations are applied on top.
    if (publishedImage != null) {
      _canvas.drawImage(publishedImage!, Offset.zero, Paint());
    }
  }

  /// Prepares the [BitmapCanvas] to execute a series of bitmap manipulations.
  ///
  /// [startBitmapTransaction] must be called before executing any bitmap
  /// operations. [startBitmapTransaction] rasterizes any outstanding [Canvas]
  /// commands, turning them into pixels, and prepares the pixel buffer for
  /// the bitmap operations that you're about to execute.
  ///
  /// Any traditional [Canvas] operations that you run during a bitmap transaction
  /// will be lost. When you're done with your bitmap operations, call
  /// [endBitmapTransaction] to shift back to the traditional [Canvas] mode.
  // TODO: this method was renamed from loadPixels(). Some uses of loadPixels()
  // might not be the same thing as "starting a bitmap transaction". Figure out
  // if this method should be split into multiple methods for different purposes.
  Future<void> startBitmapTransaction() async {
    canvasLifecycleLog.info("Starting a bitmap transaction");
    if (!_hasUnappliedCanvasCommands && _pixels == null) {
      // There aren't any unapplied canvas commands. Fill the buffer
      // with empty pixels.
      final byteCount = size.width.round() * size.height.round() * 8;
      _pixels = ByteData(byteCount);
      return;
    }

    await _doIntermediateRasterization();

    final sourceImage = (_intermediateImage ?? publishedImage)!;
    _pixels = await sourceImage.toByteData();
  }

  /// Paints the latest [pixels] onto the [canvas].
  ///
  /// This operation is the logical inverse of [startBitmapTransaction].
  // TODO: this method was renamed from udpatePixels(). Some uses of updatePixels()
  // might not be the same thing as "starting a bitmap transaction". Figure out
  // if this method should be split into multiple methods for different purposes.
  Future<void> endBitmapTransaction() async {
    canvasLifecycleLog.info("Ending a bitmap transaction");
    if (_pixels == null) {
      // No pixels to paint.
      canvasLifecycleLog.fine(" - No pixels to paint");
      return;
    }

    canvasLifecycleLog.finer("Encoding pixels to codec");
    final pixelsCodec = await ImageDescriptor.raw(
      await ImmutableBuffer.fromUint8List(_pixels!.buffer.asUint8List()),
      width: size.width.round(),
      height: size.height.round(),
      pixelFormat: PixelFormat.rgba8888,
    ).instantiateCodec();

    canvasLifecycleLog.finer("Encoding image into single frame");
    final pixelsImage = (await pixelsCodec.getNextFrame()).image;

    canvasLifecycleLog.finer("Drawing image to canvas");
    _canvas.drawImage(pixelsImage, Offset.zero, Paint());
    _markHasUnappliedCanvasCommands();
  }

  /// Immediately applies any outstanding [canvas] operations to
  /// produce a new [intermediateImage] bitmap.
  Future<void> _doIntermediateRasterization() async {
    canvasLifecycleLog.info("Doing an intermediate rasterization");
    if (!_hasUnappliedCanvasCommands && _pixels != null) {
      // There are no commands to rasterize
      canvasLifecycleLog.fine(" - nothing to rasterize right now");
      return;
    }

    _intermediateImage = await _rasterize();

    _recorder = PictureRecorder();
    _canvas = Canvas(_recorder)..drawImage(_intermediateImage!, Offset.zero, Paint());

    _hasUnappliedCanvasCommands = false;
    canvasLifecycleLog.fine("Done with intermediate rasterization");
  }

  /// Produces a new [publishedImage] based on all the commands that were
  /// run since [startRecording].
  Future<void> finishRecording() async {
    canvasLifecycleLog.info("Finishing the recording");
    if (_recorder.isRecording) {
      _publishedImage = await _rasterize();
    } else {
      _publishedImage = _intermediateImage;
    }
    _isDrawing = false;
  }

  Future<Image> _rasterize() async {
    final picture = _recorder.endRecording();
    return await picture.toImage(size.width.round(), size.height.round());
  }

  /// Returns the color of the pixel at the given ([x],[y]).
  Future<Color> get(int x, int y) async {
    await _doIntermediateRasterization();
    final sourceImage = (_intermediateImage ?? publishedImage)!;

    final pixelDataOffset = _getBitmapPixelOffset(
      imageWidth: sourceImage.width,
      x: x,
      y: y,
    );
    final imageData = await sourceImage.toByteData();
    final rgbaColor = imageData!.getUint32(pixelDataOffset);
    final argbColor = ((rgbaColor & 0x000000FF) << 24) | ((rgbaColor & 0xFFFFFF00) >> 8);
    return Color(argbColor);
  }

  /// Returns the colors of all pixels in the given region, represented as
  /// an [Image].
  ///
  /// The region is defined by a top-left ([x],[y]), a [width], and a [height].
  Future<Image> getRegion({
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    await _doIntermediateRasterization();
    final sourceImage = (_intermediateImage ?? publishedImage)!;

    final sourceData = await sourceImage.toByteData();
    final destinationData = Uint8List(width * height * 4);
    final rowLength = width * 4;

    for (int row = 0; row < height; row += 1) {
      final sourceRowOffset = _getBitmapPixelOffset(
        imageWidth: sourceImage.width,
        x: x,
        y: y + row,
      );
      final destinationRowOffset = _getBitmapPixelOffset(
        imageWidth: width,
        x: 0,
        y: row,
      );

      destinationData.setRange(
        destinationRowOffset,
        destinationRowOffset + rowLength - 1,
        Uint8List.view(sourceData!.buffer, sourceRowOffset, rowLength),
      );
    }

    final codec = await ImageDescriptor.raw(
      await ImmutableBuffer.fromUint8List(destinationData),
      width: width,
      height: height,
      pixelFormat: PixelFormat.rgba8888,
    ).instantiateCodec();

    return (await codec.getNextFrame()).image;
  }

  /// Sets the pixel at the given ([x],[y]) to the given [color].
  void set({
    required int x,
    required int y,
    required Color color,
  }) {
    if (_pixels == null) {
      throw Exception("You must call startBitmapTransaction() before selling set().");
    }

    final pixelIndex = _getBitmapPixelOffset(
      imageWidth: size.width.round(),
      x: x,
      y: y,
    );

    final argbColorInt = color.value;
    final rgbaColorInt = ((argbColorInt & 0xFF000000) >> 24) | ((argbColorInt & 0x00FFFFFF) << 8);
    _pixels!.setUint32(pixelIndex, rgbaColorInt);
  }

  /// Sets all pixels in the given region to the colors specified by the given [image].
  ///
  /// The region is defined by the top-left ([x],[y]) and the width and height of
  /// the given [image].
  Future<void> setRegion({
    required Image image,
    int x = 0,
    int y = 0,
  }) async {
    if (_pixels == null) {
      throw Exception("You must call startBitmapTransaction() before selling setRegion().");
    }

    // In theory, this method should copy each pixel in the given image
    // into the pixels buffer. But, it's easier for us to utilize the Canvas
    // to accomplish the same thing. To use the Canvas, we must first ensure
    // that any intermediate values in the pixels buffer are applied back to
    // the intermediate image. For example, if the user called set() on any
    // pixels but has not yet called endBitmapTransaction(), those pixels would be
    // lost during an intermediate rasterization. Therefore, the first thing
    // we do is endBitmapTransaction().
    await endBitmapTransaction();

    // Use the Canvas to draw the given image at the desired offset.
    _canvas.drawImage(image, Offset.zero, Paint());
    _markHasUnappliedCanvasCommands();

    // Rasterize the Canvas image command and load the latest image data
    // into the pixels buffer.
    await startBitmapTransaction();
  }

  int _getBitmapPixelOffset({
    required int imageWidth,
    required int x,
    required int y,
  }) {
    return ((y * imageWidth) + x) * 4;
  }

  //---- START Canvas delegations ---
  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {
    _canvas.clipPath(path, doAntiAlias: doAntiAlias);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {
    _canvas.clipRRect(rrect, doAntiAlias: doAntiAlias);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void clipRect(Rect rect, {ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true}) {
    _canvas.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint) {
    _canvas.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawAtlas(Image atlas, List<RSTransform> transforms, List<Rect> rects, List<Color>? colors, BlendMode? blendMode,
      Rect? cullRect, Paint paint) {
    _canvas.drawAtlas(atlas, transforms, rects, colors, blendMode, cullRect, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    _canvas.drawCircle(center, radius, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawColor(Color color, BlendMode blendMode) {
    _canvas.drawColor(color, blendMode);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    _canvas.drawDRRect(outer, inner, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawImage(Image image, Offset offset, Paint paint) {
    _canvas.drawImage(image, offset, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawImageNine(Image image, Rect center, Rect dst, Paint paint) {
    _canvas.drawImageNine(image, center, dst, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint) {
    _canvas.drawImageRect(image, src, dst, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    _canvas.drawLine(p1, p2, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawOval(Rect rect, Paint paint) {
    _canvas.drawOval(rect, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawPaint(Paint paint) {
    _canvas.drawPaint(paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    _canvas.drawParagraph(paragraph, offset);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawPath(Path path, Paint paint) {
    _canvas.drawPath(path, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawPicture(Picture picture) {
    _canvas.drawPicture(picture);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint) {
    _canvas.drawPoints(pointMode, points, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    _canvas.drawRRect(rrect, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawRawAtlas(Image atlas, Float32List rstTransforms, Float32List rects, Int32List? colors, BlendMode? blendMode,
      Rect? cullRect, Paint paint) {
    _canvas.drawRawAtlas(atlas, rstTransforms, rects, colors, blendMode, cullRect, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {
    _canvas.drawRawPoints(pointMode, points, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    _canvas.drawRect(rect, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawShadow(Path path, Color color, double elevation, bool transparentOccluder) {
    _canvas.drawShadow(path, color, elevation, transparentOccluder);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {
    _canvas.drawVertices(vertices, blendMode, paint);
    _markHasUnappliedCanvasCommands();
  }

  @override
  int getSaveCount() {
    return _canvas.getSaveCount();
  }

  @override
  void restore() {
    _canvas.restore();
  }

  @override
  void rotate(double radians) {
    _canvas.rotate(radians);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void save() {
    _canvas.save();
  }

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    _canvas.saveLayer(bounds, paint);
  }

  @override
  void scale(double sx, [double? sy]) {
    _canvas.scale(sx, sy);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void skew(double sx, double sy) {
    _canvas.skew(sx, sy);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void transform(Float64List matrix4) {
    _canvas.transform(matrix4);
    _markHasUnappliedCanvasCommands();
  }

  @override
  void translate(double dx, double dy) {
    _canvas.translate(dx, dy);
    _markHasUnappliedCanvasCommands();
  }
  //---- END Canvas delegations ---
}
