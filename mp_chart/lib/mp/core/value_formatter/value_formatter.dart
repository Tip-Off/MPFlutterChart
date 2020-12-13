import 'package:mp_chart/mp/core/axis/axis_base.dart';
import 'package:mp_chart/mp/core/entry/bar_entry.dart';
import 'package:mp_chart/mp/core/entry/candle_entry.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';
import 'package:mp_chart/mp/core/view_port.dart';

abstract class ValueFormatter {
  AxisBase? axisFormatter;

  String getFormattedValue2(double value, AxisBase axis) {
    axisFormatter = axis;
    return getFormattedValue1(value);
  }

  String getFormattedValue3(double value, Entry entry, int dataSetIndex, ViewPortHandler viewPortHandler) {
    return getFormattedValue1(value);
  }

  String getFormattedValue1(double value) {
    return value.toString();
  }

  String getDirectFormattedValue(double value, AxisBase axis) {
    return getAxisLabel(value, axis);
  }

  String getAxisLabel(double value, AxisBase axis) {
    axisFormatter = axis;
    return getFormattedValue1(value);
  }

  String getBarLabel(BarEntry barEntry) {
    return getFormattedValue1(barEntry.y);
  }

  String getBarStackedLabel(double value, BarEntry stackedEntry) {
    return getFormattedValue1(value);
  }

  String getPointLabel(Entry entry) {
    return getFormattedValue1(entry.y);
  }

  String getCandleLabel(CandleEntry candleEntry) {
    return getFormattedValue1(candleEntry.shadowHigh);
  }
}
