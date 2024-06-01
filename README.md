<p align="center">
  <img src="https://github.com/Flutter-Bounty-Hunters/bitmap_canvas/assets/7259036/e80bd6ed-973a-4165-819e-73957f061e68" alt="Bitmap Canvas - Render bitmap pixels with canvas-style APIs">
</p>

<p align="center">
  <a href="https://flutterbountyhunters.com" target="_blank">
    <img src="https://github.com/Flutter-Bounty-Hunters/flutter_test_robots/assets/7259036/1b19720d-3dad-4ade-ac76-74313b67a898" alt="Built by the Flutter Bounty Hunters">
  </a>
</p>

--- 
`bitmap_canvas` is a package that provides easy-to-use APIs for pixel painting with Dart, along with widgets to easily display those paintings.

<p align="center">
  <img src="https://user-images.githubusercontent.com/7259036/183281593-b3f4c4e8-3bd4-407a-8844-79c5d2f1482e.gif">
</p>


## In the wild
`bitmap_canvas` is the renderer for `flutter_processing`.

## Examples
Paint animated static noise, where every pixel has a random brightness.

```dart
Widget build(context) {
  // BitmapPaint is like CustomPaint, except that you can paint
  // individual pixels, too.
  return BitmapPaint(
    size: const Size(100, 100),
    painter: BitmapPainter.fromCallback((bitmapContext) async {
      final canvas = paintingContext.canvas;
      final size = paintingContext.size;
      final random = Random();
      
      await canvas.startBitmapTransaction();
      
      for (int x = 0; x < size.width; x += 1) {
        for (int y = 0; y < size.height; y += 1) {
          // This is where we paint an individual pixel.
          canvas.set(x: x, y: y, color: HSVColor.fromAHSV(1.0, 0, 0, random.nextDouble()).toColor());
        }
      }
      
      await canvas.endBitmapTransaction();
    }),
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
