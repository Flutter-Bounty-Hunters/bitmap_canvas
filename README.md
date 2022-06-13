# Bitmap Canvas
Render bitmap pixels with canvas-style APIs.

> `bitmap_canvas` supports the core rendering for `flutter_processing`

## Why do we need a bitmap canvas in Flutter?
Flutter is built on top of SKIA, a portable rendering system. Why would we want to add software
bitmap rendering on top of that? There are a couple answers:

1. Learning how to paint pixels is easier with a high-level language, rather than shader languages.
2. At the time of writing, Flutter does not fully support custom shaders, making many bitmap operations impossible with SKIA.
