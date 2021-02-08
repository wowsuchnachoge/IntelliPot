import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'IntelliPot.dart';
import 'IntelliPotDetailView.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntelliPot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DevicesListView(title: 'IntelliPot'),
    );
  }
}

class DevicesListView extends StatefulWidget {
  DevicesListView({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DevicesListViewState createState() => _DevicesListViewState();
}

class _DevicesListViewState extends State<DevicesListView> {
  Future<List<IntelliPot>> _devices;

  @override
  void initState() {
    super.initState();
    _devices = _fetchDevices();
  }

  Future<List<IntelliPot>> _fetchDevices() async {
    final response = await http
        .get('http://ec2-34-235-118-6.compute-1.amazonaws.com/api/devices/');
    if (response.statusCode == 200) {
      return _decodeDevices(response.body);
    } else {
      throw Exception('Failed to fetch IntelliPot');
    }
  }

  List<IntelliPot> _decodeDevices(String responseBody) {
    final parsed = jsonDecode(responseBody);
    List<IntelliPot> potList = [];
    if (parsed['payload'] != null) {
      for (var jsonPot in parsed['payload']) {
        potList.add(IntelliPot.fromJson(jsonPot));
      }
    }
    return potList;
  }

  Future<void> _refreshDevices(BuildContext context) async {
    setState(() {
      _devices = _fetchDevices();
    });
  }

  void _navigateAndReload(BuildContext context, IntelliPot pot) async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntelliPotDetailView(pot: pot),
      ),
    );
    if (result) {
      _refreshDevices(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: () => _refreshDevices(context),
          child: FutureBuilder<List<IntelliPot>>(
            future: _devices,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              List<IntelliPot> potList = snapshot.data;
              if (potList != null && potList.length == 0) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("No devices found"),
                    FlatButton(
                      onPressed: () {
                        _refreshDevices(context);
                      },
                      child: Text("Refresh"),
                      color: Colors.green,
                    ),
                  ],
                );
              }
              return snapshot.hasData
                  ? ListView.separated(
                      itemCount: potList.length,
                      itemBuilder: (context, index) {
                        IntelliPot pot = potList[index];
                        return ListTile(
                          title: Text(pot.name),
                          subtitle: Text((pot.plantSpecies != null
                              ? pot.plantSpecies
                              : 'Desconocido')),
                          onTap: () {
                            _navigateAndReload(context, pot);
                          },
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider();
                      },
                    )
                  : CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
