import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:mp_chart/mp/core/limit_line.dart';

abstract class CanvasUtils {
  static void drawLines(ui.Canvas canvas, List<double> pts, int offset, int count, ui.Paint paint) {
    for (var i = offset; i < count; i += 4) {
      canvas.drawLine(ui.Offset(_notNan(pts[i]), _notNan(pts[i + 1])), ui.Offset(_notNan(pts[i + 2]), _notNan(pts[i + 3])), paint);
    }
  }

  static double _notNan(double value, {double initial = 0.0}) => value.isNaN ? initial : value;

  static void drawImage(ui.Canvas canvas, Offset position, ui.Image img, ui.Size dstSize, ui.Paint paint) {
    var imgSize = ui.Size(img.width.toDouble(), img.height.toDouble());

    var sizes = applyBoxFit(BoxFit.contain, imgSize, dstSize);

    final inputRect = Alignment.center.inscribe(sizes.source, Rect.fromLTWH(0, 0, sizes.source.width, sizes.source.height));
    final outputRect = Alignment.center.inscribe(
        sizes.destination, Rect.fromLTWH(position.dx - dstSize.width / 2, position.dy - dstSize.height / 2, sizes.destination.width, sizes.destination.height));
    canvas.drawImageRect(img, inputRect, outputRect, paint);
  }

  static const double LABEL_SPACE = 2;

  static void renderLimitLabelBackground(Canvas canvas, TextPainter textPainter, Offset offset, LimitLine limitLine) {
    if (limitLine.drawBackground) {
      var paint = Paint()..color = limitLine.backgroundColor;
      canvas.drawRect(
          Rect.fromLTRB(
              offset.dx - LABEL_SPACE, offset.dy - LABEL_SPACE, offset.dx + LABEL_SPACE + textPainter.width, offset.dy + LABEL_SPACE + textPainter.height),
          paint);
    }
  }
}
