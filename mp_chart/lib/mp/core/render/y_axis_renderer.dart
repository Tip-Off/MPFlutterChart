import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:mp_chart/mp/core/axis/y_axis.dart';
import 'package:mp_chart/mp/core/enums/axis_dependency.dart';
import 'package:mp_chart/mp/core/enums/limit_label_postion.dart';
import 'package:mp_chart/mp/core/enums/y_axis_label_position.dart';
import 'package:mp_chart/mp/core/render/axis_renderer.dart';
import 'package:mp_chart/mp/core/transformer/transformer.dart';
import 'package:mp_chart/mp/core/utils/canvas_utils.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/utils/painter_utils.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:flutter/material.dart';
import 'package:mp_chart/mp/dashed/image_store.dart';
import 'package:mp_chart/mp/dashed/painter.dart';

class YAxisRenderer extends AxisRenderer {
  late YAxis _yAxis;

  late Paint _zeroLinePaint;

  YAxisRenderer(ViewPortHandler? viewPortHandler, YAxis yAxis, Transformer trans) : super(viewPortHandler, trans, yAxis) {
    _yAxis = yAxis;

    if (viewPortHandler != null) {
      axisLabelPaint = PainterUtils.create(axisLabelPaint, null, ColorUtils.BLACK, Utils.convertDpToPixel(10));

      _zeroLinePaint = Paint()
        ..color = ColorUtils.GRAY
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
    }
  }

  YAxis get yAxis => _yAxis;

  // ignore: unnecessary_getters_setters
  Paint get zeroLinePaint => _zeroLinePaint;

  // ignore: unnecessary_getters_setters
  set zeroLinePaint(Paint value) {
    _zeroLinePaint = value;
  }

  /// draws the y-axis labels to the screen
  @override
  void renderAxisLabels(Canvas c) {
    if (!_yAxis.enabled || !_yAxis.drawLabels) return;

    var positions = getTransformedPositions();

    var dependency = _yAxis.axisDependency;
    var labelPosition = _yAxis.position;

    var xPos = 0.0;

    axisLabelPaint = PainterUtils.create(axisLabelPaint, null, _yAxis.textColor, _yAxis.textSize,
        fontFamily: _yAxis.typeface?.fontFamily, fontWeight: _yAxis.typeface?.fontWeight ?? FontWeight.w400);
    if (dependency == AxisDependency.LEFT) {
      if (labelPosition == YAxisLabelPosition.OUTSIDE_CHART) {
        xPos = viewPortHandler!.offsetLeft();
      } else {
        xPos = viewPortHandler!.offsetLeft();
      }
    } else {
      if (labelPosition == YAxisLabelPosition.OUTSIDE_CHART) {
        xPos = viewPortHandler!.contentRight();
      } else {
        xPos = viewPortHandler!.contentRight();
      }
    }

    drawYLabels(c, xPos, positions, dependency, labelPosition);
  }

  @override
  void renderAxisLine(Canvas c) {
    if (!_yAxis.enabled || !_yAxis.drawAxisLine) return;

    axisLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _yAxis.axisLineColor
      ..strokeWidth = _yAxis.axisLineWidth;

    if (_yAxis.isAxisLineDashedEnabled()) {
      axisLinePaint = Painter.get(ImageStore.getVerticalDashed(), strokeWidth: _yAxis.gridLineWidth, color: _yAxis.gridColor);
    }

    _renderGridLinesPath.reset();

    if (_yAxis.axisDependency == AxisDependency.LEFT) {
      _renderGridLinesPath.moveTo(viewPortHandler!.contentLeft(), viewPortHandler!.contentTop());
      _renderGridLinesPath.lineTo(viewPortHandler!.contentLeft(), viewPortHandler!.contentBottom());

      c.drawPath(_renderGridLinesPath, axisLinePaint!);
    } else {
      _renderGridLinesPath.moveTo(viewPortHandler!.contentRight(), viewPortHandler!.contentTop());
      _renderGridLinesPath.lineTo(viewPortHandler!.contentRight(), viewPortHandler!.contentBottom());

      c.drawPath(_renderGridLinesPath, axisLinePaint!);
    }
  }

