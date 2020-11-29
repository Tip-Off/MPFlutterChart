import 'dart:async';
import 'dart:typed_data';

import 'orientation.dart';
import 'dart:ui' as ui;

class ImageStore {
  static ui.Image _horizontalDashed;
  static ui.Image _verticalDashed;

  static ui.Image getHorizontalDashed() => _horizontalDashed;
  static ui.Image getVerticalDashed() => _verticalDashed;

  Future<void> initialize() async {
    _horizontalDashed = await _generateDashed(5, Orientation.horizontal);
    _verticalDashed = await _generateDashed(5, Orientation.vertical);
  }

  Future<ui.Image> _generateDashed(int size, Orientation orientation) async {
    var length = size * 2;
    var completer = Completer<ui.Image>();

    var pixels = Int32List(length);

    for (var i = 0; i < length; i++) {
      pixels[i] = _generatePixel(i, size);
    }

    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      orientation == Orientation.horizontal ? length : 1,
      orientation == Orientation.vertical ? length : 1,
      ui.PixelFormat.bgra8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );

    return completer.future;
  }

  int _generatePixel(int i, int size) {
    if (i < size) {
      return 0xffffffff;
    } else {
      return 0x00000000;
    }
  }
}
