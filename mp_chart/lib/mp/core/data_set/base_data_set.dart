import 'package:flutter/painting.dart';
import 'package:mp_chart/mp/core/adapter_android_mp.dart';
import 'package:mp_chart/mp/core/color/gradient_color.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_data_set.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';
import 'dart:ui' as ui;

import 'package:mp_chart/mp/core/enums/axis_dependency.dart';
import 'package:mp_chart/mp/core/enums/legend_form.dart';
import 'package:mp_chart/mp/core/poolable/point.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/value_formatter/value_formatter.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';

abstract class BaseDataSet<T extends Entry> implements IDataSet<T> {
  /// List representing all colors that are used for this DataSet
  late List<ui.Color> _colors;

  GradientColor? _gradientColor;

  List<GradientColor>? _gradientColors;

  /// List representing all colors that are used for drawing the actual values for this DataSet
  late List<ui.Color> _valueColors;

  /// label that describes the DataSet or the data the DataSet represents
  String _label = 'DataSet';

  String _identifier = '';

  /// this specifies which axis this DataSet should be plotted against
  AxisDependency _axisDependency = AxisDependency.LEFT;

  /// if true, value highlightning is enabled
  bool _highlightEnabled = true;

  /// custom formatter that is used instead of the auto-formatter if set
  ValueFormatter? _valueFormatter;

  /// the typeface used for the value text
  TypeFace? _valueTypeface;

  LegendForm _form = LegendForm.DEFAULT;
  double _formSize = double.nan;
  double _formLineWidth = double.nan;
  bool _isFormLineDashed = false;

  /// if true, y-values are drawn on the chart
  bool _drawValues = true;

  /// if true, y-alerts are drawn on the chart
  bool _drawAlerts = false;

  /// the size of the value-text labels
  double _valueTextSize = 17;

  /// flag that indicates if the DataSet is visible or not
  bool _visible = true;

  /// Default constructor.
  BaseDataSet() {
    _colors = [];
    _valueColors = [];
    // default color
    _colors.add(ui.Color.fromARGB(255, 140, 234, 255));
    _valueColors.add(ColorUtils.BLACK);
  }

  /// Constructor with label.
  ///
  /// @param label
  BaseDataSet.withLabel(String label, String identifier) {
    _colors = [];
    _valueColors = [];

    // default color
    _colors.add(ui.Color.fromARGB(255, 140, 234, 255));
    _valueColors.add(ColorUtils.BLACK);
    _label = label;
    _identifier = identifier;
  }

  /// Use this method to tell the data set that the underlying data has changed.
  void notifyDataSetChanged() {
    calcMinMax();
  }

  /// ###### ###### COLOR GETTING RELATED METHODS ##### ######

  @override
  List<ui.Color> getColors() {
    return _colors;
  }

  List<ui.Color> getValueColors() {
    return _valueColors;
  }

  @override
  ui.Color getColor1() {
    return _colors[0];
  }

  @override
  ui.Color getColor2(int index) {
    return _colors[index % _colors.length];
  }

  @override
  GradientColor? getGradientColor1() {
    return _gradientColor;
  }

  @override
  List<GradientColor>? getGradientColors() {
    return _gradientColors;
  }

  @override
  GradientColor getGradientColor2(int index) {
    return _gradientColors![index % _gradientColors!.length];
  }

  /// ###### ###### COLOR SETTING RELATED METHODS ##### ######

  /// Sets the colors that should be used fore this DataSet. Colors are reused
  /// as soon as the number of Entries the DataSet represents is higher than
  /// the size of the colors array. If you are using colors from the resources,
  /// make sure that the colors are already prepared (by calling
  /// getResources().getColor(...)) before adding them to the DataSet.
  ///
  /// @param colors
  void setColors1(List<ui.Color> colors) {
    _colors = colors;
  }

  /// Adds a  color to the colors array of the DataSet.
  ///
  /// @param color
  void addColor(ui.Color color) {
    _colors.add(color);
  }

  /// Sets the one and ONLY color that should be used for this DataSet.
  /// Internally, this recreates the colors array and adds the specified color.
  ///
  /// @param color
  void setColor1(ui.Color color) {
    resetColors();
    _colors.add(color);
  }

  void setColor3(ui.Color color, int alpha) {
    resetColors();
    alpha = alpha > 255 ? 255 : (alpha < 0 ? 0 : alpha);
    _colors.add(Color.fromARGB(alpha, color.red, color.green, color.blue));
  }

  /// Sets the start and end color for gradient color, ONLY color that should be used for this DataSet.
  ///
  /// @param startColor
  /// @param endColor
  void setGradientColor(ui.Color startColor, ui.Color endColor) {
    _gradientColor = GradientColor(startColor, endColor);
  }

  /// Sets the start and end color for gradient colors, ONLY color that should be used for this DataSet.
  ///
  /// @param gradientColors
  void setGradientColors(List<GradientColor> gradientColors) {
    _gradientColors = gradientColors;
  }

  /// Sets a color with a specific alpha value.
  ///
  /// @param color
  /// @param alpha from 0-255
  void setColor2(ui.Color color, int alpha) {
    setColor1(ui.Color.fromARGB(alpha, color.red, color.green, color.blue));
  }