  /// draws the y-labels on the specified x-position
  ///
  /// @param fixedPosition
  /// @param positions
  void drawYLabels(
    Canvas c,
    double fixedPosition,
    List<double> positions,
    AxisDependency axisDependency,
    YAxisLabelPosition position,
  ) {
    final from = _yAxis.drawBottomYLabelEntry ? 0 : 1;
    final to = _yAxis.drawTopYLabelEntry ? _yAxis.entryCount : (_yAxis.entryCount - 1);

    // draw
    for (var i = from; i < to; i++) {
      var text = _yAxis.getFormattedLabel(i);

      axisLabelPaint!.text = TextSpan(text: text, style: axisLabelPaint!.text!.style);
      axisLabelPaint!.layout();
      if (axisDependency == AxisDependency.LEFT) {
        if (position == YAxisLabelPosition.OUTSIDE_CHART) {
          axisLabelPaint!.paint(c, Offset(fixedPosition - axisLabelPaint!.width, positions[i * 2 + 1] - axisLabelPaint!.height / 2));
        } else {
          axisLabelPaint!.paint(c, Offset(fixedPosition, positions[i * 2 + 1] - axisLabelPaint!.height / 2));
        }
      } else {
        if (position == YAxisLabelPosition.OUTSIDE_CHART) {
          axisLabelPaint!.paint(c, Offset(fixedPosition, positions[i * 2 + 1] - axisLabelPaint!.height / 2));
        } else {
          axisLabelPaint!.paint(c, Offset(fixedPosition - axisLabelPaint!.width, positions[i * 2 + 1] - axisLabelPaint!.height / 2));
        }
      }
    }
  }

  final Path _renderGridLinesPath = Path();

  @override
  void renderGridLines(Canvas c) {
    if (!_yAxis.enabled) return;

    if (_yAxis.drawGridLines) {
      c.save();
      c.clipRect(getGridClippingRect());

      var positions = getTransformedPositions();

      gridPaint!
        ..style = PaintingStyle.stroke
        ..color = _yAxis.gridColor
        ..strokeWidth = _yAxis.gridLineWidth;

      if (_yAxis.isGridDashedEnabled()) {
        gridPaint = Painter.get(ImageStore.getHorizontalDashed(), strokeWidth: _yAxis.gridLineWidth, color: _yAxis.gridColor);
      }

      var gridLinePath = _renderGridLinesPath;
      gridLinePath.reset();

      // draw the grid
      for (var i = 0; i < positions.length; i += 2) {
        c.drawPath(linePath(gridLinePath, i, positions), gridPaint!);

        gridLinePath.reset();
      }

      c.restore();
    }
  }

  Rect _gridClippingRect = Rect.zero;

  Rect getGridClippingRect() {
    _gridClippingRect = Rect.fromLTRB(viewPortHandler!.getContentRect().left, viewPortHandler!.getContentRect().top,
        viewPortHandler!.getContentRect().right + axis.gridLineWidth, viewPortHandler!.getContentRect().bottom + axis.gridLineWidth);
    return _gridClippingRect;
  }

  /// Calculates the path for a grid line.
  ///
  /// @param p
  /// @param i
  /// @param positions
  /// @return
  Path linePath(Path p, int i, List<double> positions) {
    p.moveTo(viewPortHandler!.offsetLeft(), positions[i + 1]);
    p.lineTo(viewPortHandler!.contentRight(), positions[i + 1]);

    return p;
  }

  List<double> mGetTransformedPositionsBuffer = List.filled(2, 0.0);

