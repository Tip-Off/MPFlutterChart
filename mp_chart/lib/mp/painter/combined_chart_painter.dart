import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:mp_chart/mp/core/animator.dart';
import 'package:mp_chart/mp/core/axis/x_axis.dart';
import 'package:mp_chart/mp/core/axis/y_axis.dart';
import 'package:mp_chart/mp/core/common_interfaces.dart';
import 'package:mp_chart/mp/core/data/bar_data.dart';
import 'package:mp_chart/mp/core/data/candle_data.dart';
import 'package:mp_chart/mp/core/data/combined_data.dart';
import 'package:mp_chart/mp/core/data/line_data.dart';
import 'package:mp_chart/mp/core/data/scatter_data.dart';
import 'package:mp_chart/mp/core/data_provider/combined_data_provider.dart';
import 'package:mp_chart/mp/core/functions.dart';
import 'package:mp_chart/mp/core/highlight/combined_highlighter.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/legend/legend.dart';
import 'package:mp_chart/mp/core/render/combined_chart_renderer.dart';
import 'package:mp_chart/mp/core/render/x_axis_renderer.dart';
import 'package:mp_chart/mp/core/render/y_axis_renderer.dart';
import 'package:mp_chart/mp/core/chart_trans_listener.dart';
import 'package:mp_chart/mp/core/transformer/transformer.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:mp_chart/mp/painter/bar_line_chart_painter.dart';

enum DrawOrder { BAR, LINE, CANDLE, SCATTER }

class CombinedChartPainter extends BarLineChartBasePainter<CombinedData> implements CombinedDataProvider {
  /// if set to true, all values are drawn above their bars, instead of below
  /// their top
  bool _drawValueAboveBar = true;

  /// flag that indicates whether the highlight should be full-bar oriented, or single-value?
  bool _highlightFullBarEnabled = false;

  /// if set to true, a grey area is drawn behind each bar that indicates the
  /// maximum value
  bool _drawBarShadow = false;

  List<DrawOrder> _drawOrder;

  CombinedChartPainter(
      CombinedData data,
      Highlight highlightForced,
      Animator animator,
      ViewPortHandler viewPortHandler,
      double maxHighlightDistance,
      bool highLightPerTapEnabled,
      double extraLeftOffset,
      double extraTopOffset,
      double extraRightOffset,
      double extraBottomOffset,
      Color infoBgColor,
      TextPainter infoPainter,
      XAxis xAxis,
      Legend legend,
      DataRendererSettingFunction rendererSettingFunction,
      OnChartValueSelectedListener selectedListener,
      int maxVisibleCount,
      bool autoScaleMinMaxEnabled,
      bool pinchZoomEnabled,
      bool doubleTapToZoomEnabled,
      bool highlightPerDragEnabled,
      bool dragXEnabled,
      bool dragYEnabled,
      bool scaleXEnabled,
      bool scaleYEnabled,
      Paint gridBackgroundPaint,
      Paint backgroundPaint,
      Paint borderPaint,
      bool drawGridBackground,
      bool drawBorders,
      bool clipValuesToContent,
      double minOffset,
      bool keepPositionOnRotation,
      OnDrawListener drawListener,
      YAxis axisLeft,
      YAxis axisRight,
      YAxisRenderer axisRendererLeft,
      YAxisRenderer axisRendererRight,
      Transformer leftAxisTransformer,
      Transformer rightAxisTransformer,
      XAxisRenderer xAxisRenderer,
      Matrix4 zoomMatrixBuffer,
      bool customViewPortEnabled,
      bool highlightFullBarEnabled,
      bool drawValueAboveBar,
      bool drawBarShadow,
      bool fitBars,
      List<DrawOrder> drawOrder,
      ChartTransListener chartTransListener)
      : _drawBarShadow = drawBarShadow,
        _highlightFullBarEnabled = highlightFullBarEnabled,
        _drawValueAboveBar = drawValueAboveBar,
        _drawOrder = drawOrder,
        super(
            data,
            highlightForced,
            animator,
            viewPortHandler,
            maxHighlightDistance,
            highLightPerTapEnabled,
            extraLeftOffset,
            extraTopOffset,
            extraRightOffset,
            extraBottomOffset,
            infoBgColor,
            infoPainter,
            xAxis,
            legend,
            rendererSettingFunction,
            selectedListener,
            maxVisibleCount,
            autoScaleMinMaxEnabled,
            pinchZoomEnabled,
            doubleTapToZoomEnabled,
            highlightPerDragEnabled,
            dragXEnabled,
            dragYEnabled,
            scaleXEnabled,
            scaleYEnabled,
            gridBackgroundPaint,
            borderPaint,
            drawGridBackground,
            drawBorders,
            clipValuesToContent,
            minOffset,
            keepPositionOnRotation,
            drawListener,
            axisLeft,
            axisRight,
            axisRendererLeft,
            axisRendererRight,
            leftAxisTransformer,
            rightAxisTransformer,
            xAxisRenderer,
            zoomMatrixBuffer,
            customViewPortEnabled,
            backgroundPaint,
            chartTransListener);

