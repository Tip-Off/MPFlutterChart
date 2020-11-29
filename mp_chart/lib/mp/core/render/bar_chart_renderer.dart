import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:mp_chart/mp/core/adapter_android_mp.dart';
import 'package:mp_chart/mp/core/animator.dart';
import 'package:mp_chart/mp/core/buffer/bar_buffer.dart';
import 'package:mp_chart/mp/core/color/gradient_color.dart';
import 'package:mp_chart/mp/core/data/bar_data.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_bar_data_set.dart';
import 'package:mp_chart/mp/core/data_provider/bar_data_provider.dart';
import 'package:mp_chart/mp/core/data_set/bar_data_set.dart';
import 'package:mp_chart/mp/core/entry/bar_entry.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/poolable/point.dart';
import 'package:mp_chart/mp/core/range.dart';
import 'package:mp_chart/mp/core/render/bar_line_scatter_candle_bubble_renderer.dart';
import 'package:mp_chart/mp/core/render/float_legend_utils.dart';
import 'package:mp_chart/mp/core/transformer/transformer.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/utils/painter_utils.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:mp_chart/mp/dashed/image_store.dart';
import 'package:mp_chart/mp/dashed/painter.dart';

class BarChartRenderer extends BarLineScatterCandleBubbleRenderer {
  BarDataProvider _provider;

  /// the rect object that is used for drawing the bars
  Rect _barRect = Rect.zero;

  List<BarBuffer> _barBuffers;
  TextPainter _labelText;

  Paint _shadowPaint;
  Paint _barBorderPaint;

  BarChartRenderer(BarDataProvider chart, Animator animator, ViewPortHandler viewPortHandler) : super(animator, viewPortHandler) {
    this._provider = chart;

    _labelText = PainterUtils.create(null, null, ColorUtils.WHITE, null);

    highlightPaint = Paint()
      ..isAntiAlias = true
      ..color = Color.fromARGB(120, 0, 0, 0)
      ..style = PaintingStyle.fill;

    _shadowPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    _barBorderPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;
  }

  @override
  void initBuffers() {
    BarData barData = _provider.getBarData();
    _barBuffers = List(barData.getDataSetCount());

    for (int i = 0; i < _barBuffers.length; i++) {
      IBarDataSet set = barData.getDataSetByIndex(i);
      _barBuffers[i] = BarBuffer(set.getEntryCount() * 4 * (set.isStacked() ? set.getStackSize() : 1), barData.getDataSetCount(), set.isStacked());
    }
  }

  @override
  void drawData(Canvas c) {
    BarData barData = _provider.getBarData();

    for (int i = 0; i < barData.getDataSetCount(); i++) {
      IBarDataSet set = barData.getDataSetByIndex(i);

      if (set.isVisible()) {
        drawDataSet(c, set, i);
      }
    }
  }

  void drawDataSet(Canvas c, IBarDataSet dataSet, int index) {
    Transformer trans = _provider.getTransformer(dataSet.getAxisDependency());

    _barBorderPaint.color = dataSet.getBarBorderColor();
    _barBorderPaint.strokeWidth = Utils.convertDpToPixel(dataSet.getBarBorderWidth());

    final bool drawBorder = dataSet.getBarBorderWidth() > 0.0;

    double phaseX = animator.getPhaseX();
    double phaseY = animator.getPhaseY();

    // draw the bar shadow before the values
    if (_provider.isDrawBarShadowEnabled()) {
      _shadowPaint.color = dataSet.getBarShadowColor();

      BarData barData = _provider.getBarData();

      final double barWidth = barData.barWidth;
      final double barWidthHalf = barWidth / 2.0;
      double x;

      for (int i = 0, count = min((((dataSet.getEntryCount()) * phaseX).ceil()), dataSet.getEntryCount()); i < count; i++) {
        BarEntry e = dataSet.getEntryForIndex(i);

        x = e.x;

        _barShadowRectBuffer = Rect.fromLTRB(x - barWidthHalf, 0.0, x + barWidthHalf, 0.0);

        trans.rectValueToPixel(_barShadowRectBuffer);

        if (!viewPortHandler.isInBoundsLeft(_barShadowRectBuffer.right)) continue;

        if (!viewPortHandler.isInBoundsRight(_barShadowRectBuffer.left)) break;

        _barShadowRectBuffer =
            Rect.fromLTRB(_barShadowRectBuffer.left, viewPortHandler.contentTop(), _barShadowRectBuffer.right, viewPortHandler.contentBottom());

        c.drawRect(_barShadowRectBuffer, _shadowPaint);
      }
    }

    // initialize the buffer
    BarBuffer buffer = _barBuffers[index];
    buffer.setPhases(phaseX, phaseY);
    buffer.dataSetIndex = (index);
    buffer.inverted = (_provider.isInverted(dataSet.getAxisDependency()));
    buffer.barWidth = (_provider.getBarData().barWidth);

    buffer.feed(dataSet);

    trans.pointValuesToPixel(buffer.buffer);

    final bool isSingleColor = dataSet.getColors().length == 1;

    if (isSingleColor) {
      renderPaint.color = dataSet.getColor1();
    }

    for (int j = 0; j < buffer.size(); j += 4) {
      if (!viewPortHandler.isInBoundsLeft(buffer.buffer[j + 2])) continue;

      if (!viewPortHandler.isInBoundsRight(buffer.buffer[j])) break;

      if (!isSingleColor) {
        // Set the color for the currently drawn value. If the index
        // is out of bounds, reuse colors.
        renderPaint.color = dataSet.getColor2(j ~/ 4);
      }

      if (dataSet.getGradientColor1() != null) {
        GradientColor gradientColor = dataSet.getGradientColor1();

        final colors = [gradientColor.startColor, gradientColor.endColor];

        renderPaint.shader = LinearGradient(colors: colors, tileMode: TileMode.mirror)
            .createShader(Rect.fromLTRB(buffer.buffer[j], buffer.buffer[j + 3], buffer.buffer[j], buffer.buffer[j + 1]));
      }

      if (dataSet.getGradientColors() != null) {
        final colors = [dataSet.getGradientColor2(j ~/ 4).startColor, dataSet.getGradientColor2(j ~/ 4).endColor];

        renderPaint.shader = LinearGradient(colors: colors, tileMode: TileMode.mirror)
            .createShader(Rect.fromLTRB(buffer.buffer[j], buffer.buffer[j + 3], buffer.buffer[j], buffer.buffer[j + 1]));
      }

      c.drawRect(Rect.fromLTRB(buffer.buffer[j], buffer.buffer[j + 1], buffer.buffer[j + 2], buffer.buffer[j + 3]), renderPaint);

      if (drawBorder) {
        c.drawRect(Rect.fromLTRB(buffer.buffer[j], buffer.buffer[j + 1], buffer.buffer[j + 2], buffer.buffer[j + 3]), _barBorderPaint);
      }
    }
  }