  /// Transforms the values contained in the axis entries to screen pixels and returns them in form of a double array
  /// of x- and y-coordinates.
  ///
  /// @return
  List<double> getTransformedPositions() {
    if (mGetTransformedPositionsBuffer.length != _yAxis.entryCount * 2) {
      mGetTransformedPositionsBuffer = List.filled(_yAxis.entryCount * 2, 0.0);
    }
    var positions = mGetTransformedPositionsBuffer;

    for (var i = 0; i < positions.length; i += 2) {
      // only fill y values, x values are not needed for y-labels
      positions[i] = 0.0;
      positions[i + 1] = _yAxis.entries[i ~/ 2];
    }

    trans.pointValuesToPixel(positions);
    return positions;
  }

  final Path _renderLimitLines = Path();
  final List<double> _renderLimitLinesBuffer = List.filled(2, 0.0);
  Rect _limitLineClippingRect = Rect.zero;

  // ignore: unnecessary_getters_setters
  Rect get limitLineClippingRect => _limitLineClippingRect;

  // ignore: unnecessary_getters_setters
  set limitLineClippingRect(Rect value) {
    _limitLineClippingRect = value;
  }

  /// Draws the LimitLines associated with this axis to the screen.
  ///
  /// @param c
  @override
  void renderLimitLines(Canvas c) {
    var limitLines = _yAxis.getLimitLines();

    if (limitLines.isEmpty) return;

    var pts = _renderLimitLinesBuffer;
    pts[0] = 0;
    pts[1] = 0;
    var limitLinePath = _renderLimitLines;
    limitLinePath.reset();

    for (var i = 0; i < limitLines.length; i++) {
      var l = limitLines[i];

      if (!l.enabled) continue;

      c.save();
      _limitLineClippingRect = Rect.fromLTRB(viewPortHandler!.getContentRect().left, viewPortHandler!.getContentRect().top,
          viewPortHandler!.getContentRect().right + l.lineWidth, viewPortHandler!.getContentRect().bottom + l.lineWidth);
      c.clipRect(_limitLineClippingRect);

      limitLinePaint!
        ..style = PaintingStyle.stroke
        ..strokeWidth = l.lineWidth
        ..color = l.lineColor;

      pts[1] = l.limit;

      trans.pointValuesToPixel(pts);

      limitLinePath.moveTo(viewPortHandler!.contentLeft(), pts[1]);
      limitLinePath.lineTo(viewPortHandler!.contentRight(), pts[1]);

      if (l.isDashedLineEnabled()) {
        limitLinePaint = Painter.get(ImageStore.getHorizontalDashed(), strokeWidth: l.lineWidth, color: l.lineColor);
      }

      c.drawPath(limitLinePath, limitLinePaint!);

      limitLinePath.reset();

      var label = l.label;

      // if drawing the limit-value label is enabled
      if (label != null && label.isNotEmpty) {
        var painter = PainterUtils.create(null, label, l.textColor, l.textSize, fontWeight: l.typeface!.fontWeight, fontFamily: l.typeface?.fontFamily);
        final labelLineHeight = Utils.calcTextHeight(painter, label).toDouble();
        var xOffset = Utils.convertDpToPixel(4) + l.xOffset;
        var yOffset = l.lineWidth + labelLineHeight + l.yOffset;
        painter.layout();
        final position = l.labelPosition;
        if (position == LimitLabelPosition.RIGHT_TOP) {
          var offset = Offset(viewPortHandler!.contentRight() - xOffset - painter.width, pts[1] - yOffset + labelLineHeight - painter.height);
          CanvasUtils.renderLimitLabelBackground(c, painter, offset, l);
          painter.paint(c, offset);
        } else if (position == LimitLabelPosition.RIGHT_BOTTOM) {
          var offset = Offset(viewPortHandler!.contentRight() - xOffset - painter.width, pts[1] + yOffset - painter.height);
          CanvasUtils.renderLimitLabelBackground(c, painter, offset, l);
          painter.paint(c, offset);
        } else if (position == LimitLabelPosition.RIGHT_CENTER) {
          var offset = Offset(viewPortHandler!.contentRight() - xOffset - painter.width, pts[1] - (l.lineWidth + labelLineHeight) / 2);
          CanvasUtils.renderLimitLabelBackground(c, painter, offset, l);
          painter.paint(c, offset);
        } else if (position == LimitLabelPosition.LEFT_CENTER) {
          var offset = Offset(viewPortHandler!.contentLeft() + xOffset, pts[1] - (l.lineWidth + labelLineHeight) / 2);
          CanvasUtils.renderLimitLabelBackground(c, painter, offset, l);
          painter.paint(c, offset);
        } else if (position == LimitLabelPosition.LEFT_TOP) {
          var offset = Offset(viewPortHandler!.contentLeft() + xOffset, pts[1] - yOffset + labelLineHeight - painter.height);
          CanvasUtils.renderLimitLabelBackground(c, painter, offset, l);
          painter.paint(c, offset);
        } else {
          var offset = Offset(viewPortHandler!.offsetLeft() + xOffset, pts[1] + yOffset - painter.height);
          CanvasUtils.renderLimitLabelBackground(c, painter, offset, l);
          painter.paint(c, offset);
        }
      }

      c.restore();
    }
  }

