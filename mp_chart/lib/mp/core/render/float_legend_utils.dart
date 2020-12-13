import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:mp_chart/mp/core/data/bar_line_scatter_candle_bubble_data.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_data_set.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/view_port.dart';

class FloatLegendUtils {
  static const _background = Color.fromARGB(150, 50, 50, 50);

  static Size drawFloatingLegend<T extends IDataSet>(
    TextPainter labelText,
    Canvas c,
    ViewPortHandler viewPortHandler,
    BarLineScatterCandleBubbleData data,
    List<Highlight> indices,
    Size rendererSize,
  ) {
    var drawSize = rendererSize;

    final entryColors = _createEntries<T>(data, indices);

    entryColors.keys.forEach((element) {
      final position = Offset(viewPortHandler.contentLeft(), viewPortHandler.contentTop() + drawSize.height);
      final legendSize = _drawTextLegend(labelText, c, entryColors[element]!, element, position);

      drawSize = Size(drawSize.width + legendSize.width, drawSize.height + legendSize.height);
    });

    return drawSize;
  }

  //T LineDataSet
  static Map<String, List<EntryColor>> _createEntries<T extends IDataSet>(BarLineScatterCandleBubbleData data, List<Highlight> indices) {
    final entryColors = <String, List<EntryColor>>{};

    data.dataSets!.where((element) => element is T && element.getEntriesForXValue(indices.first.x).isNotEmpty).toList().asMap().forEach((i, element) {
      if (element.isVisible()) {
        final h = indices.first;
        final entry = element.getEntryForXValue2(h.x, 0);
        final legendText = element.getLabel();
        final legend = legendText.split('@');
        final text = legend[0];
        var inputs = '';
        if (legend.length > 1) {
          inputs = legend[1];
        }
        final color = element.getColor1();

        if (entryColors.containsKey(text)) {
          entryColors[text]!.add(EntryColor(entry!, color, inputs));
        } else {
          entryColors.putIfAbsent(text, () => [EntryColor(entry!, color, inputs)]);
        }
      }
    });

    return entryColors;
  }

  static Size _drawTextLegend(TextPainter labelText, Canvas c, List<EntryColor> entryColor, String text, Offset labelPosition) {
    final span = _createTextSpan(entryColor, text.split('#').first);

    labelText.text = TextSpan(
      text: '',
      style: TextStyle(
        fontSize: 10,
        color: Colors.white,
      ),
      children: span,
    );
    labelText.layout();
    _drawFloatingLegendBg(c, labelPosition, labelText.size);
    labelText.paint(c, labelPosition);

    return labelText.size;
  }

  static List<InlineSpan> _createTextSpan(List<EntryColor> entryColor, String text) {
    final _whiteStyle = TextStyle(
      fontSize: 10,
      color: Colors.white,
    );

    final span = <InlineSpan>[TextSpan(text: '$text', style: _whiteStyle)];
    span.add(TextSpan(text: ' (', style: _whiteStyle));

    entryColor.forEach((element) {
      span.add(
        TextSpan(
          text: element.input.isEmpty ? '' : ' ${element.input}',
          style: _whiteStyle,
        ),
      );
    });

    span.add(TextSpan(text: ' ) ', style: _whiteStyle));

    entryColor.forEach((element) {
      span.add(
        TextSpan(
          text: ' ${element.entry.y.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 10,
            color: element.color,
          ),
        ),
      );
    });

    return span;
  }

  static void _drawFloatingLegendBg(Canvas c, Offset position, Size size) {
    c.drawRect(Rect.fromLTWH(position.dx, position.dy, size.width, size.height), Paint()..color = _background);
  }
}

class EntryColor {
  final Entry entry;
  final Color color;
  final String input;

  EntryColor(this.entry, this.color, this.input);
}
