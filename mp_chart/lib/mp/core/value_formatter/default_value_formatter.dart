// ignore: import_of_legacy_library_into_null_safe
import 'package:intl/intl.dart';
import 'package:mp_chart/mp/core/value_formatter/value_formatter.dart';

class DefaultValueFormatter extends ValueFormatter {
  /// DecimalFormat for formatting
  NumberFormat? _format;

  late int _decimalDigits;

  /// Constructor that specifies to how many digits the value should be
  /// formatted.
  ///
  /// @param digits
  DefaultValueFormatter(int digits) {
    setup(digits);
  }

  /// Sets up the formatter with a given number of decimal digits.
  ///
  /// @param digits
  void setup(int digits) {
    _decimalDigits = digits;

    if (digits < 1) {
      digits = 1;
    }

    var b = StringBuffer();
    b.write('.');
    for (var i = 0; i < digits; i++) {
      b.write('0');
    }
    _format = NumberFormat('###,###,###,##0' + b.toString());
  }

  @override
  String getFormattedValue1(double value) {
    // put more logic here ...
    // avoid memory allocations here (for performance reasons)

    return _format!.format(value);
  }

  @override
  String toString() {
    return _format!.toString();
  }

  int get decimalDigits => _decimalDigits;
}
