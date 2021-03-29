import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_candle_data_set.dart';
import 'package:mp_chart/mp/core/enums/alert_type.dart';

class AlertsUtils {
  static List<Function> getAlertFunctions(AlertType type) {
    switch (type) {
      case AlertType.bull:
        return [_bullPath, _backgroundColor, _bullCentroid, _triangleScale, _bullForegroundColor];
      case AlertType.bear:
        return [_bearPath, _backgroundColor, _bearCentroid, _triangleScale, _bearForegroundColor];
      case AlertType.normal:
        return [_normalPath, _backgroundColor, _normalCentroid, _squareScale, _normalForegroundColor];
      case AlertType.triggered_bull:
        return [_bullPath, _triggeredBackgroundColor, _bullCentroid, _triangleScale, _bullForegroundColor];
      case AlertType.triggered_bear:
        return [_bearPath, _triggeredBackgroundColor, _bearCentroid, _triangleScale, _bearForegroundColor];
      case AlertType.triggered_normal:
        return [_normalPath, _triggeredBackgroundColor, _normalCentroid, _squareScale, _normalForegroundColor];
    }
  }

  static Path _bullPath(double left, double right, double y, double half, double size, double offset) {
    var path = Path();

    path.moveTo(left + half, y - size - offset);
    path.lineTo(left, y - offset);
    path.lineTo(right, y - offset);
    path.close();

    return path;
  }

  static List<double> _bullCentroid(double left, double right, double y, double half, double size, double offset) {
    final centroidX = (left + left + half + right) / 3;
    final centroidY = (y - size - offset + y - offset + y - offset) / 3;

    return [centroidX, centroidY];
  }

  static Color _bullForegroundColor(ICandleDataSet dataSet) => dataSet.getIncreasingColor();

  static Path _bearPath(double left, double right, double y, double half, double size, double offset) {
    var path = Path();

    path.moveTo(left + half, y - offset);
    path.lineTo(left, y - size - offset);
    path.lineTo(right, y - size - offset);
    path.close();

    return path;
  }

  static List<double> _bearCentroid(double left, double right, double y, double half, double size, double offset) {
    final centroidX = (left + left + half + right) / 3;
    final centroidY = (y - offset + y - size - offset + y - size - offset) / 3;

    return [centroidX, centroidY];
  }

  static Color _bearForegroundColor(ICandleDataSet dataSet) => dataSet.getDecreasingColor();

  static Path _normalPath(double left, double right, double y, double half, double size, double offset) {
    var path = Path();

    path.moveTo(left, y - offset);
    path.lineTo(right, y - offset);
    path.lineTo(right, y - size - offset);
    path.lineTo(left, y - size - offset);
    path.close();

    return path;
  }

  static List<double> _normalCentroid(double left, double right, double y, double half, double size, double offset) {
    final centroidX = (left + right) / 2;
    final centroidY = (y - offset + y - size - offset) / 2;

    return [centroidX, centroidY];
  }

  static Color _normalForegroundColor(ICandleDataSet _dataSet) => Colors.purple;

  static Color _backgroundColor() => Colors.white;
  static Color _triggeredBackgroundColor() => Colors.yellowAccent;

  static double _triangleScale() => 0.7;
  static double _squareScale() => 0.8;
}
