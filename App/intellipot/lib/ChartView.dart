import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

import 'StackedAreaLineChart.dart';

class ChartView extends StatelessWidget {
  final String title;
  final int maxValue;
  final int step;
  final List<charts.Series> data;

  ChartView(this.title, {this.maxValue, this.step, this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Text(
              this.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(width: 1),
              borderRadius: BorderRadius.circular(15.0),
            ),
            height: 200,
            child: LineChart(this.data,
                animate: false, maxValue: this.maxValue, step: this.step),
          ),
        ],
      ),
    );
  }
}
