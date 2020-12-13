import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:mp_chart/mp/core/component.dart';
import 'package:mp_chart/mp/core/enums/legend_direction.dart';
import 'package:mp_chart/mp/core/enums/legend_form.dart';
import 'package:mp_chart/mp/core/enums/legend_horizontal_alignment.dart';
import 'package:mp_chart/mp/core/enums/legend_orientation.dart';
import 'package:mp_chart/mp/core/enums/legend_vertical_alignment.dart';
import 'package:mp_chart/mp/core/legend/legend_entry.dart';
import 'package:mp_chart/mp/core/poolable/size.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';

class Legend extends ComponentBase {
  /// The legend entries array
  List<LegendEntry?> _entries = [];

  /// Entries that will be appended to the end of the auto calculated entries after calculating the legend.
  /// (if the legend has already been calculated, you will need to call notifyDataSetChanged() to let the changes take effect)
  List<LegendEntry?>? _extraEntries;

  /// Are the legend labels/colors a custom value or auto calculated? If false,
  /// then it's auto, if true, then custom. default false (automatic legend)
  bool _isLegendCustom = false;

  LegendHorizontalAlignment _horizontalAlignment = LegendHorizontalAlignment.LEFT;
  LegendVerticalAlignment _verticalAlignment = LegendVerticalAlignment.BOTTOM;
  LegendOrientation _orientation = LegendOrientation.HORIZONTAL;
  bool _drawInside = false;

  /// the text direction for the legend
  LegendDirection _direction = LegendDirection.LEFT_TO_RIGHT;

  /// the shape/form the legend colors are drawn in
  LegendForm _shape = LegendForm.SQUARE;

  /// the size of the legend forms/shapes
  double _formSize = 8;

  /// the size of the legend forms/shapes
  double _formLineWidth = 3;

  bool _isFormLineDashed = false;

  /// the space between the legend entries on a horizontal axis, default 6f
  double _xEntrySpace = 6;

  /// the space between the legend entries on a vertical axis, default 5f
  double _yEntrySpace = 0;

  /// the space between the legend entries on a vertical axis, default 2f
  ///  double _yEntrySpace = 2f;  the space between the form and the
  /// actual label/text
  double _formToTextSpace = 5;

  /// the space that should be left between stacked forms
  double _stackSpace = 3;

  /// the maximum relative size out of the whole chart view in percent
  double _maxSizePercent = 0.95;

  /// the total width of the legend (needed width space)
  double _neededWidth = 0;

  /// the total height of the legend (needed height space)
  double _neededHeight = 0;

  double _textHeightMax = 0;

  double _textWidthMax = 0;

  /// flag that indicates if word wrapping is enabled
  bool _wordWrapEnabled = false;

  List<FSize?> _calculatedLabelSizes = List.filled(16, null);
  List<bool?> _calculatedLabelBreakPoints = List.filled(16, null);
  List<FSize?> _calculatedLineSizes = List.filled(16, null);

  /// default constructor
  Legend() {
    textSize = Utils.convertDpToPixel(10);
    xOffset = Utils.convertDpToPixel(5);
    yOffset = Utils.convertDpToPixel(3); // 2
  }

  /// Constructor. Provide entries for the legend.
  ///
  /// @param entries
  Legend.fromList(List<LegendEntry?>? entries) {
    textSize = Utils.convertDpToPixel(10);
    xOffset = Utils.convertDpToPixel(5);
    yOffset = Utils.convertDpToPixel(3);
    if (entries == null) {
      throw Exception('entries array is NULL');
    }

    _entries = entries;
  }

  // ignore: unnecessary_getters_setters
  List<LegendEntry?> get entries => _entries;

  // ignore: unnecessary_getters_setters
  set entries(List<LegendEntry?> value) {
    _entries = value;
  }

