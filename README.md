<p align="center">
  <img src="https://user-images.githubusercontent.com/7259036/173299511-3b031cd5-6232-4804-aa16-be635581dd73.png" width="300" alt="Bitmap Canvas"><br>
  <span><b>Render bitmap pixels with canvas-style APIs.</b></span><br><br>
</p>


> This project is a Flutter Bounty Hunters [proof-of-concept](https://policies.flutterbountyhunters.com/proof-of-concept). Need more capabilities? [Fund a milestone](https://policies.flutterbountyhunters.com/fund-milestone) today!

--- 

## In the wild
`bitmap_canvas` provides the core rendering for `flutter_processing`

## Why do we need a bitmap canvas in Flutter?
Flutter is built on top of SKIA, a portable rendering system. Why would we want to add software
bitmap rendering on top of that? There are a couple answers:

1. Learning how to paint pixels is easier with a high-level language, rather than shader languages.
2. At the time of writing, Flutter does not fully support custom shaders, making many bitmap operations impossible with SKIA.
