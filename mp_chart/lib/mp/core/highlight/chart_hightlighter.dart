import 'dart:math';

import 'package:mp_chart/mp/core/data/bar_line_scatter_candle_bubble_data.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_data_set.dart';
import 'package:mp_chart/mp/core/data_provider/bar_line_scatter_candle_bubble_data_provider.dart';
import 'package:mp_chart/mp/core/enums/axis_dependency.dart';
import 'package:mp_chart/mp/core/enums/rounding.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/highlight/i_highlighter.dart';
import 'package:mp_chart/mp/core/poolable/point.dart';

class ChartHighlighter<T extends BarLineScatterCandleBubbleDataProvider> implements IHighlighter {
  /// instance of the data-provider
  late T _provider;

  /// buffer for storing previously highlighted values
  final List<Highlight> _highlightBuffer = <Highlight>[];

  ChartHighlighter(T provider) {
    _provider = provider;
  }

  T get provider => _provider;

  List<Highlight> get highlightBuffer => _highlightBuffer;

  @override
  Highlight? getHighlight(double x, double y) {
    var pos = getValsForTouch(x, y);
    var xVal = pos.x;
    var yVal = pos.y;
    MPPointD.recycleInstance2(pos);
    var high = getHighlightForX(xVal, yVal, x, y);

    return high;
  }

  /// Returns a recyclable MPPointD instance.
  /// Returns the corresponding xPos for a given touch-position in pixels.
  ///
  /// @param x
  /// @param y
  /// @return
  MPPointD getValsForTouch(double x, double y) {
    // take any transformer to determine the x-axis value
    var pos = _provider.getTransformer(AxisDependency.LEFT)!.getValuesByTouchPoint1(x, y);
    return pos;
  }

  /// Returns the corresponding Highlight for a given xVal and x- and y-touch position in pixels.
  ///
  /// @param xVal
  /// @param x
  /// @param y
  /// @return
  Highlight? getHighlightForX(double xVal, double yVal, double x, double y) {
    var closestValues = getHighlightsAtXValue(xVal, x, y);

    if (closestValues.isEmpty) {
      return null;
    }

    var leftAxisMinDist = getMinimumDistance(closestValues, y, AxisDependency.LEFT);
    var rightAxisMinDist = getMinimumDistance(closestValues, y, AxisDependency.RIGHT);

    var axis = leftAxisMinDist < rightAxisMinDist ? AxisDependency.LEFT : AxisDependency.RIGHT;

    var detail = getClosestHighlightByPixel(closestValues, x, y, axis, _provider.getMaxHighlightDistance())!;

    detail.freeX = xVal;
    detail.freeY = yVal;

    return detail;
  }

  /// Returns the minimum distance from a touch value (in pixels) to the
  /// closest value (in pixels) that is displayed in the chart.
  ///
  /// @param closestValues
  /// @param pos
  /// @param axis
  /// @return
  double getMinimumDistance(List<Highlight> closestValues, double pos, AxisDependency axis) {
    var distance = double.infinity;

    for (var i = 0; i < closestValues.length; i++) {
      var high = closestValues[i];

      if (high.axis == axis) {
        var tempDistance = (getHighlightPos(high) - pos).abs();
        if (tempDistance < distance) {
          distance = tempDistance;
        }
      }
    }

    return distance;
  }

  double getHighlightPos(Highlight h) {
    return h.yPx;
  }

  /// Returns a list of Highlight objects representing the entries closest to the given xVal.
  /// The returned list contains two objects per DataSet (closest rounding up, closest rounding down).
  ///
  /// @param xVal the transformed x-value of the x-touch position
  /// @param x    touch position
  /// @param y    touch position
  /// @return
  List<Highlight> getHighlightsAtXValue(double xVal, double x, double y) {
    _highlightBuffer.clear();

    var data = getData()!;

    for (var i = 0, dataSetCount = data.getDataSetCount(); i < dataSetCount; i++) {
      IDataSet dataSet = data.getDataSetByIndex(i)!;

      // don't include DataSets that cannot be highlighted
      if (!dataSet.isHighlightEnabled()) continue;

      _highlightBuffer.addAll(buildHighlights(dataSet, i, xVal, Rounding.CLOSEST));
    }

    return _highlightBuffer;
  }

  /// An array of `Highlight` objects corresponding to the selected xValue and dataSetIndex.
  ///
  /// @param set
  /// @param dataSetIndex
  /// @param xVal
  /// @param rounding
  /// @return
  List<Highlight> buildHighlights(IDataSet set, int dataSetIndex, double xVal, Rounding rounding) {
    var highlights = <Highlight>[];

    //noinspection unchecked
    var entries = set.getEntriesForXValue(xVal);
    if (entries.isEmpty) {
      // Try to find closest x-value and take all entries for that x-value
      final closest = set.getEntryForXValue1(xVal, double.nan, rounding);
      if (closest != null) {
        //noinspection unchecked
        entries = set.getEntriesForXValue(closest.x);
      }
    }

    if (entries.isEmpty) return highlights;

    for (var e in entries) {
      var pixels = _provider.getTransformer(set.getAxisDependency())!.getPixelForValues(e.x, e.y);

      highlights.add(Highlight(x: e.x, y: e.y, xPx: pixels.x, yPx: pixels.y, dataSetIndex: dataSetIndex, axis: set.getAxisDependency()));
    }

    return highlights;
  }

  /// Returns the Highlight of the DataSet that contains the closest value on the
  /// y-axis.
  ///
  /// @param closestValues        contains two Highlight objects per DataSet closest to the selected x-position (determined by
  ///                             rounding up an down)
  /// @param x
  /// @param y
  /// @param axis                 the closest axis
  /// @param minSelectionDistance
  /// @return
  Highlight? getClosestHighlightByPixel(List<Highlight> closestValues, double x, double y, AxisDependency? axis, double minSelectionDistance) {
    Highlight? closest;
    var distance = minSelectionDistance;

    for (var i = 0; i < closestValues.length; i++) {
      var high = closestValues[i];

      if (axis == null || high.axis == axis) {
        var cDistance = getDistance(x, y, high.xPx, high.yPx);
        if (cDistance < distance) {
          closest = high;
          distance = cDistance;
        }
      }
    }

    return closest;
  }

  /// Calculates the distance between the two given points.
  ///
  /// @param x1
  /// @param y1
  /// @param x2
  /// @param y2
  /// @return
  double getDistance(double x1, double y1, double x2, double y2) {
    var x = pow((x1 - x2), 2);
    var y = pow((y1 - y2), 2);
    return sqrt(x + y);
  }

  BarLineScatterCandleBubbleData? getData() {
    return _provider.getData();
  }
}
