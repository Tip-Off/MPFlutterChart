import 'dart:ui';

import 'package:mp_chart/mp/core/data_interfaces/i_scatter_data_set.dart';
import 'package:mp_chart/mp/core/data_set/base_data_set.dart';
import 'package:mp_chart/mp/core/data_set/data_set.dart';
import 'package:mp_chart/mp/core/data_set/line_scatter_candle_radar_data_set.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';

class ScatterDataSet extends LineScatterCandleRadarDataSet<Entry> implements IScatterDataSet {
  /// the size the scattershape will have, in density pixels
  double _shapeSize = 15;

  /// The radius of the hole in the shape (applies to Square, Circle and Triangle)
  /// - default: 0.0
  double _scatterShapeHoleRadius = 0;

  /// Color for the hole in the shape.
  /// Setting to `ColorUtils.COLOR_NONE` will behave as transparent.
  /// - default: ColorUtils.COLOR_NONE
  Color _scatterShapeHoleColor = ColorUtils.COLOR_NONE;

  ScatterDataSet(List<Entry> yVals, String label) : super(yVals, label);

  @override
  DataSet<Entry> copy1() {
    var entries = <Entry>[];
    for (var i = 0; i < values.length; i++) {
      entries.add(values[i].copy());
    }
    var copied = ScatterDataSet(entries, getLabel());
    copy(copied);
    return copied;
  }

  @override
  void copy(BaseDataSet baseDataSet) {
    super.copy(baseDataSet);
    if (baseDataSet is ScatterDataSet) {
      var scatterDataSet = baseDataSet;
      scatterDataSet._shapeSize = _shapeSize;
      scatterDataSet._scatterShapeHoleRadius = _scatterShapeHoleRadius;
      scatterDataSet._scatterShapeHoleColor = _scatterShapeHoleColor;
    }
  }

  /// Sets the size in density pixels the drawn scattershape will have. This
  /// only applies for non custom shapes.
  ///
  /// @param size
  void setScatterShapeSize(double size) {
    _shapeSize = size;
  }

  @override
  double getScatterShapeSize() {
    return _shapeSize;
  }

  /// Sets the radius of the hole in the shape (applies to Square, Circle and Triangle)
  /// Set this to <= 0 to remove holes.
  ///
  /// @param holeRadius
  void setScatterShapeHoleRadius(double holeRadius) {
    _scatterShapeHoleRadius = holeRadius;
  }

  @override
  double getScatterShapeHoleRadius() {
    return _scatterShapeHoleRadius;
  }

  /// Sets the color for the hole in the shape.
  ///
  /// @param holeColor
  void setScatterShapeHoleColor(Color holeColor) {
    _scatterShapeHoleColor = holeColor;
  }

  @override
  Color getScatterShapeHoleColor() {
    return _scatterShapeHoleColor;
  }
}
