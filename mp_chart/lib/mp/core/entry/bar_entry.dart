import 'package:mp_chart/mp/core/entry/entry.dart';
import 'package:mp_chart/mp/core/enums/alert_type.dart';

import 'package:mp_chart/mp/core/range.dart';

class BarEntry extends Entry {
  /// the values the stacked barchart holds
  List<double>? _yVals;

  /// the ranges for the individual stack values - automatically calculated
  late List<Range> _ranges;

  /// the sum of all negative values this entry (if stacked) contains
  late double _negativeSum;

  /// the sum of all positive values this entry (if stacked) contains
  late double _positiveSum;

  BarEntry({required double x, required double y, AlertType? alertType, Object? data}) : super(x: x, y: y, alertType: alertType, data: data);

  BarEntry.fromListYVals({required double x, List<double>? vals, AlertType? alertType, Object? data})
      : super(x: x, y: calcSum(vals), alertType: alertType, data: data) {
    _yVals = vals;
    calcPosNegSum();
    calcRanges();
  }

  @override
  BarEntry copy() {
    var copied = BarEntry(x: x, y: y, data: mData);
    copied.setVals(_yVals);
    return copied;
  }

  List<double>? get yVals => _yVals;

  /// Set the array of values this BarEntry should represent.
  ///
  /// @param vals
  void setVals(List<double>? vals) {
    y = calcSum(vals);
    _yVals = vals;
    calcPosNegSum();
    calcRanges();
  }

  List<Range> get ranges => _ranges;

  /// Returns true if this BarEntry is stacked (has a values array), false if not.
  ///
  /// @return
  bool isStacked() {
    return _yVals != null;
  }

  double getSumBelow(int stackIndex) {
    if (_yVals == null) return 0;

    var remainder = 0.0;
    var index = _yVals!.length - 1;
    while (index > stackIndex && index >= 0) {
      remainder += _yVals![index];
      index--;
    }

    return remainder;
  }

  double get negativeSum => _negativeSum;

  double get positiveSum => _positiveSum;

  void calcPosNegSum() {
    if (_yVals == null) {
      _negativeSum = 0;
      _positiveSum = 0;
      return;
    }

    var sumNeg = 0.0;
    var sumPos = 0.0;

    for (var f in _yVals!) {
      if (f <= 0.0) {
        sumNeg += f.abs();
      } else {
        sumPos += f;
      }
    }

    _negativeSum = sumNeg;
    _positiveSum = sumPos;
  }

  /// Calculates the sum across all values of the given stack.
  ///
  /// @param vals
  /// @return
  static double calcSum(List<double>? vals) {
    if (vals == null) return 0.0;
    var sum = 0.0;
    for (var f in vals) {
      sum += f;
    }
    return sum;
  }

  void calcRanges() {
    var values = yVals;

    if (values == null || values.isEmpty) return;

    _ranges = [];

    var negRemain = -negativeSum;
    var posRemain = 0.0;

    for (var i = 0; i < _ranges.length; i++) {
      var value = values[i];

      if (value < 0) {
        _ranges.add(Range(negRemain, negRemain - value));
        negRemain -= value;
      } else {
        _ranges.add(Range(posRemain, posRemain + value));
        posRemain += value;
      }
    }
  }
}
