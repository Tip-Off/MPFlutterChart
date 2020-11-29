import 'package:flutter/painting.dart';
import 'package:mp_chart/mp/core/adapter_android_mp.dart';
import 'package:mp_chart/mp/core/animator.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/render/bar_chart_renderer.dart';
import 'package:mp_chart/mp/core/render/candle_stick_chart_renderer.dart';
import 'package:mp_chart/mp/core/render/data_renderer.dart';
import 'package:mp_chart/mp/core/render/line_chart_renderer.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:mp_chart/mp/painter/combined_chart_painter.dart';
import 'package:mp_chart/mp/painter/painter.dart';
import 'package:mp_chart/mp/core/poolable/point.dart';

class CombinedChartRenderer extends DataRenderer {
  /// all rederers for the different kinds of data this combined-renderer can draw
  List<DataRenderer> _renderers = List<DataRenderer>();
  ChartPainter _painter;
  List<Highlight> mHighlightBuffer = List<Highlight>();

  CombinedChartRenderer(CombinedChartPainter chart, Animator animator, ViewPortHandler viewPortHandler) : super(animator, viewPortHandler) {
    _painter = chart;
    createRenderers();
  }

  /// Creates the renderers needed for this combined-renderer in the required order. Also takes the DrawOrder into
  /// consideration.
  void createRenderers() {
    _renderers.clear();

    CombinedChartPainter chart = (_painter as CombinedChartPainter);
    if (chart == null) return;

    List<DrawOrder> orders = chart.getDrawOrder();

    for (DrawOrder order in orders) {
      switch (order) {
        case DrawOrder.BAR:
          if (chart.getBarData() != null) _renderers.add(BarChartRenderer(chart, animator, viewPortHandler));
          break;
        case DrawOrder.LINE:
          if (chart.getLineData() != null) _renderers.add(LineChartRenderer(chart, animator, viewPortHandler));
          break;
        case DrawOrder.CANDLE:
          if (chart.getCandleData() != null) _renderers.add(CandleStickChartRenderer(chart, animator, viewPortHandler));
          break;
      }
    }
  }

  @override
  void initBuffers() {
    for (DataRenderer renderer in _renderers) renderer.initBuffers();
  }

  @override
  void drawData(Canvas c) {
    for (DataRenderer renderer in _renderers) renderer.drawData(c);
  }

  @override
  void drawValue(Canvas c, String valueText, double x, double y, Color color, double textSize, TypeFace typeFace) {}

  @override
  void drawValues(Canvas c) {
    for (DataRenderer renderer in _renderers) renderer.drawValues(c);
  }

  @override
  void drawExtras(Canvas c) {
    for (DataRenderer renderer in _renderers) renderer.drawExtras(c);
  }

  @override
  MPPointD drawHighlighted(Canvas c, List<Highlight> indices) {
    ChartPainter chart = _painter;
    if (chart == null) return MPPointD(0, 0);

    var pix = MPPointD(-1, -1);
    var rendererSize = Size(0, 0);
    _renderers.forEach((renderer) {
      mHighlightBuffer.clear();

      for (Highlight h in indices) {
        mHighlightBuffer.add(h);
      }

      pix = renderer.drawHighlighted(c, mHighlightBuffer);
      final legendSize = renderer.drawFloatingLegend(c, mHighlightBuffer, rendererSize);
      rendererSize = Size(rendererSize.width + legendSize.width, rendererSize.height + legendSize.height);
    });

    return pix;
  }

  /// Returns the sub-renderer object at the specified index.
  ///
  /// @param index
  /// @return
  DataRenderer getSubRenderer(int index) {
    if (index >= _renderers.length || index < 0)
      return null;
    else
      return _renderers[index];
  }

  /// Returns all sub-renderers.
  ///
  /// @return
  List<DataRenderer> getSubRenderers() {
    return _renderers;
  }

  void setSubRenderers(List<DataRenderer> renderers) {
    this._renderers = renderers;
  }

  @override
  Size drawFloatingLegend(Canvas c, List<Highlight> indices, Size rendererSize) => rendererSize;
}
