import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:mp_chart/mp/core/adapter_android_mp.dart';
import 'package:mp_chart/mp/core/animator.dart';
import 'package:mp_chart/mp/core/data/line_data.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_line_data_set.dart';
import 'package:mp_chart/mp/core/data_provider/line_data_provider.dart';
import 'package:mp_chart/mp/core/data_set/line_data_set.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';
import 'package:mp_chart/mp/core/enums/mode.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/render/float_legend_utils.dart';
import 'package:mp_chart/mp/core/render/line_scatter_candle_radar_renderer.dart';
import 'package:mp_chart/mp/core/transformer/transformer.dart';
import 'package:mp_chart/mp/core/utils/canvas_utils.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/utils/painter_utils.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:mp_chart/mp/core/poolable/point.dart';

class LineChartRenderer extends LineScatterCandleRadarRenderer {
  LineDataProvider _provider;

  TextPainter _labelText;

  LineChartRenderer(LineDataProvider chart, Animator animator, ViewPortHandler viewPortHandler) : super(animator, viewPortHandler) {
    _provider = chart;

    _labelText = PainterUtils.create(null, null, ColorUtils.WHITE, null);
  }

  LineDataProvider get provider => _provider;

  @override
  void initBuffers() {}

  @override
  void drawData(Canvas c) {
    var lineData = _provider.getLineData();

    for (var set in lineData.dataSets) {
      if (set.isVisible()) drawDataSet(c, set);
    }
  }

  void drawDataSet(Canvas c, ILineDataSet dataSet) {
    if (dataSet.getEntryCount() < 1) return;

    renderPaint.strokeWidth = dataSet.getLineWidth();

    drawLinear(c, dataSet);
  }

  List<double> mLineBuffer = List(4);

  void drawLinear(Canvas canvas, ILineDataSet dataSet) {
    var entryCount = dataSet.getEntryCount();

    final isDrawSteppedEnabled = dataSet.getMode() == Mode.STEPPED;
    final pointsPerEntryPair = isDrawSteppedEnabled ? 4 : 2;

    var trans = _provider.getTransformer(dataSet.getAxisDependency());

    var phaseY = animator.getPhaseY();

    renderPaint.style = PaintingStyle.stroke;

    xBounds.set(_provider, dataSet);

    // more than 1 color
    if (dataSet.getColors().length > 1) {
      if (mLineBuffer.length <= pointsPerEntryPair * 2) mLineBuffer = List(pointsPerEntryPair * 4);

      for (var j = xBounds.min; j <= xBounds.range + xBounds.min; j++) {
        var e = dataSet.getEntryForIndex(j);
        if (e == null) continue;

        mLineBuffer[0] = e.x;
        mLineBuffer[1] = e.y * phaseY;

        if (j < xBounds.max) {
          e = dataSet.getEntryForIndex(j + 1);

          if (e == null) break;

          if (isDrawSteppedEnabled) {
            mLineBuffer[2] = e.x;
            mLineBuffer[3] = mLineBuffer[1];
            mLineBuffer[4] = mLineBuffer[2];
            mLineBuffer[5] = mLineBuffer[3];
            mLineBuffer[6] = e.x;
            mLineBuffer[7] = e.y * phaseY;
          } else {
            mLineBuffer[2] = e.x;
            mLineBuffer[3] = e.y * phaseY;
          }
        } else {
          mLineBuffer[2] = mLineBuffer[0];
          mLineBuffer[3] = mLineBuffer[1];
        }

        trans.pointValuesToPixel(mLineBuffer);

        if (!viewPortHandler.isInBoundsRight(mLineBuffer[0])) break;

        // make sure the lines don't do shitty things outside bounds
        if (!viewPortHandler.isInBoundsLeft(mLineBuffer[2]) ||
            (!viewPortHandler.isInBoundsTop(mLineBuffer[1]) && !viewPortHandler.isInBoundsBottom(mLineBuffer[3]))) continue;

        // get the color that is set for this line-segment
        renderPaint.color = dataSet.getColor2(j);

        CanvasUtils.drawLines(canvas, mLineBuffer, 0, pointsPerEntryPair * 2, renderPaint);
      }
    } else {
      // only one color per dataset

      if (mLineBuffer.length < max((entryCount) * pointsPerEntryPair, pointsPerEntryPair) * 2) {
        mLineBuffer = List(max((entryCount) * pointsPerEntryPair, pointsPerEntryPair) * 4);
      }

      Entry e1, e2;

      e1 = dataSet.getEntryForIndex(xBounds.min);

      if (e1 != null) {
        var j = 0;
        for (var x = xBounds.min; x <= xBounds.range + xBounds.min; x++) {
          e1 = dataSet.getEntryForIndex(x == 0 ? 0 : (x - 1));
          e2 = dataSet.getEntryForIndex(x);

          if (e1 == null || e2 == null) continue;

          if (e1.mData is bool && !e1.mData) continue;

          mLineBuffer[j++] = e1.x;
          mLineBuffer[j++] = e1.y * phaseY;

          if (isDrawSteppedEnabled) {
            mLineBuffer[j++] = e2.x;
            mLineBuffer[j++] = e1.y * phaseY;
            mLineBuffer[j++] = e2.x;
            mLineBuffer[j++] = e1.y * phaseY;
          }

          mLineBuffer[j++] = e2.x;
          mLineBuffer[j++] = e2.y * phaseY;
        }

        if (j > 0) {
          trans.pointValuesToPixel(mLineBuffer);

          final size = max((xBounds.range + 1) * pointsPerEntryPair, pointsPerEntryPair) * 2;

          renderPaint.color = dataSet.getColor1();

          CanvasUtils.drawLines(canvas, mLineBuffer, 0, size, renderPaint);
        }
      }
    }
  }

  @override
  void drawValues(Canvas c) {}

  @override
  void drawValue(Canvas c, String valueText, double x, double y, Color color, double textSize, TypeFace typeFace) {}

  @override
  void drawExtras(Canvas c) {}

  @override
  MPPointD drawHighlighted(Canvas c, List<Highlight> indices) {
    var lineData = _provider.getLineData();

    var pix = MPPointD(0, 0);

    for (var high in indices) {
      ILineDataSet dataSet;
      if (high.dataSetIndex >= 0) {
        dataSet = lineData.getDataSetByIndex(high.dataSetIndex);
      } else {
        dataSet = lineData.dataSets.firstWhere((element) => element.getEntriesForXValue(high.x).length > 0, orElse: () => null);
      }

      if (dataSet == null || !dataSet.isHighlightEnabled()) continue;

      var e = dataSet.getEntryForXValue2(high.x, high.y);

      if (!isInBoundsX(e, dataSet)) continue;

      var yVal = high.freeY == null || high.freeY.isNaN ? high.y : high.freeY;

      pix = _provider.getTransformer(dataSet.getAxisDependency()).getPixelForValues(e.x, yVal);

      high.setDraw(pix.x, pix.y);

      // draw the lines
      drawHighlightLines(c, pix.x, pix.y, dataSet);
    }
    return pix;
  }

  @override
  Size drawFloatingLegend(Canvas c, List<Highlight> indices, Size rendererSize) {
    final data = _provider.getData();
    return FloatLegendUtils.drawFloatingLegend<LineDataSet>(_labelText, c, viewPortHandler, data, indices, rendererSize);
  }
}
