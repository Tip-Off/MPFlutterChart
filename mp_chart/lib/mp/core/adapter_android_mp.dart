import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

class DashPathEffect {
  ui.Image image;

  Float64List matrix = Float64List.fromList(Matrix4.identity().storage);

  ui.Paint get paint {
    return Paint()
      ..colorFilter = ColorFilter.mode(Colors.orange, BlendMode.srcIn)
      ..strokeWidth = 2
      ..shader =
          ImageShader(image, TileMode.repeated, TileMode.repeated, matrix);
  }

  DashPathEffect(this.image, int lineStroke, Color color);
}

class TypeFace {
  String _fontFamily;
  FontWeight _fontWeight;

  TypeFace({String fontFamily, FontWeight fontWeight = FontWeight.w400}) {
    _fontFamily = fontFamily;
    _fontWeight = fontWeight;
  }

  // ignore: unnecessary_getters_setters
  FontWeight get fontWeight => _fontWeight;

  // ignore: unnecessary_getters_setters
  set fontWeight(FontWeight value) {
    _fontWeight = value;
  }

  // ignore: unnecessary_getters_setters
  String get fontFamily => _fontFamily;

  // ignore: unnecessary_getters_setters
  set fontFamily(String value) {
    _fontFamily = value;
  }
}
