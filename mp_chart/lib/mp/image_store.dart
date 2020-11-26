import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum DashedOrientation {
  horizontal,
  vertical,
}

class ImageStore {
  static ui.Image _horizontalDashed;
  static ui.Image _verticalDashed;

  static ui.Image getHorizontalDashed() => _horizontalDashed;
  static ui.Image getVerticalDashed() => _verticalDashed;

  static Future<void> initialize() async {
    _horizontalDashed = await _generateDashed(5, DashedOrientation.horizontal);
    _verticalDashed = await _generateDashed(5, DashedOrientation.vertical);
  }

  static Future<ui.Image> _generateDashed(
      int size, DashedOrientation orientation) async {
    int length = size * 2;
    var completer = Completer<ui.Image>();

    Int32List pixels = Int32List(length);

    for (var i = 0; i < length; i++) {
      pixels[i] = _generatePixel(i, size);
    }

    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      orientation == DashedOrientation.horizontal ? length : 1,
      orientation == DashedOrientation.vertical ? length : 1,
      ui.PixelFormat.bgra8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );

    return completer.future;
  }

  static int _generatePixel(int i, int size) {
    if (i < size) {
      return 0xffffffff;
    } else {
      return 0x00000000;
    }
  }
}
