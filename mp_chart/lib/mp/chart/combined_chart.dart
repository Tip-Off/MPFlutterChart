import 'package:flutter/widgets.dart';
import 'package:mp_chart/mp/chart/bar_line_scatter_candle_bubble_chart.dart';
import 'package:mp_chart/mp/chart/chart.dart';
import 'package:mp_chart/mp/controller/combined_chart_controller.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_data_set.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/poolable/point.dart';
import 'package:mp_chart/mp/core/touch_listener.dart';
import 'package:mp_chart/mp/core/utils/highlight_utils.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';
import 'package:optimized_gesture_detector/details.dart';
import 'package:optimized_gesture_detector/direction.dart';
import 'package:mp_chart/mp/chart/horizontal_bar_chart.dart';
import 'package:mp_chart/mp/core/enums/x_axis_position.dart';
import 'package:mp_chart/mp/core/enums/axis_dependency.dart';

class CombinedChart
    extends BarLineScatterCandleBubbleChart<CombinedChartController> {
  const CombinedChart(CombinedChartController controller) : super(controller);
}

enum AxisTouchE {
  BOTTOM, TOP, LEFT, RIGHT, NO_AXIS
}

class AxisEnabled {
  final bool botton;
  final bool top;
  final bool left;
  final bool right;

  AxisEnabled({
    this.botton = false,
    this.top = false,
    this.left = false,
    this.right = false,
  });
}

class _AxisTouch {
  final Rect validArea;
  final Offset point;
  final AxisEnabled axisEnabled;

  _AxisTouch(this.validArea, this.point, this.axisEnabled);

  AxisTouchE calculate() {

    if (validArea.contains(point)) {
      return AxisTouchE.NO_AXIS;
    }

    if (point.dy > validArea.bottom && axisEnabled.botton) {
      return AxisTouchE.BOTTOM;
    }

    if (point.dx > validArea.right && axisEnabled.right) {
      return AxisTouchE.RIGHT;
    }

    if (point.dy < validArea.top && axisEnabled.top) {
      return AxisTouchE.TOP;
    }

    if (point.dx < validArea.left && axisEnabled.left) {
      return AxisTouchE.LEFT;
    }
    return AxisTouchE.NO_AXIS;
  }

}

class CombinedChartState extends ChartState<CombinedChart> {
  IDataSet _closestDataSetToTouch;

  Highlight lastHighlighted;
  double _curX = 0.0;
  double _curY = 0.0;
  double _scale = -1.0;

  bool _startInside = true;

  MPPointF _getTrans(double x, double y) {
    return Utils.local2Chart(widget.controller, x, y, inverted: _inverted());
  }

  MPPointF _getTouchValue(TouchValueType type, double screenX, double screenY,
      double localX, localY) {
    if (type == TouchValueType.CHART) {
      return _getTrans(localX, localY);
    } else if (type == TouchValueType.SCREEN) {
      return MPPointF.getInstance1(screenX, screenY);
    } else {
      return MPPointF.getInstance1(localX, localY);
    }
  }

  bool _inverted() {
    var res = (_closestDataSetToTouch == null &&
        widget.controller.painter.isAnyAxisInverted()) ||
        (_closestDataSetToTouch != null &&
            widget.controller.painter
                .isInverted(_closestDataSetToTouch.getAxisDependency()));
    return res;
  }

