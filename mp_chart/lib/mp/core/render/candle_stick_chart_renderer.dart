import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:matrix4_transform/matrix4_transform.dart';
import 'package:mp_chart/mp/core/adapter_android_mp.dart';
import 'package:mp_chart/mp/core/animator.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_candle_data_set.dart';
import 'package:mp_chart/mp/core/data_provider/candle_data_provider.dart';
import 'package:mp_chart/mp/core/entry/candle_entry.dart';
import 'package:mp_chart/mp/core/enums/alert_type.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/render/line_scatter_candle_radar_renderer.dart';
import 'package:mp_chart/mp/core/utils/canvas_utils.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/utils/painter_utils.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:mp_chart/mp/core/poolable/point.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';
import 'package:collection/collection.dart';

class CandleStickChartRenderer extends LineScatterCandleRadarRenderer {
  late CandleDataProvider _provider;

  final List<double> _shadowBuffer = List.filled(4, 0.0);
  final List<double> _bodyBuffers = List.filled(4, 0.0);

  late TextPainter _labelText;

  final _floatingLegendBg = Color.fromARGB(150, 50, 50, 50);

  final _whiteStyle = TextStyle(
    fontSize: 10,
    color: Colors.white,
  );

  final _greenStyle = TextStyle(
    fontSize: 10,
    color: Colors.lightGreenAccent,
  );

  final _redStyle = TextStyle(
    fontSize: 10,
    color: Colors.redAccent,
  );

  CandleStickChartRenderer(CandleDataProvider chart, Animator animator, ViewPortHandler viewPortHandler) : super(animator, viewPortHandler) {
    _provider = chart;

    _labelText = PainterUtils.create(null, null, ColorUtils.WHITE, null);
  }

  CandleDataProvider get porvider => _provider;

  @override
  void initBuffers() {}

  @override
  void drawData(Canvas c) {
    var candleData = _provider.getCandleData()!;

    for (var set in candleData.dataSets!) {
      if (set.isVisible()) drawDataSet(c, set);
    }
  }

  void drawDataSet(Canvas c, ICandleDataSet dataSet) {
    var trans = _provider.getTransformer(dataSet.getAxisDependency());

    var phaseY = animator.getPhaseY();
    var barSpace = dataSet.getBarSpace();

    xBounds.set(_provider, dataSet);

    renderPaint.strokeWidth = dataSet.getShadowWidth();

    // draw the body
    for (var j = xBounds.min!; j <= xBounds.range! + xBounds.min!; j++) {
      // get the entry
      var e = dataSet.getEntryForIndex(j);

      if (e == null) continue;

      final xPos = e.x;

      final open = e.open;
      final close = e.close;
      final high = e.shadowHigh;
      final low = e.shadowLow;
      final candleHighlight = e.highlighted;

      // calculate the shadow
      _shadowBuffer[0] = xPos;
      _shadowBuffer[1] = high * phaseY;
      _shadowBuffer[2] = xPos;
      _shadowBuffer[3] = low * phaseY;

      trans!.pointValuesToPixel(_shadowBuffer);

      // draw the shadows
      if (dataSet.getShadowColorSameAsCandle()) {
        if (open > close) {
          renderPaint.color = dataSet.getDecreasingColor() == ColorUtils.COLOR_NONE ? dataSet.getColor2(j) : dataSet.getDecreasingColor();
        } else {
          renderPaint.color = dataSet.getIncreasingColor() == ColorUtils.COLOR_NONE ? dataSet.getColor2(j) : dataSet.getIncreasingColor();
        }
      } else {
        renderPaint.color = dataSet.getShadowColor() == ColorUtils.COLOR_NONE ? dataSet.getColor2(j) : dataSet.getShadowColor();
      }

      renderPaint.style = PaintingStyle.stroke;

      CanvasUtils.drawLines(c, _shadowBuffer, 0, _shadowBuffer.length, renderPaint);

      // calculate the body
      _bodyBuffers[0] = xPos - 0.5 + barSpace;
      _bodyBuffers[1] = close * phaseY;
      _bodyBuffers[2] = (xPos + 0.5 - barSpace);
      _bodyBuffers[3] = open * phaseY;

      trans.pointValuesToPixel(_bodyBuffers);

      renderPaint.style = PaintingStyle.fill;

      // draw body differently for increasing and decreasing entry
      if (open > close) {
        renderPaint.color = _highlightColorOr(dataSet, dataSet.getDecreasingColor(), candleHighlight);

        c.drawRect(Rect.fromLTRB(_bodyBuffers[0], _bodyBuffers[1], _bodyBuffers[2], _bodyBuffers[3]), renderPaint);
      } else if (open < close) {
        renderPaint.color = _highlightColorOr(dataSet, dataSet.getIncreasingColor(), candleHighlight);

        c.drawRect(Rect.fromLTRB(_bodyBuffers[0], _bodyBuffers[1], _bodyBuffers[2], _bodyBuffers[3]), renderPaint);
      } else {
        renderPaint.color = _highlightColorOr(dataSet, dataSet.getIncreasingColor(), candleHighlight);

        c.drawLine(Offset(_bodyBuffers[0], _bodyBuffers[1]), Offset(_bodyBuffers[2], _bodyBuffers[3]), renderPaint);
      }

      _maybeDrawAlert(c, dataSet, e);
    }
  }