  Rect _barShadowRectBuffer = Rect.zero;

  void prepareBarHighlight(double x, double y1, double y2, double barWidthHalf, Transformer trans) {
    double left = x - barWidthHalf;
    double right = x + barWidthHalf;
    double top = y1;
    double bottom = y2;

    _barRect = trans.rectToPixelPhase(Rect.fromLTRB(left, top, right, bottom), animator.getPhaseY());
  }

  @override
  void drawValues(Canvas c) {}

  @override
  void drawValue(Canvas c, String valueText, double x, double y, Color color, double textSize, TypeFace typeFace) {
    valuePaint = PainterUtils.create(valuePaint, valueText, color, textSize, fontFamily: typeFace?.fontFamily, fontWeight: typeFace?.fontWeight);
    valuePaint.layout();
    valuePaint.paint(c, Offset(x - valuePaint.width / 2, y - valuePaint.height));
  }

  @override
  MPPointD drawHighlighted(Canvas c, List<Highlight> indices) {
    BarData barData = _provider.getBarData();

    var pix = MPPointD(0, 0);

    for (Highlight high in indices) {
      IBarDataSet dataSet;
      if (high.dataSetIndex >= 0) {
        dataSet = barData.getDataSetByIndex(high.dataSetIndex);
      } else {
        dataSet = barData.dataSets.firstWhere((element) => element.getEntriesForXValue(high.x).length > 0, orElse: () => null);
      }

      if (dataSet == null || !dataSet.isHighlightEnabled()) continue;

      BarEntry e = dataSet.getEntryForXValue2(high.x, high.y);

      if (!isInBoundsX(e, dataSet)) continue;

      Transformer trans = _provider.getTransformer(dataSet.getAxisDependency());

      var color = dataSet.getHighLightColor();
      highlightPaint.color = Color.fromARGB(dataSet.getHighLightAlpha(), color.red, color.green, color.blue);

      bool isStack = (high.stackIndex >= 0 && e.isStacked()) ? true : false;

      double y1;
      double y2;

      if (isStack) {
        if (_provider.isHighlightFullBarEnabled()) {
          y1 = e.positiveSum;
          y2 = -e.negativeSum;
        } else {
          Range range = e.ranges[high.stackIndex];

          y1 = range.from;
          y2 = range.to;
        }
      } else {
        y1 = e.y;
        y2 = 0.0;
      }

      pix = _provider.getTransformer(dataSet.getAxisDependency()).getPixelForValues(e.x, y1); //MPPointD(e.x, y2);
      prepareBarHighlight(e.x, y1, y2, barData.barWidth / 2.0, trans);

      setHighlightDrawPos(high, _barRect);
      c.drawRect(_barRect, highlightPaint);

      drawHighlightLines(c, _barRect.center.dx, y1 > 0 ? _barRect.top : _barRect.bottom, dataSet);
    }

    return pix;
  }

  void drawHighlightLines(Canvas c, double x, double y, IBarDataSet set) {
    highlightPaint
      ..color = set.getHighLightColor()
      ..strokeWidth = set.getHighlightLineWidth();

    if (set.isHighlightLineDashed()) {
      highlightPaint = Painter.get(ImageStore.getVerticalDashed(), strokeWidth: set.getHighlightLineWidth(), color: set.getHighLightColor());
    }

    c.drawLine(Offset(x, viewPortHandler.contentTop()), Offset(x, viewPortHandler.contentBottom()), highlightPaint);
    c.drawLine(Offset(viewPortHandler.contentLeft(), y), Offset(viewPortHandler.contentRight(), y), highlightPaint);
  }

  /// Sets the drawing position of the highlight object based on the riven bar-rect.
  /// @param high
  void setHighlightDrawPos(Highlight high, Rect bar) {
    high.setDraw(bar.center.dx, bar.top);
  }

  @override
  void drawExtras(Canvas c) {}

  @override
  Size drawFloatingLegend(Canvas c, List<Highlight> indices, Size rendererSize) {
    final data = _provider.getData();
    return FloatLegendUtils.drawFloatingLegend<BarDataSet>(_labelText, c, viewPortHandler, data, indices, rendererSize);
  }
}
