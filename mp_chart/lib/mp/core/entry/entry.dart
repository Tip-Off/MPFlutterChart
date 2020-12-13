import 'package:mp_chart/mp/core/entry/base_entry.dart';
import 'dart:ui' as ui;

class Entry extends BaseEntry {
  double _x = 0;

  Entry({required double x, required double y, ui.Image? icon, Object? data})
      : _x = x,
        super(y: y, icon: icon, data: data);

  Entry copy() {
    var e = Entry(x: _x, y: y, data: mData);
    return e;
  }

  // ignore: unnecessary_getters_setters
  double get x => _x;

  // ignore: unnecessary_getters_setters
  set x(double value) {
    _x = value;
  }
}
