import 'package:mp_chart/mp/core/entry/entry.dart';
import 'dart:ui' as ui;

class CandleEntry extends Entry {
  /// shadow-high value
  late double _shadowHigh;

  /// shadow-low value
  late double _shadowLow;

  /// close value
  late double _close;

  /// open value
  late double _open;

  final double volume;

  bool highlighted;

  CandleEntry({
    this.volume = 0,
    this.highlighted = false,
    required double x,
    required double shadowH,
    required double shadowL,
    required double open,
    required double close,
    ui.Image? icon,
    Object? data,
  }) : super(x: x, y: (shadowH + shadowL) / 2, icon: icon, data: data) {
    _shadowHigh = shadowH;
    _shadowLow = shadowL;
    _open = open;
    _close = close;
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
      volume: volume,
      data: mData,
    );
    return c;
  }

  // ignore: unnecessary_getters_setters
  double get open => _open;

  // ignore: unnecessary_getters_setters
  set open(double value) {
    _open = value;
  }

  // ignore: unnecessary_getters_setters
  double get close => _close;

  // ignore: unnecessary_getters_setters
  set close(double value) {
    _close = value;
  }

  // ignore: unnecessary_getters_setters
  double get shadowLow => _shadowLow;

  // ignore: unnecessary_getters_setters
  set shadowLow(double value) {
    _shadowLow = value;
  }

  // ignore: unnecessary_getters_setters
  double get shadowHigh => _shadowHigh;

  // ignore: unnecessary_getters_setters
  set shadowHigh(double value) {
    _shadowHigh = value;
  }
}
