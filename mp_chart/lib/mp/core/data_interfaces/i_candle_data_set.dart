import 'dart:ui';

import 'package:mp_chart/mp/core/data_interfaces/i_line_scatter_candle_radar_data_set.dart';
import 'package:mp_chart/mp/core/entry/candle_entry.dart';

mixin ICandleDataSet implements ILineScatterCandleRadarDataSet<CandleEntry> {
  /// Returns the space that is left out on the left and right side of each
  /// candle.
  ///
  /// @return
  double getBarSpace();

  /// Returns the width of the candle-shadow-line in pixels.
  ///
  /// @return
  double getShadowWidth();

  /// Returns shadow color for all entries
  ///
  /// @return
  Color getShadowColor();

  /// Returns the increasing color (for open < close).
  ///
  /// @return
  Color getIncreasingColor();

  /// Returns the decreasing color (for open > close).
  ///
  /// @return
  Color getDecreasingColor();

  /// Returns paint style when open < close
  ///
  /// @return
  PaintingStyle getIncreasingPaintStyle();

  /// Returns paint style when open > close
  ///
  /// @return
  PaintingStyle getDecreasingPaintStyle();

  /// Is the shadow color same as the candle color?
  ///
  /// @return
  bool getShadowColorSameAsCandle();

  bool getHighlightCandleEnabled();

  void setHighlightCandleEnabled(bool status);

  Color getHighlightCandleColor();

  void setHighlightCandleColor(Color color);
}
