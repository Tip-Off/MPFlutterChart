import 'package:flutter/cupertino.dart';
import 'package:mp_chart/mp/chart/chart.dart';
import 'package:mp_chart/mp/core/animator.dart';
import 'package:mp_chart/mp/core/axis/x_axis.dart';
import 'package:mp_chart/mp/core/common_interfaces.dart';
import 'package:mp_chart/mp/core/data/chart_data.dart';
import 'package:mp_chart/mp/core/functions.dart';
import 'package:mp_chart/mp/core/legend/legend.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/utils/painter_utils.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:mp_chart/mp/painter/painter.dart';
import 'package:optimized_gesture_detector/gesture_dectetor.dart';

abstract class Controller<P extends ChartPainter> implements AnimatorUpdateListener {
  ChartState state;
  ChartData data;
  Animator animator;
  P _painter;

  ////// needed
  ViewPortHandler viewPortHandler;
  XAxis xAxis;
  Legend legend;
  OnChartValueSelectedListener selectionListener;

  ////// option
  double maxHighlightDistance;
  bool highLightPerTapEnabled;
  double extraTopOffset, extraRightOffset, extraBottomOffset, extraLeftOffset;

  ////// split child property
  Color infoBgColor;
  TextPainter infoPaint;

  XAxisSettingFunction xAxisSettingFunction;
  LegendSettingFunction legendSettingFunction;
  DataRendererSettingFunction rendererSettingFunction;

  CanDragDownFunction horizontalConflictResolveFunc;
  CanDragDownFunction verticalConflictResolveFunc;

  Controller(
      {this.viewPortHandler,
      this.xAxis,
      this.legend,
      this.selectionListener,
      this.maxHighlightDistance = 100.0,
      this.highLightPerTapEnabled = true,
      this.extraTopOffset = 0.0,
      this.extraRightOffset = 0.0,
      this.extraBottomOffset = 0.0,
      this.extraLeftOffset = 0.0,
      bool resolveGestureHorizontalConflict = false,
      bool resolveGestureVerticalConflict = false,
      double infoTextSize = 12,
      Color infoTextColor,
      this.infoBgColor,
      this.infoPaint,
      String noDataText = "No chart data available.",
      this.xAxisSettingFunction,
      this.legendSettingFunction,
      this.rendererSettingFunction}) {
    animator = ChartAnimatorBySys(this);

    if (infoTextColor == null) {
      infoTextColor = ColorUtils.BLACK;
    }
    infoPaint = PainterUtils.create(null, noDataText, infoTextColor, infoTextSize);
    infoBgColor ??= ColorUtils.WHITE;

    if (maxHighlightDistance == 0.0) {
      maxHighlightDistance = Utils.convertDpToPixel(500);
    }

    this.viewPortHandler ??= initViewPortHandler();
    this.selectionListener ??= initSelectionListener();

    if (resolveGestureHorizontalConflict) {
      horizontalConflictResolveFunc = () => true;
    }

    if (resolveGestureVerticalConflict) {
      verticalConflictResolveFunc = () => true;
    }
  }

  ViewPortHandler initViewPortHandler() => ViewPortHandler();

  XAxis initXAxis() => XAxis();

  Legend initLegend() => Legend();

  OnChartValueSelectedListener initSelectionListener() => null;

  ChartState createChartState() {
    state = createRealState();
    return state;
  }

  ChartState createRealState();

  void doneBeforePainterInit() {
    legend = initLegend();
    if (xAxis == null) {
      xAxis = initXAxis();
    }
    if (legendSettingFunction != null) {
      legendSettingFunction(legend, this);
    }
    if (xAxisSettingFunction != null) {
      xAxisSettingFunction(xAxis, this);
    }
  }

  void initialPainter();

  @override
  void onAnimationUpdate(double x, double y) {
    state?.setStateIfNotDispose();
  }

  @override
  void onRotateUpdate(double angle) {}

  // ignore: unnecessary_getters_setters
  P get painter => _painter;

  // ignore: unnecessary_getters_setters
  set painter(P value) {
    _painter = value;
  }
}