  @override
  void onTapDown(TapDownDetails details) {
    widget.controller.stopDeceleration();
    _curX = details.localPosition.dx;
    _curY = details.localPosition.dy;
    _closestDataSetToTouch = widget.controller.painter.getDataSetByTouchPoint(
        details.localPosition.dx, details.localPosition.dy);
    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.localPosition.dx,
          details.localPosition.dy);
      widget.controller.touchEventListener.onTapDown(point.x, point.y);
    }
  }

  void _specialSingleTapUp(TapUpDetails details) {
    if (widget.controller.specialMoveEnabled) {
      return;
    }

    if (widget.controller.painter.highLightPerTapEnabled) {
      Highlight h = widget.controller.painter.getHighlightByTouchPoint(
          details.localPosition.dx, details.localPosition.dy);
      lastHighlighted = HighlightUtils.performHighlight(
          widget.controller.painter, h, lastHighlighted);
      setStateIfNotDispose();
    } else {
      lastHighlighted = null;
    }
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    _specialSingleTapUp(details);

    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.localPosition.dx,
          details.localPosition.dy);
      widget.controller.touchEventListener.onSingleTapUp(point.x, point.y);
    }
  }

  bool tapInValidArea(double x, double y) {
    var validArea = widget.controller.painter.viewPortHandler.contentRect;
    return validArea.contains(Offset(x, y));
  }

  AxisEnabled get axisEnabled {
    var xAxisPosition = widget.controller.xAxis.position;
    return AxisEnabled(
        botton: xAxisPosition == XAxisPosition.BOTH_SIDED || xAxisPosition == XAxisPosition.BOTTOM,
        top: xAxisPosition == XAxisPosition.BOTH_SIDED || xAxisPosition == XAxisPosition.TOP,
        left: widget.controller.axisLeft.enabled,
        right: widget.controller.axisRight.enabled
    );
  }

  bool _specialDoubleTapUp(TapUpDetails details) {
    if (!widget.controller.specialMoveEnabled) {
      return false;
    }

    if (lastHighlighted != null) {
      lastHighlighted = null;
      setStateIfNotDispose();
      return true;
    }

    if (widget.controller.painter.doubleTapToZoomEnabled &&
        widget.controller.painter.getData().getEntryCount() > 0) {
      MPPointF trans =
      _getTrans(details.localPosition.dx, details.localPosition.dy);
      widget.controller.painter.zoom(
          widget.controller.painter.scaleXEnabled ? 1.2 : 1,
          widget.controller.painter.scaleYEnabled ? 1.2 : 1,
          trans.x,
          trans.y);
      setStateIfNotDispose();
      MPPointF.recycleInstance(trans);
    }
    if (widget.controller.painter.highLightPerTapEnabled) {
      Highlight h = widget.controller.painter.getHighlightByTouchPoint(
          details.localPosition.dx, details.localPosition.dy);

      if (h != null) {
        h.highlightX = widget.controller.getValuesByTouchPoint(details.localPosition.dx, details.localPosition.dy, AxisDependency.LEFT).x;
        h.highlightY = widget.controller.getValuesByTouchPoint(details.localPosition.dx, details.localPosition.dy, AxisDependency.LEFT).y;
      }

      lastHighlighted = HighlightUtils.performHighlight(
          widget.controller.painter, h, lastHighlighted);
      setStateIfNotDispose();
    } else {
      lastHighlighted = null;
    }

    return true;
  }

  @override
  void onDoubleTapUp(TapUpDetails details) {
    widget.controller.stopDeceleration();

    var specialDoubleTapUp = _specialDoubleTapUp(details);
    if (specialDoubleTapUp) {
      return;
    }

    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.localPosition.dx,
          details.localPosition.dy);
      widget.controller.touchEventListener.onDoubleTapUp(point.x, point.y);
    }
  }

  @override
  void onMoveStart(OpsMoveStartDetails details) {
    widget.controller.stopDeceleration();

    _curX = details.localPoint.dx;
    _curY = details.localPoint.dy;

    defineIfStartInside(_curX, _curY);

    if (widget.controller.specialMoveEnabled) {
      return;
    }

    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPoint.dx,
          details.globalPoint.dy,
          details.localPoint.dx,
          details.localPoint.dy);
      widget.controller.touchEventListener.onMoveStart(point.x, point.y);
    }
  }

  void defineIfStartInside(double x, double y) {
    _startInside = tapInValidArea(x, y);
  }

  bool tryScaleUsingAxis(double dx, double dy) {
    if (_startInside) {
      return false;
    }

    var rect = widget.controller.painter.viewPortHandler.contentRect;
    var offset = Offset(dx, dy);

    var touch = _AxisTouch(rect, offset, axisEnabled);
    var axis = touch.calculate();

    if (axis == AxisTouchE.BOTTOM || axis == AxisTouchE.TOP) {
      var ndx = dx - _curX;
      var scale = 1 + (ndx / 100);

      var trans = _getTrans(_curX, _curY);
      var h = widget.controller.painter.viewPortHandler;

      bool canZoomMoreX = scale < 1 ? h.canZoomOutMoreX() : h.canZoomInMoreX();
      widget.controller.painter
          .zoom(canZoomMoreX ? scale : 1, 1, trans.x, trans.y);

      setStateIfNotDispose();
      _curX = dx;

      return true;
    }

    return false;
  }

  bool _canMove() {
    return (widget.controller.specialMoveEnabled && widget.controller.painter.highlightPerDragEnabled && lastHighlighted != null)
        || (!widget.controller.specialMoveEnabled && widget.controller.painter.highlightPerDragEnabled);
  }

  bool _specialMove(OpsMoveUpdateDetails details) {
    if (_canMove()) {
      final highlighted = widget.controller.painter.getHighlightByTouchPoint(
          details.localPoint.dx, details.localPoint.dy);

      if (widget.controller.highlightMagneticSetEnabled) {
        highlighted.freeX = double.nan;
        highlighted.freeY = double.nan;
      }

      highlighted.highlightX = lastHighlighted.highlightX;
      highlighted.highlightY = lastHighlighted.highlightY;

      if (highlighted?.x != lastHighlighted.x) {
        highlighted.highlightX = widget.controller.getValuesByTouchPoint(details.localPoint.dx, details.localPoint.dy, AxisDependency.LEFT).x;
      }

      highlighted.highlightY = widget.controller.getValuesByTouchPoint(details.localPoint.dx, details.localPoint.dy, AxisDependency.LEFT).y;

      if (highlighted?.equalTo(lastHighlighted) == false) {
        lastHighlighted = HighlightUtils.performHighlight(
            widget.controller.painter, highlighted, lastHighlighted);
        setStateIfNotDispose();
      }
      return widget.controller.specialMoveEnabled;
    }
    return false;
  }

  @override
  void onMoveUpdate(OpsMoveUpdateDetails details) {
    var scaled = tryScaleUsingAxis(details.localPoint.dx, details.localPoint.dy);
    if (scaled) {
      return;
    }

    var specialMoved = _specialMove(details);
    if (specialMoved) {
      return;
    }

    var dx = details.localPoint.dx - _curX;
    var dy = details.localPoint.dy - _curY;
    if (widget.controller.painter.dragYEnabled &&
        widget.controller.painter.dragXEnabled) {
      if (_inverted()) {
        /// if there is an inverted horizontalbarchart
        if (widget is HorizontalBarChart) {
          dx = -dx;
        } else {
          dy = -dy;
        }
      }
      widget.controller.painter.translate(dx, dy);
      if (widget.controller.touchEventListener != null) {
        var point = _getTouchValue(
            widget.controller.touchEventListener.valueType(),
            details.globalPoint.dx,
            details.globalPoint.dy,
            details.localPoint.dx,
            details.localPoint.dy);
        widget.controller.touchEventListener.onMoveUpdate(point.x, point.y);
      }
      setStateIfNotDispose();
    } else {
      if (widget.controller.painter.dragXEnabled) {
        if (_inverted()) {
          /// if there is an inverted horizontalbarchart
          if (widget is HorizontalBarChart) {
            dx = -dx;
          } else {
            dy = -dy;
          }
        }
        widget.controller.painter.translate(dx, 0.0);
        if (widget.controller.touchEventListener != null) {
          var point = _getTouchValue(
              widget.controller.touchEventListener.valueType(),
              details.globalPoint.dx,
              details.globalPoint.dy,
              details.localPoint.dx,
              details.localPoint.dy);
          widget.controller.touchEventListener.onMoveUpdate(point.x, point.y);
        }
        setStateIfNotDispose();
      } else if (widget.controller.painter.dragYEnabled) {
        if (_inverted()) {
          /// if there is an inverted horizontalbarchart
          if (widget is HorizontalBarChart) {
            dx = -dx;
          } else {
            dy = -dy;
          }
        }
        widget.controller.painter.translate(0.0, dy);
        if (widget.controller.touchEventListener != null) {
          var point = _getTouchValue(
              widget.controller.touchEventListener.valueType(),
              details.globalPoint.dx,
              details.globalPoint.dy,
              details.localPoint.dx,
              details.localPoint.dy);
          widget.controller.touchEventListener.onMoveUpdate(point.x, point.y);
        }
        setStateIfNotDispose();
      }
    }
    _curX = details.localPoint.dx;
    _curY = details.localPoint.dy;
  }

  @override
  void onMoveEnd(OpsMoveEndDetails details) {
    if (_canMove()) {
      return;
    }

    widget.controller
      ..stopDeceleration()
      ..setDecelerationVelocity(details.velocity.pixelsPerSecond)
      ..computeScroll();

    if (!_startInside || widget.controller.specialMoveEnabled) {
      return;
    }

    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPoint.dx,
          details.globalPoint.dy,
          details.localPoint.dx,
          details.localPoint.dy);
      widget.controller.touchEventListener.onMoveEnd(point.x, point.y);
    }
  }

  @override
  void onScaleStart(OpsScaleStartDetails details) {
    widget.controller.stopDeceleration();
    _curX = details.localPoint.dx;
    _curY = details.localPoint.dy;
    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPoint.dx,
          details.globalPoint.dy,
          details.localPoint.dx,
          details.localPoint.dy);
      widget.controller.touchEventListener.onScaleStart(point.x, point.y);
    }
  }

  @override
  void onScaleUpdate(OpsScaleUpdateDetails details) {
    var pinchZoomEnabled = widget.controller.pinchZoomEnabled;
    var isYDirection = details.mainDirection == Direction.Y;
    if (_scale == -1.0) {
      if (pinchZoomEnabled) {
        _scale = details.scale;
      } else {
        _scale = isYDirection ? details.verticalScale : details.horizontalScale;
      }
      return;
    }

    var scale = 1.0;
    if (pinchZoomEnabled) {
      scale = details.scale / _scale;
    } else {
      scale = isYDirection
          ? details.verticalScale / _scale
          : details.horizontalScale / _scale;
    }
    MPPointF trans = _getTrans(_curX, _curY);
    var h = widget.controller.painter.viewPortHandler;
    scale = Utils.optimizeScale(scale);
    if (pinchZoomEnabled) {
      bool canZoomMoreX = scale < 1 ? h.canZoomOutMoreX() : h.canZoomInMoreX();
      bool canZoomMoreY = scale < 1 ? h.canZoomOutMoreY() : h.canZoomInMoreY();
      widget.controller.painter.zoom(
          canZoomMoreX ? scale : 1, canZoomMoreY ? scale : 1, trans.x, trans.y);
      if (widget.controller.touchEventListener != null) {
        var point = _getTouchValue(
            widget.controller.touchEventListener.valueType(),
            details.globalFocalPoint.dx,
            details.globalFocalPoint.dy,
            details.localFocalPoint.dx,
            details.localFocalPoint.dy);
        widget.controller.touchEventListener.onScaleUpdate(point.x, point.y);
      }
      setStateIfNotDispose();
    } else {
      if (isYDirection) {
        if (widget.controller.painter.scaleYEnabled) {
          bool canZoomMoreY =
          scale < 1 ? h.canZoomOutMoreY() : h.canZoomInMoreY();
          widget.controller.painter
              .zoom(1, canZoomMoreY ? scale : 1, trans.x, trans.y);
          if (widget.controller.touchEventListener != null) {
            var point = _getTouchValue(
                widget.controller.touchEventListener.valueType(),
                details.globalFocalPoint.dx,
                details.globalFocalPoint.dy,
                details.localFocalPoint.dx,
                details.localFocalPoint.dy);
            widget.controller.touchEventListener
                .onScaleUpdate(point.x, point.y);
          }
          setStateIfNotDispose();
        }
      } else {
        if (widget.controller.painter.scaleXEnabled) {
          bool canZoomMoreX =
          scale < 1 ? h.canZoomOutMoreX() : h.canZoomInMoreX();
          widget.controller.painter
              .zoom(canZoomMoreX ? scale : 1, 1, trans.x, trans.y);
          if (widget.controller.touchEventListener != null) {
            var point = _getTouchValue(
                widget.controller.touchEventListener.valueType(),
                details.globalFocalPoint.dx,
                details.globalFocalPoint.dy,
                details.localFocalPoint.dx,
                details.localFocalPoint.dy);
            widget.controller.touchEventListener
                .onScaleUpdate(point.x, point.y);
          }
          setStateIfNotDispose();
        }
      }
    }
    MPPointF.recycleInstance(trans);

    if (pinchZoomEnabled) {
      _scale = details.scale;
    } else {
      _scale = isYDirection ? details.verticalScale : details.horizontalScale;
    }
  }

  @override
  void onScaleEnd(OpsScaleEndDetails details) {
    _scale = -1.0;
    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPoint.dx,
          details.globalPoint.dy,
          details.localPoint.dx,
          details.localPoint.dy);
      widget.controller.touchEventListener.onScaleEnd(point.x, point.y);
    }
  }

  void onDragStart(LongPressStartDetails details) {
    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.localPosition.dx,
          details.localPosition.dy);
      widget.controller.touchEventListener.onDragStart(point.x, point.y);
    }
  }

  void onDragUpdate(LongPressMoveUpdateDetails details) {
    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.localPosition.dx,
          details.localPosition.dy);
      widget.controller.touchEventListener.onDragUpdate(point.x, point.y);
    }
  }

  void onDragEnd(LongPressEndDetails details) {
    if (widget.controller.touchEventListener != null) {
      var point = _getTouchValue(
          widget.controller.touchEventListener.valueType(),
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.localPosition.dx,
          details.localPosition.dy);
      widget.controller.touchEventListener.onDragEnd(point.x, point.y);
    }
  }

  @override
  void updatePainter() {
    if (widget.controller.painter.getData() != null &&
        widget.controller.painter.getData().dataSets != null &&
        widget.controller.painter.getData().dataSets.length > 0)
      widget.controller.painter.highlightValue6(lastHighlighted, false);
  }
}
