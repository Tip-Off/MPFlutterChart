import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:mp_chart/mp/chart/candlestick_chart.dart';
import 'package:mp_chart/mp/controller/bar_line_scatter_candle_bubble_controller.dart';
import 'package:mp_chart/mp/core/axis/y_axis.dart';
import 'package:mp_chart/mp/core/common_interfaces.dart';
import 'package:mp_chart/mp/core/data/candle_data.dart';
import 'package:mp_chart/mp/core/functions.dart';
import 'package:mp_chart/mp/core/render/x_axis_renderer.dart';
import 'package:mp_chart/mp/core/render/y_axis_renderer.dart';
import 'package:mp_chart/mp/core/touch_listener.dart';
import 'package:mp_chart/mp/core/chart_trans_listener.dart';
import 'package:mp_chart/mp/core/transformer/transformer.dart';
import 'package:mp_chart/mp/painter/candlestick_chart_painter.dart';
import 'package:mp_chart/mp/core/enums/axis_dependency.dart';

class CandlestickChartController extends BarLineScatterCandleBubbleController<CandlestickChartPainter> {
  double _initialXZoom = 0;
  final int initialXPosition;
  final int initialXRange;

  CandlestickChartController(
      {this.initialXPosition = -1,
      this.initialXRange = 0,
      bool specialMoveEnabled = false,
      bool highlightMagneticSetEnabled = true,
      int maxVisibleCount = 100,
      bool autoScaleMinMaxEnabled = true,
      bool doubleTapToZoomEnabled = true,
      bool highlightPerDragEnabled = true,
      bool dragXEnabled = true,
      bool dragYEnabled = true,
      bool scaleXEnabled = true,
      bool scaleYEnabled = true,
      bool drawGridBackground = false,
      bool drawBorders = false,
      bool clipValuesToContent = false,
      double minOffset = 30.0,
      OnDrawListener? drawListener,
      YAxis? axisLeft,
      YAxis? axisRight,
      YAxisRenderer? axisRendererLeft,
      YAxisRenderer? axisRendererRight,
      Transformer? leftAxisTransformer,
      Transformer? rightAxisTransformer,
      XAxisRenderer? xAxisRenderer,
      bool customViewPortEnabled = false,
      Matrix4? zoomMatrixBuffer,
      bool pinchZoomEnabled = true,
      bool keepPositionOnRotation = false,
      Paint? gridBackgroundPaint,
      Paint? borderPaint,
      Color? backgroundColor,
      Color? gridBackColor,
      Color? borderColor,
      double borderStrokeWidth = 1.0,
      AxisLeftSettingFunction? axisLeftSettingFunction,
      AxisRightSettingFunction? axisRightSettingFunction,
      OnTouchEventListener? touchEventListener,
      String noDataText = 'No chart data available.',
      XAxisSettingFunction? xAxisSettingFunction,
      LegendSettingFunction? legendSettingFunction,
      DataRendererSettingFunction? rendererSettingFunction,
      OnChartValueSelectedListener? selectionListener,
      double maxHighlightDistance = 100.0,
      bool highLightPerTapEnabled = true,
      double extraTopOffset = 0.0,
      double extraRightOffset = 0.0,
      double extraBottomOffset = 0.0,
      double extraLeftOffset = 0.0,
      bool resolveGestureHorizontalConflict = false,
      bool resolveGestureVerticalConflict = false,
      double infoTextSize = 12,
      Color? infoTextColor,
      Color? infoBgColor,
      ChartTransListener? chartTransListener})
      : super(
            specialMoveEnabled: specialMoveEnabled,
            highlightMagneticSetEnabled: highlightMagneticSetEnabled,
            noDataText: noDataText,
            xAxisSettingFunction: xAxisSettingFunction,
            legendSettingFunction: legendSettingFunction,
            rendererSettingFunction: rendererSettingFunction,
            selectionListener: selectionListener,
            maxHighlightDistance: maxHighlightDistance,
            highLightPerTapEnabled: highLightPerTapEnabled,
            extraTopOffset: extraTopOffset,
            extraRightOffset: extraRightOffset,
            extraBottomOffset: extraBottomOffset,
            extraLeftOffset: extraLeftOffset,
            resolveGestureHorizontalConflict: resolveGestureHorizontalConflict,
            resolveGestureVerticalConflict: resolveGestureVerticalConflict,
            infoTextSize: infoTextSize,
            infoTextColor: infoTextColor,
            infoBgColor: infoBgColor,
            maxVisibleCount: maxVisibleCount,
            autoScaleMinMaxEnabled: autoScaleMinMaxEnabled,
            doubleTapToZoomEnabled: doubleTapToZoomEnabled,
            highlightPerDragEnabled: highlightPerDragEnabled,
            dragXEnabled: dragXEnabled,
            dragYEnabled: dragYEnabled,
            scaleXEnabled: scaleXEnabled,
            scaleYEnabled: scaleYEnabled,
            drawGridBackground: drawGridBackground,
            drawBorders: drawBorders,
            clipValuesToContent: clipValuesToContent,
            minOffset: minOffset,
            drawListener: drawListener,
            axisLeft: axisLeft,
            axisRight: axisRight,
            axisRendererLeft: axisRendererLeft,
            axisRendererRight: axisRendererRight,
            leftAxisTransformer: leftAxisTransformer,
            rightAxisTransformer: rightAxisTransformer,
            xAxisRenderer: xAxisRenderer,
            customViewPortEnabled: customViewPortEnabled,
            zoomMatrixBuffer: zoomMatrixBuffer,
            pinchZoomEnabled: pinchZoomEnabled,
            keepPositionOnRotation: keepPositionOnRotation,
            gridBackgroundPaint: gridBackgroundPaint,
            borderPaint: borderPaint,
            backgroundColor: backgroundColor,
            gridBackColor: gridBackColor,
            borderColor: borderColor,
            borderStrokeWidth: borderStrokeWidth,
            axisLeftSettingFunction: axisLeftSettingFunction,
            axisRightSettingFunction: axisRightSettingFunction,
            touchEventListener: touchEventListener,
            chartTransListener: chartTransListener);