  /// returns the maximum length in pixels across all legend labels + formsize
  /// + formtotextspace
  ///
  /// @param p the paint object used for rendering the text
  /// @return
  double getMaximumEntryWidth(TextPainter p) {
    var max = 0.0;
    var maxFormSize = 0.0;
    var formToTextSpace = Utils.convertDpToPixel(_formToTextSpace);
    for (var entry in _entries) {
      final formSize = Utils.convertDpToPixel(double.nan == entry!.formSize ? _formSize : entry.formSize);
      if (formSize > maxFormSize) maxFormSize = formSize;

      var label = entry.label;
      if (label == null) continue;

      var length = Utils.calcTextWidth(p, label).toDouble();

      if (length > max) max = length;
    }

    return max + maxFormSize + formToTextSpace;
  }

  /// returns the maximum height in pixels across all legend labels
  ///
  /// @param p the paint object used for rendering the text
  /// @return
  double getMaximumEntryHeight(TextPainter p) {
    var max = 0.0;
    for (var entry in _entries) {
      var label = entry!.label;
      if (label == null) continue;

      var length = Utils.calcTextHeight(p, label).toDouble();

      if (length > max) max = length;
    }

    return max;
  }

  List<LegendEntry?>? get extraEntries => _extraEntries;

  void setExtra1(List<LegendEntry?> entries) {
    _extraEntries = entries;
  }

  /// Entries that will be appended to the end of the auto calculated
  ///   entries after calculating the legend.
  /// (if the legend has already been calculated, you will need to call notifyDataSetChanged()
  ///   to let the changes take effect)
  void setExtra2(List<Color> colors, List<String> labels) {
    var entries = <LegendEntry>[];
    for (var i = 0; i < min(colors.length, labels.length); i++) {
      final entry = LegendEntry.empty();
      entry.formColor = colors[i];
      entry.label = labels[i];

      if (entry.formColor == ColorUtils.COLOR_SKIP) {
        entry.form = LegendForm.NONE;
      } else if (entry.formColor == ColorUtils.COLOR_NONE) entry.form = LegendForm.EMPTY;

      entries.add(entry);
    }

    _extraEntries = entries;
  }

  double get textHeightMax => _textHeightMax;

  double get textWidthMax => _textWidthMax;

  /// Sets a custom legend's entries array.
  /// * A null label will start a group.
  /// This will disable the feature that automatically calculates the legend
  ///   entries from the datasets.
  /// Call resetCustom() to re-enable automatic calculation (and then
  ///   notifyDataSetChanged() is needed to auto-calculate the legend again)
  void setCustom(List<LegendEntry> entries) {
    _entries = entries;
    _isLegendCustom = true;
  }

  /// Calling this will disable the custom legend entries (set by
  /// setCustom(...)). Instead, the entries will again be calculated
  /// automatically (after notifyDataSetChanged() is called).
  void resetCustom() {
    _isLegendCustom = false;
  }

  bool get isLegendCustom => _isLegendCustom;

  // ignore: unnecessary_getters_setters
  LegendHorizontalAlignment get horizontalAlignment => _horizontalAlignment;

  // ignore: unnecessary_getters_setters
  set horizontalAlignment(LegendHorizontalAlignment value) {
    _horizontalAlignment = value;
  }

  // ignore: unnecessary_getters_setters
  LegendVerticalAlignment get verticalAlignment => _verticalAlignment;

  // ignore: unnecessary_getters_setters
  set verticalAlignment(LegendVerticalAlignment value) {
    _verticalAlignment = value;
  }

  // ignore: unnecessary_getters_setters
  LegendOrientation get orientation => _orientation;

  // ignore: unnecessary_getters_setters
  set orientation(LegendOrientation value) {
    _orientation = value;
  }

  // ignore: unnecessary_getters_setters
  bool get drawInside => _drawInside;

  // ignore: unnecessary_getters_setters
  set drawInside(bool value) {
    _drawInside = value;
  }

  // ignore: unnecessary_getters_setters
  LegendDirection get direction => _direction;

  // ignore: unnecessary_getters_setters
  set direction(LegendDirection value) {
    _direction = value;
  }

  // ignore: unnecessary_getters_setters
  LegendForm get shape => _shape;

  // ignore: unnecessary_getters_setters
  set shape(LegendForm value) {
    _shape = value;
  }

  // ignore: unnecessary_getters_setters
  double get formSize => _formSize;

