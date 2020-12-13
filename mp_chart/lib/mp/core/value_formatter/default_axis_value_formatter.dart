// ignore: import_of_legacy_library_into_null_safe
import 'package:intl/intl.dart';
import 'package:mp_chart/mp/core/value_formatter/value_formatter.dart';

class DefaultAxisValueFormatter extends ValueFormatter {
  /// decimalformat for formatting
  NumberFormat? _format;

  /// the number of decimal digits this formatter uses
  late int _digits;

  /// Constructor that specifies to how many digits the value should be
  /// formatted.
  ///
  /// @param digits
  DefaultAxisValueFormatter(int digits) {
    _digits = digits;

    var b = StringBuffer();
    for (var i = 0; i < digits; i++) {
      if (i == 0) b.write('.');
      b.write('0');
    }

    _format = NumberFormat('###,###,###,##0' + b.toString());
  }

  @override
  String getFormattedValue1(double value) {
    // avoid memory allocations here (for performance)
    return _format!.format(value);
  }

  int get digits => _digits;
}
