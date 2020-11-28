import 'package:mp_chart/mp/core/enums/axis_dependency.dart';

enum HighlightStatus { START, MOVE, END }

class Highlight {
  /// the x-value of the highlighted value
  double x = double.nan;

  /// the y-value of the highlighted value
  double y = double.nan;

  ///
  double freeX = double.nan;

  ///
  double freeY = double.nan;

  ///
  double highlightX = double.nan;

  ///
  double highlightY = double.nan;

  /// the x-pixel of the highlight
  double _xPx;

  /// the y-pixel of the highlight
  double _yPx;

  /// the index of the data object - in case it refers to more than one
  int _dataIndex = -1;

  ///
  /// the index of the datase
  /// t the highlighted value is in
  int _dataSetIndex;

  /// index which value of a stacked bar entry is highlighted, default -1
  int _stackIndex = -1;

  /// the axis the highlighted value belongs to
  AxisDependency _axis;

  /// the x-position (pixels) on which this highlight object was last drawn
  double _drawX;

  /// the y-position (pixels) on which this highlight object was last drawn
  double _drawY;

  Highlight({
    this.freeX,
    this.freeY,
    this.highlightX,
    this.highlightY,
    double x = double.nan,
    double y = double.nan,
    double xPx = 0,
    double yPx = 0,
    int dataSetIndex = 0,
    int stackIndex = -1,
    int dataIndex = -1,
    // ignore: avoid_init_to_null
    AxisDependency axis = null,
  }) {
    this.x = x;
    this.y = y;
    this._xPx = xPx;
    this._yPx = yPx;
    this._dataIndex = dataIndex;
    this._dataSetIndex = dataSetIndex;
    this._axis = axis;
    this._stackIndex = stackIndex;
  }

  Highlight copyWith({
    double freeX,
    double freeY,
    double highlightX,
    double highlightY,
    double x,
    double y,
    double xPx,
    double yPx,
    int dataSetIndex,
    int stackIndex,
    int dataIndex,
    AxisDependency axis,
  }) =>
      Highlight(
        freeX: freeX ?? this.freeX,
        freeY: freeY ?? this.freeY,
        highlightX: highlightX ?? this.highlightX,
        highlightY: highlightY ?? this.highlightY,
        x: x ?? this.x,
        y: y ?? this.y,
        xPx: xPx ?? this.xPx,
        yPx: yPx ?? this.yPx,
        dataSetIndex: dataSetIndex ?? this.dataSetIndex,
        stackIndex: stackIndex ?? this.stackIndex,
        dataIndex: dataIndex ?? this.dataIndex,
        axis: axis ?? this.axis,
      );

  double get xPx => _xPx;

  double get yPx => _yPx;

  // ignore: unnecessary_getters_setters
  int get dataIndex => _dataIndex;

  // ignore: unnecessary_getters_setters
  set dataIndex(int value) {
    _dataIndex = value;
  }

  int get dataSetIndex => _dataSetIndex;

  int get stackIndex => _stackIndex;

  bool isStacked() {
    return _stackIndex >= 0;
  }

  AxisDependency get axis => _axis;

  /// Sets the x- and y-position (pixels) where this highlight was last drawn.
  ///
  /// @param x
  /// @param y
  void setDraw(double x, double y) {
    this._drawX = x;
    this._drawY = y;
  }

  double get drawX => _drawX;

  double get drawY => _drawY;

  /// Returns true if this highlight object is equal to the other (compares
  /// xIndex and dataSetIndex)
  ///
  /// @param h
  /// @return
  bool equalTo(Highlight h) {
    if (h == null)
      return false;
    else {
      if (this._dataSetIndex == h._dataSetIndex &&
          this.x == h.x &&
          this.y == h.y &&
          this.freeX == h.freeX &&
          this.freeY == h.freeY &&
          this._stackIndex == h._stackIndex &&
          this._dataIndex == h._dataIndex)
        return true;
      else
        return false;
    }
  }

  @override
  String toString() {
    return "Highlight, x: $x, y: $y, dataSetIndex: $_dataSetIndex, stackIndex (only stacked barentry): $_stackIndex";
  }
}