  Color _highlightColorOr(ICandleDataSet dataSet, Color alternative, bool candleHighlight) =>
      dataSet.getHighlightCandleEnabled() && candleHighlight ? dataSet.getHighlightCandleColor() : alternative;

  @override
  void drawValues(Canvas c) {}

  var rng = Random();

  void _maybeDrawAlert(Canvas c, ICandleDataSet dataSet, CandleEntry entry) {
    if (!dataSet.isDrawAlertsEnabled() || entry.mAlertType == null) return;

    final alertType = entry.mAlertType!;

    var y = _shadowBuffer[1];

    final left = _bodyBuffers[0];
    final right = _bodyBuffers[2];

    final size = right - left;
    final half = size / 2;

    final offset = half;

    final pY = y;

    Path? path;

    if (alertType == AlertType.bull || alertType == AlertType.triggered_bull) {
      path = _bullPath(left, right, pY, half, size, offset);
    } else if (alertType == AlertType.bear || alertType == AlertType.triggered_bear) {
      path = _bearPath(left, right, pY, half, size, offset);
    } else {
      path = _normalPath(left, right, pY, half, size, offset);
    }

    renderPaint.color = ColorUtils.WHITE;

    c.drawPath(path, renderPaint);

    List<double> centroid;

    if (alertType == AlertType.bull || alertType == AlertType.triggered_bull) {
      centroid = _bullCentroid(left, right, pY, half, size, offset);
    } else if (alertType == AlertType.bear || alertType == AlertType.triggered_bear) {
      centroid = _bearCentroid(left, right, pY, half, size, offset);
    } else {
      centroid = _normalCentroid(left, right, y, half, size, offset);
    }

    var scale = 0.7;

    if (alertType == AlertType.normal || alertType == AlertType.triggered_normal) scale = 0.8;

    final matrix = Matrix4Transform().scale(scale, origin: Offset(centroid[0], centroid[1])).matrix4;

    final path2 = path.transform(matrix.storage);

    if (alertType == AlertType.bull || alertType == AlertType.triggered_bull) {
      renderPaint.color = _highlightColorOr(dataSet, dataSet.getIncreasingColor(), entry.highlighted);
    } else if (alertType == AlertType.bear || alertType == AlertType.triggered_bear) {
      renderPaint.color = _highlightColorOr(dataSet, dataSet.getDecreasingColor(), entry.highlighted);
    } else {
      renderPaint.color = Colors.purple;
    }

    c.drawPath(path2, renderPaint);
  }

  Path _bullPath(double left, double right, double y, double half, double size, double offset) {
    var path = Path();

    path.moveTo(left + half, y - size - offset);
    path.lineTo(left, y - offset);
    path.lineTo(right, y - offset);
    path.close();

    return path;
  }

  List<double> _bullCentroid(double left, double right, double y, double half, double size, double offset) {
    final centroidX = (left + left + half + right) / 3;
    final centroidY = (y - size - offset + y - offset + y - offset) / 3;

    return [centroidX, centroidY];
  }

  Path _bearPath(double left, double right, double y, double half, double size, double offset) {
    var path = Path();

    path.moveTo(left + half, y - offset);
    path.lineTo(left, y - size - offset);
    path.lineTo(right, y - size - offset);
    path.close();

    return path;
  }