  @override
  CandleData? get data => super.data as CandleData?;

  @override
  CandlestickChartState? get state => super.state as CandlestickChartState?;

  @override
  CandlestickChartPainter? get painter => super.painter;

  @override
  void initialPainter() {
    painter = CandlestickChartPainter(
        data!,
        painter != null ? painter!.highlightForced : null,
        animator,
        viewPortHandler!,
        maxHighlightDistance,
        highLightPerTapEnabled,
        extraLeftOffset,
        extraTopOffset,
        extraRightOffset,
        extraBottomOffset,
        infoBgColor!,
        infoPaint!,
        xAxis!,
        legend!,
        rendererSettingFunction!,
        selectionListener!,
        maxVisibleCount,
        autoScaleMinMaxEnabled,
        pinchZoomEnabled,
        doubleTapToZoomEnabled,
        highlightPerDragEnabled,
        dragXEnabled,
        dragYEnabled,
        scaleXEnabled,
        scaleYEnabled,
        gridBackgroundPaint!,
        backgroundPaint!,
        borderPaint!,
        drawGridBackground,
        drawBorders,
        clipValuesToContent,
        minOffset,
        keepPositionOnRotation,
        drawListener!,
        axisLeft!,
        axisRight!,
        axisRendererLeft!,
        axisRendererRight!,
        leftAxisTransformer!,
        rightAxisTransformer!,
        xAxisRenderer!,
        zoomMatrixBuffer!,
        customViewPortEnabled,
        chartTransListener!);

    initialParameters();
  }

  void initialParameters() {
    if (initialXRange > 0) {
      _initialXZoom = _initialXZoom == 1 ? 1 : ((data!.xMax - 1) - data!.xMin).abs() / initialXRange;

      var matrix = painter!.viewPortHandler!.getMatrixTouch();
      painter!.viewPortHandler!.zoom2(_initialXZoom, 0, matrix);
      painter!.viewPortHandler!.refresh(matrix, maxCandles: data!.xMax);

      if (_initialXZoom != 1) {
        moveViewToAnimated(initialXPosition < 0 ? data!.xMax : initialXPosition as double, 0, AxisDependency.LEFT, 50);
      }

      _initialXZoom = 1;
    }
  }

  @override
  CandlestickChartState createRealState() {
    return CandlestickChartState();
  }
}
