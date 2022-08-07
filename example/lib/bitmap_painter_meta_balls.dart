import 'dart:math';

import 'package:bitmap_canvas/bitmap_canvas.dart';
import 'package:flutter/material.dart';

class MetaBallsPainter implements BitmapPainter {
  MetaBallsPainter() {
    const width = 100;
    const height = 100;
    final random = Random();
    for (int i = 0; i < _blobCount; i += 1) {
      _blobs.add(
        Blob(
          offset: Offset(random.nextDouble() * width, random.nextDouble() * height),
          velocity: Offset.fromDirection(random.nextDouble() * (2 * pi), _blobSpeed),
          radius: _blobRadius,
        ),
      );
    }
  }

  final _blobCount = 3;
  final _blobRadius = 10.0;
  final _blobSpeed = 1.0;

  final _blobs = <Blob>[];

  @override
  Future<void> paint(BitmapPaintingContext paintingContext) async {
    final width = paintingContext.size.width;
    final height = paintingContext.size.height;

    paintingContext.canvas.drawRect(
      Offset.zero & paintingContext.size,
      Paint()..color = Colors.black,
    );

    await paintingContext.canvas.startBitmapTransaction();

    for (int col = 0; col < width; col += 1) {
      for (int row = 0; row < height; row += 1) {
        double sum = 0;
        for (final blob in _blobs) {
          final distance = (Offset(col.toDouble(), row.toDouble()) - blob.offset).distance;

          // Add to brightness
          sum += 0.75 * blob._radius / distance;

          // Colors
          // sum += 50 * blob.radius / distance;
        }

        // Brightness
        paintingContext.canvas
            .set(x: col, y: row, color: HSVColor.fromAHSV(1.0, 0.0, 0.0, sum.clamp(0.0, 1.0)).toColor());

        // Colors
        // set(x: col, y: row, color: HSVColor.fromAHSV(1.0, sum % 360, 1.0, 1.0).toColor());
      }
    }

    await paintingContext.canvas.endBitmapTransaction();

    final screenSize = Size(width.toDouble(), height.toDouble());
    for (final blob in _blobs) {
      blob.move(screenSize);
      // blob.paint(this);
    }
  }
}

class Blob {
  Blob({
    required Offset offset,
    required Offset velocity,
    required double radius,
  })  : _offset = offset,
        _velocity = velocity,
        _radius = radius;

  Offset _offset;
  Offset get offset => _offset;

  Offset _velocity;

  final double _radius;
  double get radius => _radius;

  void move(Size screenSize) {
    if (_offset.dx <= 0 || _offset.dx >= screenSize.width) {
      _velocity = Offset(-_velocity.dx, _velocity.dy);
    }
    if (_offset.dy <= 0 || _offset.dy >= screenSize.height) {
      _velocity = Offset(_velocity.dx, -_velocity.dy);
    }

    _offset += _velocity;
  }

  void paint(Canvas canvas) {
    canvas.drawCircle(
      _offset,
      _radius,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }
}
