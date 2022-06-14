<p align="center">
  <img src="https://user-images.githubusercontent.com/7259036/173299511-3b031cd5-6232-4804-aa16-be635581dd73.png" width="300" alt="Bitmap Canvas"><br>
  <span><b>Render bitmap pixels with canvas-style APIs.</b></span><br><br>
</p>


> This project is a Flutter Bounty Hunters [proof-of-concept](https://policies.flutterbountyhunters.com/proof-of-concept). Need more capabilities? [Fund a milestone](https://policies.flutterbountyhunters.com/fund-milestone) today!

--- 

## In the wild
`bitmap_canvas` provides the core rendering for `flutter_processing`

## Why do we need a bitmap canvas in Flutter?
Flutter is built on top of SKIA, a portable rendering system, which supports hardware acceleration with shaders. If we want to paint individual pixels, shouldn't we use shaders? Software rendering is so slow!

There are a few reasons that you might choose software rendering (i.e., painting pixels with Dart):

1. Learning how to paint pixels is easier with Dart than it is with a shader language, like GLSL.
2. Some pixel painting behaviors can't be implemented with shaders, in general.
3. At the time of writing, Flutter does not fully support custom shaders, which means that presently, most pixel painting behaviors can't be implemented with shaders in Flutter.

`bitmap_canvas` is a package that provides easy-to-use APIs for pixel painting with Dart, along with widgets to easily display those paintings.
