import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class GaugeChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  GaugeChart(this.seriesList, {this.animate});

  factory GaugeChart.withValue(int value, int maxValue) {
    return new GaugeChart(
      _createData(value, maxValue),
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new charts.PieChart(seriesList,
        animate: animate,
        defaultRenderer: new charts.ArcRendererConfig(
            arcWidth: 10, startAngle: 4 / 5 * pi, arcLength: 7 / 5 * pi));
  }

  static List<charts.Series<GaugeSegment, String>> _createData(
      int value, int maxValue) {
    final double colorVal = value / maxValue;
    charts.Color color = charts.ColorUtil.fromDartColor(Colors.red);
    if (colorVal <= 0.25) {
      color = charts.ColorUtil.fromDartColor(Colors.blue);
    }
    if (colorVal > 0.25 && colorVal <= 0.5) {
      color = charts.ColorUtil.fromDartColor(Colors.green);
    }
    if (colorVal > 0.5 && colorVal <= 0.75) {
      color = charts.ColorUtil.fromDartColor(Colors.orange);
    }
    final data = [
      new GaugeSegment('Color', value, color),
      new GaugeSegment('Grey', maxValue - value,
          charts.ColorUtil.fromDartColor(Colors.grey)),
    ];

    return [
      new charts.Series<GaugeSegment, String>(
        id: 'Segments',
        colorFn: (GaugeSegment segment, __) => segment.color,
        domainFn: (GaugeSegment segment, _) => segment.segment,
        measureFn: (GaugeSegment segment, _) => segment.size,
        data: data,
      )
    ];
  }
}

/// Sample data type.
class GaugeSegment {
  final String segment;
  final int size;
  final charts.Color color;

  GaugeSegment(this.segment, this.size, this.color);
}