  // ignore: unnecessary_getters_setters
  set formSize(double value) {
    _formSize = value;
  }

  // ignore: unnecessary_getters_setters
  double get formLineWidth => _formLineWidth;

  // ignore: unnecessary_getters_setters
  set formLineWidth(double value) {
    _formLineWidth = value;
  }

  /// Sets the line dash path effect used for shapes that consist of lines.
  ///
  /// @param dashPathEffect
  void setFormLineDashed(bool isFormLineDashed) {
    _isFormLineDashed = isFormLineDashed;
  }

  /// @return The line dash path effect used for shapes that consist of lines.
  bool isFormLineDashed() {
    return _isFormLineDashed;
  }

  // ignore: unnecessary_getters_setters
  double get yEntrySpace => _yEntrySpace;

  // ignore: unnecessary_getters_setters
  set yEntrySpace(double value) {
    _yEntrySpace = value;
  }

  // ignore: unnecessary_getters_setters
  double get xEntrySpace => _xEntrySpace;

  // ignore: unnecessary_getters_setters
  set xEntrySpace(double value) {
    _xEntrySpace = value;
  }

  // ignore: unnecessary_getters_setters
  double get formToTextSpace => _formToTextSpace;

  // ignore: unnecessary_getters_setters
  set formToTextSpace(double value) {
    _formToTextSpace = value;
  }

  // ignore: unnecessary_getters_setters
  double get stackSpace => _stackSpace;

  // ignore: unnecessary_getters_setters
  set stackSpace(double value) {
    _stackSpace = value;
  }

  // ignore: unnecessary_getters_setters
  double get maxSizePercent => _maxSizePercent;

  // ignore: unnecessary_getters_setters
  set maxSizePercent(double value) {
    _maxSizePercent = value;
  }

  // ignore: unnecessary_getters_setters
  bool get wordWrapEnabled => _wordWrapEnabled;

  // ignore: unnecessary_getters_setters
  set wordWrapEnabled(bool value) {
    _wordWrapEnabled = value;
  }

  double get neededWidth => _neededWidth;

  double get neededHeight => _neededHeight;

  List<FSize?> get calculatedLineSizes => _calculatedLineSizes;

  List<FSize?> get calculatedLabelSizes => _calculatedLabelSizes;

  List<bool?> get calculatedLabelBreakPoints => _calculatedLabelBreakPoints;