  List<DrawOrder> initDrawOrder() {
    return List()..add(DrawOrder.CANDLE)..add(DrawOrder.BAR)..add(DrawOrder.LINE)..add(DrawOrder.SCATTER);
  }

  @override
  void initDefaultWithData() {
    super.initDefaultWithData();
    _drawOrder ??= initDrawOrder();
    highlighter = CombinedHighlighter(this, this);
    renderer = CombinedChartRenderer(this, animator, viewPortHandler);
    (renderer as CombinedChartRenderer).createRenderers();
    renderer.initBuffers();
  }

  @override
  CombinedData getCombinedData() {
    return getData();
  }

  /// Returns the Highlight object (contains x-index and DataSet index) of the selected value at the given touch
  /// point
  /// inside the CombinedChart.
  ///
  /// @param x
  /// @param y
  /// @return
  @override
  Highlight getHighlightByTouchPoint(double x, double y) {
    if (getCombinedData() == null) {
      return null;
    } else {
      Highlight h = highlighter.getHighlight(x, y);
      if (h == null || !isHighlightFullBarEnabled()) return h;

      // For isHighlightFullBarEnabled, remove stackIndex
      return Highlight(
          x: h.x, y: h.y, xPx: h.xPx, yPx: h.yPx, freeX: h.freeX, freeY: h.freeY, dataSetIndex: h.dataSetIndex, stackIndex: h.stackIndex, axis: h.axis)
        ..dataIndex = h.dataIndex;
    }
  }

  @override
  LineData getLineData() {
    if (getCombinedData() == null) return null;
    return getCombinedData().getLineData();
  }

  @override
  BarData getBarData() {
    if (getCombinedData() == null) return null;
    return getCombinedData().getBarData();
  }

  @override
  ScatterData getScatterData() {
    if (getCombinedData() == null) return null;
    return getCombinedData().getScatterData();
  }

  @override
  CandleData getCandleData() {
    if (getCombinedData() == null) return null;
    return getCombinedData().getCandleData();
  }

  @override
  bool isDrawBarShadowEnabled() {
    return _drawBarShadow;
  }

  @override
  bool isDrawValueAboveBarEnabled() {
    return _drawValueAboveBar;
  }

  /// If set to true, all values are drawn above their bars, instead of below
  /// their top.
  ///
  /// @param enabled
  void setDrawValueAboveBar(bool enabled) {
    _drawValueAboveBar = enabled;
  }

  /// If set to true, a grey area is drawn behind each bar that indicates the
  /// maximum value. Enabling his will reduce performance by about 50%.
  ///
  /// @param enabled
  void setDrawBarShadow(bool enabled) {
    _drawBarShadow = enabled;
  }

  /// Set this to true to make the highlight operation full-bar oriented,
  /// false to make it highlight single values (relevant only for stacked).
  ///
  /// @param enabled
  void setHighlightFullBarEnabled(bool enabled) {
    _highlightFullBarEnabled = enabled;
  }

  /// @return true the highlight operation is be full-bar oriented, false if single-value
  @override
  bool isHighlightFullBarEnabled() {
    return _highlightFullBarEnabled;
  }

  /// Returns the currently set draw order.
  ///
  /// @return
  List<DrawOrder> getDrawOrder() {
    return _drawOrder;
  }

  /// Sets the order in which the provided data objects should be drawn. The
  /// earlier you place them in the provided array, the further they will be in
  /// the background. e.g. if you provide new DrawOrer[] { DrawOrder.BAR,
  /// DrawOrder.LINE }, the bars will be drawn behind the lines.
  ///
  /// @param order
  void setDrawOrder(List<DrawOrder> order) {
    if (order == null || order.length <= 0) return;
    _drawOrder = order;
  }
}
