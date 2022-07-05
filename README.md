<p align="center">
  <img src="https://user-images.githubusercontent.com/7259036/173299511-3b031cd5-6232-4804-aa16-be635581dd73.png" width="300" alt="Bitmap Canvas"><br>
  <span><b>Render bitmap pixels with canvas-style APIs.</b></span><br><br>
</p>


> This project is a Flutter Bounty Hunters [proof-of-concept](https://policies.flutterbountyhunters.com/proof-of-concept). Need more capabilities? [Fund a milestone](https://policies.flutterbountyhunters.com/fund-milestone) today!

--- 
`bitmap_canvas` is a package that provides easy-to-use APIs for pixel painting with Dart, along with widgets to easily display those paintings.

## In the wild
`bitmap_canvas` is the renderer for `flutter_processing`.

## Examples
Paint animated static noise, where every pixel has a random brightness.

```dart
Widget build(context) {
  return BitmapPaint(
    size: const Size(100, 100),
    painter: BitmapPainter.fromCallback((bitmapContext) async {
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
    }),
    playbackMode: PlaybackMode.singleFrame,
  );
}
```

## Why do we need a bitmap canvas in Flutter?
Flutter is built on top of SKIA, a portable rendering system, which supports hardware acceleration with shaders. 

You might wonder, if we want to paint individual pixels, shouldn't we use shaders? Software rendering is so slow!

There are a few reasons that you might choose software rendering (i.e., painting pixels with Dart) over shaders:

1. Learning how to paint pixels in Dart is easier than with a shader language, like GLSL.
2. Shaders can't implement every style of pixel painting. For example, any pixel painting where one pixel depends on the value of another pixel is unsupported in shaders.
3. Flutter doesn't fully support custom shaders, which means that most pixel painting behaviors can't be implemented with shaders in Flutter.
