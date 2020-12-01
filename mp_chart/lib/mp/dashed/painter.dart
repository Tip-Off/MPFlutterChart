import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class Painter {
  static final matrix = Float64List.fromList(Matrix4.identity().storage);

  static Paint get(ui.Image image, {Color color = Colors.white, double strokeWidth = 1}) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn)
      ..strokeWidth = strokeWidth
      ..shader = ImageShader(image, TileMode.repeated, TileMode.repeated, matrix);
  }
}