  @override
  void renderHighlight(Canvas c, AxisHighlightRenderOpt opt) {
    var dependency = _yAxis.axisDependency;
    var labelPosition = _yAxis.position;

    var xPos = 0.0;
    if (dependency == AxisDependency.LEFT) {
      if (labelPosition == YAxisLabelPosition.OUTSIDE_CHART) {
        xPos = viewPortHandler!.offsetLeft() - axisLabelPaint!.width;
      } else {
        xPos = viewPortHandler!.offsetLeft();
      }
    } else {
      if (labelPosition == YAxisLabelPosition.OUTSIDE_CHART) {
        xPos = viewPortHandler!.contentRight();
      } else {
        xPos = viewPortHandler!.contentRight() - axisLabelPaint!.width;
      }
    }

    _drawYHighlightLabels(c, xPos, opt, _yAxis.axisDependency, _yAxis.position);
  }

  void _drawYHighlightLabels(
    Canvas c,
    double fixedPosition,
    AxisHighlightRenderOpt opt,
    AxisDependency axisDependency,
    YAxisLabelPosition position,
  ) {
    axisLabelPaint!.text = TextSpan(
      text: _yAxis.getDirectFormattedLabel(opt.axisPoint.y),
      style: axisLabelPaint!.text!.style!.copyWith(color: Colors.white),
    );

    axisLabelPaint!.layout();

    var labelPosition = Offset(0, 0);
    if (axisDependency == AxisDependency.LEFT) {
      if (position == YAxisLabelPosition.OUTSIDE_CHART) {
        labelPosition = Offset(fixedPosition - axisLabelPaint!.width, opt.screenPoint.y - axisLabelPaint!.height / 2);
      } else {
        labelPosition = Offset(fixedPosition, opt.screenPoint.y - axisLabelPaint!.height / 2);
      }
    } else {
      if (position == YAxisLabelPosition.OUTSIDE_CHART) {
        labelPosition = Offset(fixedPosition, opt.screenPoint.y - axisLabelPaint!.height / 2);
      } else {
        labelPosition = Offset(fixedPosition, opt.screenPoint.y - axisLabelPaint!.height / 2);
      }
    }

    var validPoint = Offset(viewPortHandler!.getContentCenter().x, labelPosition.dy);

    if (viewPortHandler!.getContentRect().contains(validPoint)) {
      var paint = Paint()..color = Colors.deepOrange;

      c.drawRect(Rect.fromLTWH(labelPosition.dx - 1, labelPosition.dy - 1, axisLabelPaint!.width + 2, axisLabelPaint!.height + 2), paint);

      labelPosition = labelPosition.translate(-1, 0.5);
      axisLabelPaint!.paint(c, labelPosition);
    }
  }

  // ignore: unnecessary_getters_setters
  Rect get gridClippingRect => _gridClippingRect;

  // ignore: unnecessary_getters_setters
  set gridClippingRect(Rect value) {
    _gridClippingRect = value;
  }
}
