import 'dart:async';
import 'dart:math';

import 'package:bitmap_canvas/src/bitmap_paint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bitmap_canvas/bitmap_canvas.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("BitmapCanvas", () {
    testGoldens("paints random noise", (tester) async {
      await _runAtSize(tester, const Size(100, 100), (tester) async {
        final framePaintCompleter = Completer();

        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: BitmapPaint(
                  size: const Size(100, 100),
                  playbackMode: PlaybackMode.singleFrame,
                  painter: BitmapPainter.fromCallback((paintingContext) async {
                    print("TEST 1: Painting bitmap canvas");
                    final canvas = paintingContext.canvas;
                    final size = paintingContext.size;

                    final random = Random(_randomSeed);
                    print("TEST 2: Starting bitmap transaction");
                    await canvas.startBitmapTransaction();
                    print("TEST 3: Painting pixels");
                    for (int x = 0; x < size.width; x += 1) {
                      for (int y = 0; y < size.height; y += 1) {
                        canvas.set(x: x, y: y, color: HSVColor.fromAHSV(1.0, 0, 0, random.nextDouble()).toColor());
                      }
                    }
                    print("TEST 4: Ending bitmap transaction");
                    await canvas.endBitmapTransaction();

                    print("TEST 5: Done painting a frame");
                    if (!framePaintCompleter.isCompleted) {
                      framePaintCompleter.complete();
                    }
                  }),
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
          ),
        );
        // await tester.pump();
        // await tester.pump();
        // await tester.pump();
        // await tester.pump();
        // await tester.pump();
        // await tester.pump();
        // await tester.pump();
        // await tester.pump();
        await tester.pumpAndSettle();

        print("Waiting for frame paint completer to complete");
        // await framePaintCompleter.future;
        await Future.delayed(const Duration(seconds: 10));

        print("Painting golden");
        await screenMatchesGolden(tester, "random_noise", customPump: (tester) async {
          // no pump-and-settle
        });
      });
    });
  });
}

const _randomSeed = 123456;

Future<void> _runAtSize(WidgetTester tester, Size size, Future<void> Function(WidgetTester) test) async {
  tester.binding.window
    ..physicalSizeTestValue = size
    ..devicePixelRatioTestValue = 1.0;

  await test(tester);

  tester.binding.window.clearAllTestValues();
}
