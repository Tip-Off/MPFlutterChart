import 'dart:ui';

import 'package:mp_chart/mp/core/data_interfaces/i_data_set.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';

mixin IBarLineScatterCandleBubbleDataSet<T extends Entry> implements IDataSet<T> {
  Color getHighLightColor();

  double getHighlightLineWidth();

  bool isHighlightLineDashed();
}