  List<double> _bearCentroid(double left, double right, double y, double half, double size, double offset) {
    final centroidX = (left + left + half + right) / 3;
    final centroidY = (y - offset + y - size - offset + y - size - offset) / 3;

    return [centroidX, centroidY];
  }

  Path _normalPath(double left, double right, double y, double half, double size, double offset) {
    var path = Path();

    path.moveTo(left, y - offset);
    path.lineTo(right, y - offset);
    path.lineTo(right, y - size - offset);
    path.lineTo(left, y - size - offset);
    path.close();

    return path;
  }

  List<double> _normalCentroid(double left, double right, double y, double half, double size, double offset) {
    final centroidX = (left + right) / 2;
    final centroidY = (y - offset + y - size - offset) / 2;

    return [centroidX, centroidY];
  }

  @override
  void drawValue(Canvas c, String valueText, double x, double y, Color color, double textSize, TypeFace typeFace) {
    valuePaint = PainterUtils.create(valuePaint, valueText, color, textSize, fontFamily: typeFace.fontFamily, fontWeight: typeFace.fontWeight);
    valuePaint!.layout();
    valuePaint!.paint(c, Offset(x - valuePaint!.width / 2, y - valuePaint!.height));
  }

  @override
  void drawExtras(Canvas c) {
    var candleData = _provider.getCandleData()!;

    for (var set in candleData.dataSets!) {
      if (set.isVisible()) _drawVolumeDataSet(c, set);
    }
  }

  double _getMaximumVolume(ICandleDataSet dataSet) {
    var maxVolume = 0.0;
    for (var i = xBounds.min!; i <= xBounds.range! + xBounds.min!; i++) {
      maxVolume = max(maxVolume, dataSet.getEntryForIndex(i)!.volume);
    }
    return maxVolume;
  }

  Color _getColor(double open, double close, ICandleDataSet dataSet, int index) {
    if (open > close) {
      return dataSet.getDecreasingColor() == ColorUtils.COLOR_NONE ? dataSet.getColor2(index) : dataSet.getDecreasingColor();
    } else {
      return dataSet.getIncreasingColor() == ColorUtils.COLOR_NONE ? dataSet.getColor2(index) : dataSet.getIncreasingColor();
    }
  }

  void _drawVolumeDataSet(Canvas c, ICandleDataSet dataSet) {
    var trans = _provider.getTransformer(dataSet.getAxisDependency());

    var barSpace = dataSet.getBarSpace();

    xBounds.set(_provider, dataSet);
    renderPaint.strokeWidth = dataSet.getShadowWidth();

    var maximumVolume = _getMaximumVolume(dataSet);

    // draw the body
    for (var j = xBounds.min!; j <= xBounds.range! + xBounds.min!; j++) {
      var e = dataSet.getEntryForIndex(j);
      if (e == null || maximumVolume == 0.0) continue;

      final xPos = e.x;
      final volume = e.volume;
      final factor = volume / maximumVolume;
      final h2 = viewPortHandler!.getChartHeight() * .2;

      var xBar = trans!.getPixelForValues(xPos - 0.5 + barSpace, 0).x;
      var sizeBar = trans.getPixelForValues(xPos + 0.5 - barSpace, 0).x;
      var widthBar = (sizeBar - xBar).abs();
      var heightBar = h2 * factor;
      var yBar = viewPortHandler!.contentBottom() - heightBar;

      renderPaint.color = _getColor(e.open, e.close, dataSet, j).withOpacity(.4);
      renderPaint.style = PaintingStyle.fill;
      c.drawRect(Rect.fromLTWH(xBar, yBar, widthBar, heightBar), renderPaint);
    }
  }

  @override
  MPPointD drawHighlighted(Canvas c, List<Highlight> indices) {
    var candleData = _provider.getCandleData()!;

    var pix = MPPointD(0, 0);
    for (var high in indices) {
      ICandleDataSet? dataSet;

      if (high.dataSetIndex >= 0) {
        dataSet = candleData.getDataSetByIndex(high.dataSetIndex);
      } else {
        dataSet = candleData.dataSets!.firstWhereOrNull((element) => element.getEntriesForXValue(high.x).isNotEmpty);
      }

      if (dataSet == null || !dataSet.isHighlightEnabled()) continue;

      var e = dataSet.getEntryForXValue2(high.x, high.y)!;

      if (!isInBoundsX(e, dataSet)) continue;

      var yVal = high.freeY == null || high.freeY!.isNaN ? high.y : high.freeY;
      pix = _provider.getTransformer(dataSet.getAxisDependency())!.getPixelForValues(e.x, yVal!);

      high.setDraw(pix.x, pix.y);

      // draw the lines
      drawHighlightLines(c, pix.x, pix.y, dataSet);
    }
    return pix;
  }

