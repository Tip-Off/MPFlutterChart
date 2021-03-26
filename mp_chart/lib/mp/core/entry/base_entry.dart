import 'package:mp_chart/mp/core/enums/alert_type.dart';

abstract class BaseEntry {
  /// the y value
  double _y = 0;

  /// optional spot for additional data this Entry represents
  Object? _data;

  /// optional alert type
  AlertType? _alertType;

  BaseEntry({required double y, AlertType? alertType, Object? data}) {
    _y = y;
    _alertType = alertType;
    _data = data;
  }

  // ignore: unnecessary_getters_setters
  AlertType? get mAlertType => _alertType;

  // ignore: unnecessary_getters_setters
  set mAlertType(AlertType? value) {
    _alertType = value;
  }

  // ignore: unnecessary_getters_setters
  Object? get mData => _data;

  // ignore: unnecessary_getters_setters
  set mData(Object? value) {
    _data = value;
  }

  // ignore: unnecessary_getters_setters
  double get y => _y;

  // ignore: unnecessary_getters_setters
  set y(double value) {
    _y = value;
  }
}
