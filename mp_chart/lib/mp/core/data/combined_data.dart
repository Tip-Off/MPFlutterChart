import 'package:mp_chart/mp/core/data/bar_data.dart';
import 'package:mp_chart/mp/core/data/bar_line_scatter_candle_bubble_data.dart';
import 'package:mp_chart/mp/core/data/candle_data.dart';
import 'package:mp_chart/mp/core/data/chart_data.dart';
import 'package:mp_chart/mp/core/data/line_data.dart';
import 'package:mp_chart/mp/core/data/scatter_data.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_bar_line_scatter_candle_bubble_data_set.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';

class CombinedData extends BarLineScatterCandleBubbleData<IBarLineScatterCandleBubbleDataSet<Entry>> {
  LineData _lineData;
  BarData _barData;
  ScatterData _scatterData;
  CandleData _candleData;

  CombinedData() : super();

  void setData1(LineData data) {
    _lineData = data;
    notifyDataChanged();
  }

  void setData2(BarData data) {
    _barData = data;
    notifyDataChanged();
  }

  void setData3(ScatterData data) {
    _scatterData = data;
    notifyDataChanged();
  }

  void setData4(CandleData data) {
    _candleData = data;
    notifyDataChanged();
  }

  @override
  void calcMinMax1() {
    dataSets ??= [];
    dataSets.clear();

    yMax = -double.infinity;
    yMin = double.infinity;
    xMax = -double.infinity;
    xMin = double.infinity;

    leftAxisMax = -double.infinity;
    leftAxisMin = double.infinity;
    rightAxisMax = -double.infinity;
    rightAxisMin = double.infinity;

    var allData = getAllData();

    for (ChartData data in allData) {
      data.calcMinMax1();

      List<IBarLineScatterCandleBubbleDataSet<Entry>> sets = data.dataSets;
      dataSets.addAll(sets);

      if (data.getYMax1() > yMax) yMax = data.getYMax1();

      if (data.getYMin1() < yMin) yMin = data.getYMin1();

      if (data.xMax > xMax) xMax = data.xMax;

      if (data.xMin < xMin) xMin = data.xMin;

      if (data.leftAxisMax > leftAxisMax) leftAxisMax = data.leftAxisMax;

      if (data.leftAxisMin < leftAxisMin) leftAxisMin = data.leftAxisMin;

      if (data.rightAxisMax > rightAxisMax) rightAxisMax = data.rightAxisMax;

      if (data.rightAxisMin < rightAxisMin) rightAxisMin = data.rightAxisMin;
    }
  }

  LineData getLineData() {
    return _lineData;
  }

  BarData getBarData() {
    return _barData;
  }

  ScatterData getScatterData() {
    return _scatterData;
  }

  CandleData getCandleData() {
    return _candleData;
  }

  /// Returns all data objects in row: line-bar-scatter-candle-bubble if not null.
  ///
  /// @return
  List<BarLineScatterCandleBubbleData> getAllData() {
    var data = <BarLineScatterCandleBubbleData>[];
    if (_candleData != null) data.add(_candleData);
    if (_lineData != null) data.add(_lineData);
    if (_barData != null) data.add(_barData);
    if (_scatterData != null) data.add(_scatterData);

    return data;
  }

  BarLineScatterCandleBubbleData getDataByIndex(int index) {
    return getAllData()[index];
  }

  @override
  void notifyDataChanged() {
    if (_lineData != null) _lineData.notifyDataChanged();
    if (_barData != null) _barData.notifyDataChanged();
    if (_candleData != null) _candleData.notifyDataChanged();
    if (_scatterData != null) _scatterData.notifyDataChanged();

    calcMinMax1(); // recalculate everything
  }

  /// Get the Entry for a corresponding highlight object
  ///
  /// @param highlight
  /// @return the entry that is highlighted
  @override
  Entry getEntryForHighlight(Highlight highlight) {
    if (highlight.dataIndex >= getAllData().length || highlight.dataIndex < 0) return null;

    ChartData data = getDataByIndex(highlight.dataIndex);

    if (highlight.dataSetIndex >= data.getDataSetCount()) return null;

    // The value of the highlighted entry could be NaN -
    //   if we are not interested in highlighting a specific value.

    if (highlight.dataSetIndex < 0) {
      for (var element in data.dataSets) {
        final entries = element.getEntriesForXValue(highlight.x);
        for (var entry in entries) {
          if (entry.y == highlight.y || highlight.y.isNaN) {
            return entry;
          }
        }
      }
      return null;
    }

    var entries = data.getDataSetByIndex(highlight.dataSetIndex).getEntriesForXValue(highlight.x);
    for (var entry in entries) {
      if (entry.y == highlight.y || highlight.y.isNaN) return entry;
    }

    return null;
  }

  /// Get dataset for highlight
  ///
  /// @param highlight current highlight
  /// @return dataset related to highlight
  IBarLineScatterCandleBubbleDataSet<Entry> getDataSetByHighlight(Highlight highlight) {
    if (highlight.dataIndex >= getAllData().length || highlight.dataIndex < 0) return null;

    var data = getDataByIndex(highlight.dataIndex);

    if (highlight.dataSetIndex >= data.getDataSetCount()) return null;

    return data.dataSets[highlight.dataSetIndex];
  }

  int getDataIndex(ChartData data) {
    return getAllData().indexOf(data);
  }

  @override
  bool removeDataSet1(IBarLineScatterCandleBubbleDataSet<Entry> d) {
    var datas = getAllData();
    var success = false;
    for (ChartData data in datas) {
      if (data.dataSets == null || data.dataSets.isEmpty) {
        continue;
      }

      if (d.runtimeType != data.dataSets[0].runtimeType) {
        continue;
      }

      success = data.removeDataSet1(d);
      if (success) {
        break;
      }
    }
    return success;
  }
}
