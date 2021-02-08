import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class LineChart extends StatelessWidget {
  final List<charts.Series> data;
  final bool animate;
  final int maxValue, step;

  LineChart(this.data, {this.animate, this.maxValue, this.step});

  factory LineChart.withSampleData() {
    return LineChart(
      _createSampleData(),
      animate: false,
      maxValue: 100,
      step: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    int i = 0;
    List<charts.TickSpec<int>> staticTicks = <charts.TickSpec<int>>[];
    for (i = 0; i <= maxValue; i += step) {
      staticTicks.add(charts.TickSpec(i));
    }
    return charts.LineChart(
      data,
      primaryMeasureAxis: charts.NumericAxisSpec(
        tickProviderSpec: charts.StaticNumericTickProviderSpec(staticTicks),
      ),
      animate: animate,
    );
  }

  static List<charts.Series<ChartData, int>> _createSampleData() {
    final data = [
      ChartData(0, 5),
      ChartData(1, 0),
      ChartData(2, 5),
      ChartData(3, 4),
      ChartData(4, 8),
      ChartData(5, 1),
      ChartData(6, 4),
      ChartData(7, 3),
      ChartData(8, 2),
    ];

    return [
      charts.Series<ChartData, int>(
        id: 'TestSeries',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (ChartData data, _) => data.id,
        measureFn: (ChartData data, _) => data.value,
        data: data,
      )
    ];
  }
}

class ChartData {
  final double value;
  final int id;

  ChartData(this.id, this.value);
}