  /// Calculates the dimensions of the Legend. This includes the maximum width
  /// and height of a single entry, as well as the total width and height of
  /// the Legend.
  ///
  /// @param labelpaint
  void calculateDimensions(TextPainter labelpainter, ViewPortHandler viewPortHandler) {
    var defaultFormSize = Utils.convertDpToPixel(_formSize);
    var stackSpace = Utils.convertDpToPixel(_stackSpace);
    var formToTextSpace = Utils.convertDpToPixel(_formToTextSpace);
    var xEntrySpace = Utils.convertDpToPixel(_xEntrySpace);
    var yEntrySpace = Utils.convertDpToPixel(_yEntrySpace);
    var wordWrapEnabled = _wordWrapEnabled;
    var entries = _entries;
    var entryCount = entries.length;

    _textWidthMax = getMaximumEntryWidth(labelpainter);
    _textHeightMax = getMaximumEntryHeight(labelpainter);

    switch (_orientation) {
      case LegendOrientation.VERTICAL:
        {
          var maxWidth = 0.0, maxHeight = 0.0, width = 0.0;
          var labelLineHeight = Utils.getLineHeight1(labelpainter);
          var wasStacked = false;

          for (var i = 0; i < entryCount; i++) {
            var e = entries[i]!;
            var drawingForm = e.form != LegendForm.NONE;
            var formSize = e.formSize.isNaN ? defaultFormSize : Utils.convertDpToPixel(e.formSize);
            var label = e.label;

            if (!wasStacked) width = 0;

            if (drawingForm) {
              if (wasStacked) width += stackSpace;
              width += formSize;
            }

            // grouped forms have null labels
            if (label != null) {
              // make a step to the left
              if (drawingForm && !wasStacked) {
                width += formToTextSpace;
              } else if (wasStacked) {
                maxWidth = max(maxWidth, width);
                maxHeight += labelLineHeight + yEntrySpace;
                width = 0;
                wasStacked = false;
              }

              width += Utils.calcTextWidth(labelpainter, label);

              if (i < entryCount - 1) maxHeight += labelLineHeight + yEntrySpace;
            } else {
              wasStacked = true;
              width += formSize;
              if (i < entryCount - 1) width += stackSpace;
            }

            maxWidth = max(maxWidth, width);
          }

          _neededWidth = maxWidth;
          _neededHeight = maxHeight;

          break;
        }
      case LegendOrientation.HORIZONTAL:
        {
          var labelLineHeight = Utils.getLineHeight1(labelpainter);
          var labelLineSpacing = Utils.getLineSpacing1(labelpainter) + yEntrySpace;
          var contentWidth = viewPortHandler.chartWidth() * _maxSizePercent;

          // Start calculating layout
          var maxLineWidth = 0.0;
          var currentLineWidth = 0.0;
          var requiredWidth = 0.0;
          var stackedStartIndex = -1;

          _calculatedLabelBreakPoints = [];
          _calculatedLabelSizes = [];
          _calculatedLineSizes = [];

          for (var i = 0; i < entryCount; i++) {
            var e = entries[i]!;
            var drawingForm = e.form != LegendForm.NONE;
            var formSize = e.formSize.isNaN ? defaultFormSize : Utils.convertDpToPixel(e.formSize);
            var label = e.label;

            _calculatedLabelBreakPoints.add(false);

            if (stackedStartIndex == -1) {
              // we are not stacking, so required width is for this label
              // only
              requiredWidth = 0;
            } else {
              // add the spacing appropriate for stacked labels/forms
              requiredWidth += stackSpace;
            }

            // grouped forms have null labels
            if (label != null) {
              _calculatedLabelSizes.add(Utils.calcTextSize1(labelpainter, label));
              requiredWidth += drawingForm ? formToTextSpace + formSize : 0;
              requiredWidth += _calculatedLabelSizes[i]!.width;
            } else {
              _calculatedLabelSizes.add(FSize.getInstance(0, 0));
              requiredWidth += drawingForm ? formSize : 0;

              if (stackedStartIndex == -1) {
                // mark this index as we might want to break here later
                stackedStartIndex = i;
              }
            }

            if (label != null || i == entryCount - 1) {
              var requiredSpacing = currentLineWidth == 0 ? 0.0 : xEntrySpace;

              if (!wordWrapEnabled // No word wrapping, it must fit.
                  // The line is empty, it must fit
                  ||
                  currentLineWidth == 0
                  // It simply fits
                  ||
                  (contentWidth - currentLineWidth >= requiredSpacing + requiredWidth)) {
                // Expand current line
                currentLineWidth += requiredSpacing + requiredWidth;
              } else {
                // It doesn't fit, we need to wrap a line

                // Add current line size to array
                _calculatedLineSizes.add(FSize.getInstance(currentLineWidth, labelLineHeight));
                maxLineWidth = max(maxLineWidth, currentLineWidth);

                // Start a new line
                _calculatedLabelBreakPoints.insert(stackedStartIndex > -1 ? stackedStartIndex : i, true);
                currentLineWidth = requiredWidth;
              }

              if (i == entryCount - 1) {
                // Add last line size to array
                _calculatedLineSizes.add(FSize.getInstance(currentLineWidth, labelLineHeight));
                maxLineWidth = max(maxLineWidth, currentLineWidth);
              }
            }

            stackedStartIndex = label != null ? -1 : stackedStartIndex;
          }

          _neededWidth = maxLineWidth;
          _neededHeight = labelLineHeight * (_calculatedLineSizes.length).toDouble() +
              labelLineSpacing * (_calculatedLineSizes.isEmpty ? 0 : (_calculatedLineSizes.length - 1));

          break;
        }
    }
    _neededHeight += yOffset;
    _neededWidth += xOffset;
  }
}
