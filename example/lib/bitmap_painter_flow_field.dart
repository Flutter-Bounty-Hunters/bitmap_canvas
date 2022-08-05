import 'dart:math';

import 'package:bitmap_canvas/bitmap_canvas.dart';
import 'package:fast_noise/fast_noise.dart';
import 'package:flutter/material.dart';

class FlowFieldDemo extends StatefulWidget {
  const FlowFieldDemo({Key? key}) : super(key: key);

  @override
  State<FlowFieldDemo> createState() => _FlowFieldBitmapPainterState();
}

class _FlowFieldBitmapPainterState extends State<FlowFieldDemo> implements BitmapPainter {
  static const _pixelsPerFlowGrid = 10;
  static const _particleCount = 50;

  late List<List<Offset>> _flowField;
  late List<_Particle> _particles;
  PerlinNoise? _perlinNoise;
  final int _perlinNoiseSeed = 1337;
  final int _perlinNoiseOctaves = 4;
  final double _perlinNoiseFalloff = 0.5;
  bool _hasPaintedFirstFrame = false;

  @override
  Future<void> paint(BitmapPaintingContext paintingContext) async {
    if (!_hasPaintedFirstFrame) {
      _paintFirstFrame(paintingContext);
    }

    final width = paintingContext.size.width;
    final height = paintingContext.size.height;

    for (final particle in _particles) {
      final flowFieldX = (particle.position.dx.clamp(0, width - 1) / _pixelsPerFlowGrid).floor();
      final flowFieldY = (particle.position.dy.clamp(0, height - 1) / _pixelsPerFlowGrid).floor();
      particle.applyForce(_flowField[flowFieldX][flowFieldY]);
      particle.move();

      // Draw a line between the particles previous position and
      // current position.
      paintingContext.canvas.drawLine(
        particle.previousPosition,
        particle.position,
        Paint()
          ..color = Colors.purpleAccent.withOpacity(0.1)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      // If the particle moved off-screen, move it back on.
      if (particle.left >= width) {
        particle.position = Offset(0, particle.position.dy);
        particle.previousPosition = particle.position;
      }
      if (particle.right <= 0) {
        particle.position = Offset(width, particle.position.dy);
        particle.previousPosition = particle.position;
      }
      if (particle.top >= height) {
        particle.position = Offset(particle.position.dx, 0);
        particle.previousPosition = particle.position;
      }
      if (particle.bottom <= 0) {
        particle.position = Offset(particle.position.dx, height);
        particle.previousPosition = particle.position;
      }
    }
  }

  Future<void> _paintFirstFrame(BitmapPaintingContext paintingContext) async {
    const width = 100;
    const height = 100;
    final cols = (width / _pixelsPerFlowGrid).round();
    final rows = (height / _pixelsPerFlowGrid).round();

    _flowField = List<List<Offset>>.generate(
      cols,
      (_) => List<Offset>.filled(
        rows,
        const Offset(0, 0),
      ),
    );
    for (int y = 0; y < rows; y += 1) {
      for (int x = 0; x < cols; x += 1) {
        final flowFieldVector = Offset.fromDirection(
          // Change the "z" value to get a different flow field pattern.
          noise(x: x * 1, y: y * 1, z: 0) * 2 * pi,
        );

        _flowField[x][y] = flowFieldVector;
      }
    }

    _particles = <_Particle>[];
    for (int i = 0; i < _particleCount; i += 1) {
      _particles.add(
        _Particle(
          position: Offset(random(0, width), random(0, height)),
          velocity: Offset.fromDirection(random(0, pi * 2) * 1),
          maxSpeed: 1,
        ),
      );
    }

    paintingContext.canvas.drawRect(
      Offset.zero & paintingContext.size,
      Paint()..color = Colors.deepPurple,
    );

    _hasPaintedFirstFrame = true;
  }

  double random(num bound1, [num? bound2]) {
    final lowerBound = bound2 != null ? bound1 : 0;
    final upperBound = bound2 ?? bound1;

    if (upperBound < lowerBound) {
      throw Exception('random() lower bound must be less than upper bound');
    }

    return Random().nextDouble() * (upperBound - lowerBound) + lowerBound;
  }

  double noise({
    required double x,
    double y = 0,
    double z = 0,
  }) {
    if (_perlinNoise == null) {
      _initializePerlinNoise();
    }

    return _perlinNoise!.getPerlin3(x, y, z);
  }

  void _initializePerlinNoise() {
    _perlinNoise = PerlinNoise(
      seed: _perlinNoiseSeed,
      octaves: _perlinNoiseOctaves,
      gain: _perlinNoiseFalloff,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BitmapPaint(
      size: const Size(100, 100),
      painter: this,
      playbackMode: PlaybackMode.continuous,
    );
  }
}

class _Particle {
  _Particle({
    required this.position,
    required Offset velocity,
    double maxSpeed = 5.0,
    Offset? acceleration,
  })  : previousPosition = position,
        _velocity = velocity,
        _maxSpeed = maxSpeed,
        _acceleration = acceleration ?? const Offset(0, 0);

  Offset position;
  Offset previousPosition;

  double get left => position.dx - 1;
  double get right => position.dx + 1;
  double get top => position.dy - 1;
  double get bottom => position.dy + 1;

  Offset _velocity;
  final double _maxSpeed;

  Offset _acceleration;

  void move() {
    previousPosition = position;

    _velocity += _acceleration;
    _velocity = _limit(_velocity, _maxSpeed);
    position += _velocity;
    _acceleration = Offset.zero;
  }

  Offset _limit(Offset offset, double maxLength) {
    return Offset(
      maxLength * cos(offset.direction),
      maxLength * sin(offset.direction),
    );
  }

  void applyForce(Offset force) {
    _acceleration += force;
  }
}
