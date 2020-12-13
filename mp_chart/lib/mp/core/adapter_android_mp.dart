import 'dart:ui';

class TypeFace {
  String? _fontFamily;
  late FontWeight _fontWeight;

  TypeFace({String? fontFamily, FontWeight fontWeight = FontWeight.w400}) {
    _fontFamily = fontFamily;
    _fontWeight = fontWeight;
  }

  // ignore: unnecessary_getters_setters
  FontWeight get fontWeight => _fontWeight;

  // ignore: unnecessary_getters_setters
  set fontWeight(FontWeight value) {
    _fontWeight = value;
  }

  // ignore: unnecessary_getters_setters
  String? get fontFamily => _fontFamily;

  // ignore: unnecessary_getters_setters
  set fontFamily(String? value) {
    _fontFamily = value;
  }
}
