import 'package:flutter/rendering.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';

abstract class PainterUtils {
  static TextPainter create(TextPainter? painter, String? text, Color? color, double? fontSize, {String? fontFamily, FontWeight fontWeight = FontWeight.w400}) {
    if (painter == null) {
      return _create(text, color, fontSize, fontFamily: fontFamily, fontWeight: fontWeight);
    }

    if (painter.text != null && (painter.text is TextSpan)) {
      var preText = (painter.text as TextSpan).text;
      var preColor = painter.text!.style!.color;
      preColor = preColor ?? ColorUtils.BLACK;
      var preFontSize = painter.text!.style!.fontSize;
      preFontSize = preFontSize ?? Utils.convertDpToPixel(13);
      return _create(text ?? preText, color ?? preColor, fontSize ?? preFontSize, fontFamily: fontFamily, fontWeight: fontWeight);
    } else {
      return _create(text, color, fontSize, fontFamily: fontFamily, fontWeight: fontWeight);
    }
  }

  static TextPainter _create(String? text, Color? color, double? fontSize, {String? fontFamily, FontWeight fontWeight = FontWeight.w400}) {
    return TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(text: text, style: createTextStyle(color, fontSize, fontFamily: fontFamily, fontWeight: fontWeight)));
  }

  static TextStyle createTextStyle(Color? color, double? fontSize, {String? fontFamily, FontWeight fontWeight = FontWeight.w400}) {
    return TextStyle(color: color, fontSize: fontSize, fontFamily: fontFamily, fontWeight: fontWeight);
  }
}
