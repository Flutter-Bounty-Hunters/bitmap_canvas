import 'package:example/bitmap_painter_flow_field.dart';
import 'package:example/bitmap_painter_meta_balls.dart';
import 'package:flutter/material.dart';

import 'bitmap_painter_white_noise.dart';

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
            children: const [
              BitmapCanvasDemo(),
              FlowFieldDemo(),
              MetaBallsDemo(),
              BitmapCanvasDemo(),
              BitmapCanvasDemo(),
            ],
          ),
        ),
      ),
    ),
  );
}