  @override
  Size drawFloatingLegend(Canvas c, List<Highlight> indices, Size rendererSize) {
    var size = Size(0, 0);
    if (indices.isNotEmpty) {
      var candleData = _provider.getCandleData()!;
      for (var set in candleData.dataSets!) {
        if (set.isVisible()) {
          final drawSize = _drawFloatingLegend(c, set, indices.first);
          size = Size(size.width + drawSize.width, size.height + drawSize.height);
        }
      }
    }
    return size;
  }

  Size _drawFloatingLegend(Canvas c, ICandleDataSet dataSet, Highlight h) {
    final e = dataSet.getEntryForXValue2(h.x, 0)!;
    final ohlcPosition = Offset(viewPortHandler!.contentLeft(), viewPortHandler!.contentTop());
    final ohlcSize = _drawOHLC(c, e, ohlcPosition);

    final diffPosition = Offset(viewPortHandler!.contentLeft() + _labelText.width, viewPortHandler!.contentTop());
    _drawDiff(c, dataSet, e, diffPosition);

    final volPosition = Offset(viewPortHandler!.contentLeft(), viewPortHandler!.contentTop() + _labelText.height);
    final volSize = _drawVol(c, e, volPosition);

    return Size(ohlcSize.width + volSize.width, ohlcSize.height + volSize.height);
  }

  Size _drawOHLC(Canvas c, CandleEntry e, Offset labelPosition) {
    var style = _colorByEntry(e);

    _labelText.text = TextSpan(text: '', style: _whiteStyle, children: [
      TextSpan(text: 'O', style: _whiteStyle),
      TextSpan(text: '${e.open}', style: style),
      TextSpan(text: '\tH', style: _whiteStyle),
      TextSpan(text: '${e.shadowHigh}', style: style),
      TextSpan(text: '\tL', style: _whiteStyle),
      TextSpan(text: '${e.shadowLow}', style: style),
      TextSpan(text: '\tC', style: _whiteStyle),
      TextSpan(text: '${e.close}', style: style),
    ]);
    _labelText.layout();
    _drawFloatingLegendBg(c, labelPosition, _labelText.size);
    _labelText.paint(c, labelPosition);

    return _labelText.size;
  }

  void _drawDiff(Canvas c, ICandleDataSet dataSet, CandleEntry currentEntry, Offset labelPosition) {
    var currentIndex = dataSet.getEntryIndex2(currentEntry);

    if (currentIndex > 0) {
      var previousEntry = dataSet.getEntryForIndex(currentIndex - 1)!;
      var diff = currentEntry.close - previousEntry.close;
      var diffPorcentage = diff / previousEntry.close * 100;
      var signal = diff > 0 ? '+' : '';

      _labelText.text = TextSpan(text: '\t\t', style: _whiteStyle, children: [
        TextSpan(
          text: '$signal${diff.toStringAsFixed(2)}',
          style: _colorByEntry(currentEntry),
        ),
        TextSpan(
          text: '\t($signal${diffPorcentage.toStringAsFixed(2)}%)',
          style: _colorByEntry(currentEntry),
        ),
      ]);
      _labelText.layout();
      _drawFloatingLegendBg(c, labelPosition, _labelText.size);
      _labelText.paint(c, labelPosition);
    }
  }

  Size _drawVol(Canvas c, CandleEntry e, Offset labelPosition) {
    _labelText.text = TextSpan(text: 'Vol ', style: _whiteStyle, children: [
      TextSpan(
        text: '${e.volume}',
        style: _colorByEntry(e),
      ),
    ]);
    _labelText.layout();
    _drawFloatingLegendBg(c, labelPosition, _labelText.size);
    _labelText.paint(c, labelPosition);

    return _labelText.size;
  }

  void _drawFloatingLegendBg(Canvas c, Offset position, Size size) {
    c.drawRect(Rect.fromLTWH(position.dx, position.dy, size.width, size.height), Paint()..color = _floatingLegendBg);
  }

  TextStyle _colorByEntry(CandleEntry e) => e.close > e.open ? _greenStyle : _redStyle;
}
