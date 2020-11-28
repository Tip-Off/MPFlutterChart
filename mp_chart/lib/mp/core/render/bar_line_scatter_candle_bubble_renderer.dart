import 'package:mp_chart/mp/core/bounds.dart';
import 'package:mp_chart/mp/core/animator.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_bar_line_scatter_candle_bubble_data_set.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_data_set.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';
import 'package:mp_chart/mp/core/render/data_renderer.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:flutter/painting.dart';

abstract class BarLineScatterCandleBubbleRenderer extends DataRenderer {
  /// buffer for storing the current minimum and maximum visible x
  XBounds _xBounds;
  Path _highlightLinePath = Path();

  BarLineScatterCandleBubbleRenderer(Animator animator, ViewPortHandler viewPortHandler)
      : super(animator, viewPortHandler) {
    _xBounds = XBounds(this.animator);
  }

  // ignore: unnecessary_getters_setters
  XBounds get xBounds => _xBounds;

  // ignore: unnecessary_getters_setters
  set xBounds(XBounds value) {
    _xBounds = value;
  }

  /// Returns true if the DataSet values should be drawn, false if not.
  ///
  /// @param set
  /// @return
  bool shouldDrawValues(IDataSet set) {
    return set.isVisible() && (set.isDrawValuesEnabled() || set.isDrawIconsEnabled());
  }

  /// Checks if the provided entry object is in bounds for drawing considering the current animation phase.
  ///
  /// @param e
  /// @param set
  /// @return
  bool isInBoundsX(Entry e, IBarLineScatterCandleBubbleDataSet set) {
    if (e == null) return false;

    double entryIndex = set.getEntryIndex2(e).toDouble();

    if (e == null || entryIndex >= set.getEntryCount() * animator.getPhaseX()) {
      return false;
    } else {
      return true;
    }
  }

  /// Draws vertical & horizontal highlight-lines if enabled.
  ///
  /// @param c
  /// @param x x-position of the highlight line intersection
  /// @param y y-position of the highlight line intersection
  /// @param set the currently drawn dataset
  void drawBarHighlightLines(Canvas c, double x, double y, IBarLineScatterCandleBubbleDataSet dataSet) {
    // set color and stroke-width
    highlightPaint
      ..color = dataSet.getHighLightColor()
      ..strokeWidth = 1.0;

    // draw vertical highlight lines
    if (dataSet.isHighlightEnabled()) {
      // create vertical path
      _highlightLinePath.reset();
      _highlightLinePath.moveTo(x, viewPortHandler.contentTop());
      _highlightLinePath.lineTo(x, viewPortHandler.contentBottom());

      c.drawPath(_highlightLinePath, highlightPaint);

      // create horizontal path
      _highlightLinePath.reset();
      _highlightLinePath.moveTo(viewPortHandler.contentLeft(), y);
      _highlightLinePath.lineTo(viewPortHandler.contentRight(), y);

      c.drawPath(_highlightLinePath, highlightPaint);
    }
  }
}
