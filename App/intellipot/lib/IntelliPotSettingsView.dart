import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'CameraView.dart';
import 'IntelliPot.dart';

class IntelliPotSettingsView extends StatefulWidget {
  IntelliPotSettingsView({Key key, this.pot}) : super(key: key);

  final IntelliPot pot;

  @override
  _IntelliPotSettingsViewState createState() => _IntelliPotSettingsViewState();
}

class _IntelliPotSettingsViewState extends State<IntelliPotSettingsView> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _plantSpeciesController = TextEditingController();
  String _lastName, _lastSpecies;

  Future<void> _sendData(String name, String species, String mode,
      int waterPeriod, int humidityThreshold) async {
    final response = await http.put(
      'http://ec2-34-235-118-6.compute-1.amazonaws.com/api/devices/update',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, String>{
          'deviceID': widget.pot.deviceID,
          'name': name,
          'species': species,
          'mode': (mode != null ? mode : 'manual'),
          'waterPeriod': (waterPeriod != null ? waterPeriod.toString() : null),
          'humidityThreshold': humidityThreshold.toString(),
        },
      ),
    );
    if (response.statusCode != 200) {
      print('Error updating name');
    }
  }

  @override
  void initState() {
    super.initState();
    _lastName = widget.pot.name;
    _lastSpecies = (widget.pot.plantSpecies != null
        ? widget.pot.plantSpecies
        : 'Desconocido');
  }

  @override
  Widget build(BuildContext context) {
    _nameController.addListener(() {
      setState(() {
        widget.pot.name =
            _nameController.text.isEmpty ? _lastName : _nameController.text;
      });
    });
    _plantSpeciesController.addListener(() {
      setState(() {
        widget.pot.plantSpecies = _plantSpeciesController.text.isEmpty
            ? _lastSpecies
            : _plantSpeciesController.text;
      });
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pot.name),
        leading: FlatButton(
          onPressed: () {
            _sendData(widget.pot.name, widget.pot.plantSpecies, widget.pot.mode,
                widget.pot.waterPeriod, widget.pot.humidityThreshold);
            Navigator.pop(context, widget.pot);
          },
          child: Icon(
            Icons.chevron_left,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildNameTextField(),
          _buildPlantSpeciesTextField(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Text("Modo automático:"),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Switch(
                    value: widget.pot.mode == 'auto',
                    onChanged: (value) {
                      setState(() {
                        if (value) {
                          widget.pot.mode = 'auto';
                        } else {
                          widget.pot.mode = 'manual';
                        }
                      });
                    },
                    activeColor: Colors.green,
                    activeTrackColor: Colors.lightGreenAccent,
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: widget.pot.mode == 'manual',
            child: AbsorbPointer(
              absorbing: widget.pot.mode == 'auto',
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Text(
                        "Regar cada ${(widget.pot.waterPeriod != null ? widget.pot.waterPeriod.toString() : 1)} días"),
                    Slider(
                      value: (widget.pot.waterPeriod != null
                          ? widget.pot.waterPeriod.toDouble()
                          : 1),
                      min: 1,
                      max: 15,
                      divisions: 14,
                      label: widget.pot.waterPeriod.toString(),
                      onChanged: (value) {
                        setState(() {
                          widget.pot.waterPeriod = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: widget.pot.mode == 'auto',
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Text("Humedad mínima " +
                      widget.pot.humidityThreshold.toString() +
                      "%"),
                  Slider(
                      value: (widget.pot.humidityThreshold != null
                          ? widget.pot.humidityThreshold.toDouble()
                          : 1),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: widget.pot.humidityThreshold.toString() + "%",
                      onChanged: (value) {
                        setState(() {
                          widget.pot.humidityThreshold = value.toInt();
                        });
                      }),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: FlatButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraView(title: 'Camera'),
                  ),
                );
              },
              child: Text('Tomar foto',
                  style: TextStyle(
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameTextField() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Text("Nombre:"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: widget.pot.name,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantSpeciesTextField() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Text("Expecie:"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _plantSpeciesController,
                decoration: InputDecoration(
                  hintText: (widget.pot.plantSpecies != null
                      ? widget.pot.plantSpecies
                      : 'Desconocido'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
