import 'package:mp_chart/mp/core/entry/entry.dart';

import 'package:mp_chart/mp/core/enums/alert_type.dart';

class CandleEntry extends Entry {
  /// shadow-high value
  late double _shadowHigh;

  /// shadow-low value
  late double _shadowLow;

  /// close value
  late double _close;

  /// open value
  late double _open;

  late double _volume;

  bool highlighted;

  CandleEntry({
    double volume = 0,
    this.highlighted = false,
    required double x,
    required double shadowH,
    required double shadowL,
    required double open,
    required double close,
    AlertType? alertType,
    Object? data,
  }) : super(x: x, y: (shadowH + shadowL) / 2, alertType: alertType, data: data) {
    _shadowHigh = shadowH;
    _shadowLow = shadowL;
    _open = open;
    _close = close;
    _volume = volume;
  }

  @override
  String toString() {
    return '''{
      x: $x,
      y: $y,
      open: $open,
      close: $close,
      high: $shadowHigh,
      low: $shadowLow,
      volume: $volume,
    }''';
  }

  /// Returns the overall range (difference) between shadow-high and
  /// shadow-low.
  ///
  /// @return
  double getShadowRange() {
    return (_shadowHigh - _shadowLow).abs();
  }

  /// Returns the body size (difference between open and close).
  ///
  /// @return
  double getBodyRange() {
    return (_open - _close).abs();
  }

  @override
  CandleEntry copy() {
    var c = CandleEntry(
      x: x,
      shadowH: _shadowHigh,
      shadowL: _shadowLow,
      open: _open,
      close: _close,
      highlighted: highlighted,
      volume: _volume,
      data: mData,
      alertType: mAlertType,
    );
    return c;
  }

  double get open => _open;

  set open(double value) {
    _open = value;
  }

  double get close => _close;

  set close(double value) {
    _close = value;
  }

  double get shadowLow => _shadowLow;

  set shadowLow(double value) {
    _shadowLow = value;
  }

  double get shadowHigh => _shadowHigh;

  set shadowHigh(double value) {
    _shadowHigh = value;
  }

  double get volume => _volume;

  set volume(double value) {
    _volume = value;
  }
}