  /// Sets colors with a specific alpha value.
  ///
  /// @param colors
  /// @param alpha
  void setColors2(List<ui.Color> colors, int alpha) {
    resetColors();
    for (var color in colors) {
      addColor(ui.Color.fromARGB(alpha, color.red, color.green, color.blue));
    }
  }

  /// Resets all colors of this DataSet and recreates the colors array.
  void resetColors() {
    _colors.clear();
  }

  /// ###### ###### OTHER STYLING RELATED METHODS ##### ######

  @override
  void setLabel(String label) {
    _label = label;
  }

  @override
  String getLabel() {
    return _label;
  }

  @override
  String getIdentifier() {
    return _identifier;
  }

  @override
  void setHighlightEnabled(bool enabled) {
    _highlightEnabled = enabled;
  }

  @override
  bool isHighlightEnabled() {
    return _highlightEnabled;
  }

  @override
  void setValueFormatter(ValueFormatter? f) {
    if (f == null) {
      return;
    } else {
      _valueFormatter = f;
    }
  }

  @override
  ValueFormatter? getValueFormatter() {
    if (needsFormatter()) return Utils.getDefaultValueFormatter();
    return _valueFormatter;
  }

  @override
  bool needsFormatter() {
    return _valueFormatter == null;
  }

  @override
  void setValueTextColor(ui.Color color) {
    _valueColors.clear();
    _valueColors.add(color);
  }

  @override
  void setValueTextColors(List<ui.Color> colors) {
    _valueColors = colors;
  }

  @override
  void setValueTypeface(TypeFace tf) {
    _valueTypeface = tf;
  }

  @override
  void setValueTextSize(double size) {
    _valueTextSize = Utils.convertDpToPixel(size);
  }

  @override
  ui.Color getValueTextColor1() {
    return _valueColors[0];
  }

  @override
  ui.Color getValueTextColor2(int index) {
    return _valueColors[index % _valueColors.length];
  }

  @override
  TypeFace? getValueTypeface() {
    return _valueTypeface;
  }

  @override
  double getValueTextSize() {
    return _valueTextSize;
  }

  void setForm(LegendForm form) {
    _form = form;
  }

  @override
  LegendForm getForm() {
    return _form;
  }

  void setFormSize(double formSize) {
    _formSize = formSize;
  }

  @override
  double getFormSize() {
    return _formSize;
  }

  void setFormLineWidth(double formLineWidth) {
    _formLineWidth = formLineWidth;
  }

  @override
  double getFormLineWidth() {
    return _formLineWidth;
  }

  void setFormLineDashed(bool value) {
    _isFormLineDashed = value;
  }

  @override
  bool isFormLineDashed() {
    return _isFormLineDashed;
  }

  @override
  void setDrawValues(bool enabled) {
    _drawValues = enabled;
  }

  @override
  bool isDrawValuesEnabled() {
    return _drawValues;
  }

  @override
  void setDrawAlerts(bool enabled) {
    _drawAlerts = enabled;
  }

  @override
  bool isDrawAlertsEnabled() {
    return _drawAlerts;
  }

  @override
  void setVisible(bool visible) {
    _visible = visible;
  }

  @override
  bool isVisible() {
    return _visible;
  }

  @override
  AxisDependency getAxisDependency() {
    return _axisDependency;
  }

  @override
  void setAxisDependency(AxisDependency dependency) {
    _axisDependency = dependency;
  }

  /// ###### ###### DATA RELATED METHODS ###### ######

  @override
  int getIndexInEntries(int xIndex) {
    for (var i = 0; i < getEntryCount(); i++) {
      if (xIndex == getEntryForIndex(i)!.x) return i;
    }

    return -1;
  }

  @override
  bool removeFirst() {
    if (getEntryCount() > 0) {
      var entry = getEntryForIndex(0);
      return removeEntry1(entry);
    } else {
      return false;
    }
  }

  @override
  bool removeLast() {
    if (getEntryCount() > 0) {
      var e = getEntryForIndex(getEntryCount() - 1);
      return removeEntry1(e);
    } else {
      return false;
    }
  }

  @override
  bool removeEntryByXValue(double xValue) {
    var e = getEntryForXValue2(xValue, double.nan);
    return removeEntry1(e);
  }

  @override
  bool removeEntry2(int index) {
    var e = getEntryForIndex(index);
    return removeEntry1(e);
  }

  @override
  bool contains(T e) {
    for (var i = 0; i < getEntryCount(); i++) {
      if (getEntryForIndex(i) == e) return true;
    }

    return false;
  }

  void copy(BaseDataSet baseDataSet) {
    baseDataSet._axisDependency = _axisDependency;
    baseDataSet._colors = _colors;
    baseDataSet._drawAlerts = _drawAlerts;
    baseDataSet._drawValues = _drawValues;
    baseDataSet._form = _form;
    baseDataSet._isFormLineDashed = _isFormLineDashed;
    baseDataSet._formLineWidth = _formLineWidth;
    baseDataSet._formSize = _formSize;
    baseDataSet._gradientColor = _gradientColor;
    baseDataSet._gradientColors = _gradientColors;
    baseDataSet._highlightEnabled = _highlightEnabled;
    baseDataSet._valueColors = _valueColors;
    baseDataSet._valueFormatter = _valueFormatter;
    baseDataSet._valueColors = _valueColors;
    baseDataSet._valueTextSize = _valueTextSize;
    baseDataSet._visible = _visible;
  }
}
