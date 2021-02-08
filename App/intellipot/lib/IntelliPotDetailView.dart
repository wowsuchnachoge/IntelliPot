import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:intellipot/StackedAreaLineChart.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'ChartView.dart';
import 'GaugeChart.dart';
import 'IntelliPot.dart';
import 'IntelliPotSettingsView.dart';
import 'MqttController.dart';

class IntelliPotDetailView extends StatefulWidget {
  IntelliPotDetailView({Key key, this.pot}) : super(key: key);

  final IntelliPot pot;

  @override
  _IntelliPotDetailViewState createState() => _IntelliPotDetailViewState();
}

class _IntelliPotDetailViewState extends State<IntelliPotDetailView> {
  MqttController _mqttController;
  StreamSubscription _subscription;
  List<charts.Series<ChartData, int>> temperatureData,
      airHumidityData,
      soilMoistureData;

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final String message =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    final jsonMessage = json.decode(message);
    setState(() {
      widget.pot.temperature = jsonMessage['temperature'];
      widget.pot.airHumidity = jsonMessage['airHumidity'];
      widget.pot.soilMoisture = jsonMessage['soilMoisture'];
      widget.pot.recievingLight = jsonMessage['recievingLight'];
    });
  }

  void _navigateAndUpdate(BuildContext context, IntelliPot pot) async {
    var resultPot = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntelliPotSettingsView(
          pot: pot,
        ),
      ),
    );
    if (resultPot != null) {
      setState(() {
        widget.pot.name = resultPot.name;
      });
    }
  }

  List<charts.Series<ChartData, int>> _createData(
      List<double> data, String id) {
    final List<ChartData> chartData = [];
    for (int i = 0; i < data.length; i++) {
      chartData.add(ChartData(i, data[i]));
    }
    return [
      charts.Series<ChartData, int>(
        id: id,
        colorFn: (_, __) {
          if (id == 'temperature') {
            return charts.MaterialPalette.red.shadeDefault;
          }
          if (id == 'airHumidity') {
            return charts.MaterialPalette.blue.shadeDefault;
          }
          return charts.MaterialPalette.green.shadeDefault;
        },
        domainFn: (ChartData data, _) => data.id,
        measureFn: (ChartData data, _) => data.value,
        data: chartData,
      )
    ];
  }

  Future<void> _getPlantData() async {
    List<double> t = [], ah = [], sm = [];
    final response = await http.get(
        'http://ec2-34-235-118-6.compute-1.amazonaws.com/api/devices/' +
            widget.pot.deviceID);
    if (response.statusCode == 200) {
      var parsedResponse = jsonDecode(response.body);
      for (var line in parsedResponse['payload']) {
        t.add(line['temperature'].toDouble());
        ah.add(line['airHumidity'].toDouble());
        sm.add(line['soilMoisture'].toDouble());
      }
      setState(() {
        this.temperatureData = _createData(t, 'temperature');
        this.airHumidityData = _createData(ah, 'airHumidity');
        this.soilMoistureData = _createData(sm, 'soilMoisture');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getPlantData();
    final _random = Random();
    _mqttController = MqttController(
        host: 'ec2-34-235-118-6.compute-1.amazonaws.com',
        id: _random.nextInt(1000000).toString(),
        subscribeTopic: widget.pot.deviceID + '/data');
    _mqttController.connect(widget.pot.deviceID);
    _subscription = _mqttController.client.updates.listen(_onMessage);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _subscription.cancel();
        return _mqttController.disconnect();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.pot.name),
          leading: FlatButton(
            onPressed: () {
              _subscription.cancel();
              _mqttController.disconnect();
              Navigator.pop(context, true);
            },
            child: Icon(
              Icons.chevron_left,
              color: Colors.white,
              size: 25,
            ),
          ),
          actions: [
            FlatButton(
              onPressed: () {
                _navigateAndUpdate(context, widget.pot);
              },
              child: Icon(
                Icons.edit,
                color: Colors.white,
                size: 25,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildPlantImage(),
            DraggableScrollableSheet(
              initialChildSize: 0.175,
              minChildSize: 0.175,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 7,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Top Line
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Row(
                            children: [
                              Spacer(),
                              Container(
                                height: 5,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                        ),
                        // Title Row
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    child: Container(
                                      height: 35,
                                      child: Text(
                                        (widget.pot.plantSpecies != null
                                            ? widget.pot.plantSpecies
                                            : 'Desconocido'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      (widget.pot.mode == 'manual'
                                          ? 'Programado para regar cada ' +
                                              widget.pot.waterPeriod
                                                  .toString() +
                                              ' días'
                                          : 'Riego automático en ' +
                                              widget.pot.humidityThreshold
                                                  .toString() +
                                              '%'),
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w100),
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Visibility(
                                      visible: widget.pot.mode == 'manual',
                                      child: FlatButton(
                                        padding:
                                            EdgeInsets.fromLTRB(10, 0, 0, 0),
                                        onPressed: () {
                                          // Mandar mensaje por MQTT
                                          final builder =
                                              MqttClientPayloadBuilder();
                                          builder.addString('water');
                                          _mqttController.publish(
                                              widget.pot.deviceID + '/water',
                                              builder);
                                        },
                                        child: Container(
                                          height: 35,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(15.0),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Regar',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 2.5,
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        (widget.pot.lastWater != null
                                            ? 'Último riego el ' +
                                                widget.pot.lastWater
                                            : ''),
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w100),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Grid view
                        IgnorePointer(
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Temperatura',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Stack(
                                            children: [
                                              GaugeChart.withValue(
                                                  widget.pot.temperature, 40),
                                              Center(
                                                child: Text(
                                                  widget.pot.temperature
                                                          .toString() +
                                                      'ºC',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 22,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Humedad del aire',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Stack(
                                            children: [
                                              GaugeChart.withValue(
                                                  widget.pot.airHumidity, 100),
                                              Center(
                                                child: Text(
                                                  widget.pot.airHumidity
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 22,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Humedad del suelo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Stack(
                                            children: [
                                              GaugeChart.withValue(
                                                  ((widget.pot.soilMoisture ==
                                                                  null
                                                              ? 0
                                                              : widget.pot
                                                                  .soilMoisture) *
                                                          100)
                                                      .toInt(),
                                                  100),
                                              Center(
                                                child: Text(
                                                  ((widget.pot.soilMoisture ==
                                                                      null
                                                                  ? 0
                                                                  : widget.pot
                                                                      .soilMoisture) *
                                                              100)
                                                          .toInt()
                                                          .toString() +
                                                      '%',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 22,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Luz solar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: (widget.pot.recievingLight
                                              ? Icon(Icons.wb_sunny_sharp,
                                                  size: 75,
                                                  color: Colors.yellow)
                                              : Icon(Icons.wb_sunny_sharp,
                                                  size: 75,
                                                  color: Colors.grey)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ChartView('Temperatura (ºC)',
                            maxValue: 40, step: 10, data: temperatureData),
                        ChartView('Humedad del aire (%)',
                            maxValue: 100, step: 25, data: airHumidityData),
                        ChartView('Humedad del suelo (%)',
                            maxValue: 100, step: 25, data: soilMoistureData),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantImage() {
    return Image.network(
      'https://www.ikea.com/us/en/images/products/fejka-artificial-potted-plant-with-pot-indoor-outdoor-succulent__0614211_PE686835_S5.JPG?f=m',
      fit: BoxFit.cover,
      height: double.infinity,
    );
  }
}
