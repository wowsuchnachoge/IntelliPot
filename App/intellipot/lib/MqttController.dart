import 'dart:async';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttController {
  final String host;
  final String id;
  final String subscribeTopic;
  MqttServerClient client;
  MqttController({this.host, this.id, this.subscribeTopic});

  Future<int> connect(String deviceID) async {
    client = MqttServerClient(host, id);
    client.onConnected = _onConnected;
    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      print('Client exception - $e');
      client.disconnect();
      return 0;
    } on SocketException catch (e) {
      print('Socket exception - $e');
      client.disconnect();
      return 0;
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      return 1;
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      return 0;
    }
  }

  void publish(String topic, MqttClientPayloadBuilder builder) {
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload);
  }

  void _onConnected() {
    client.subscribe(subscribeTopic, MqttQos.exactlyOnce);
  }

  Future<bool> disconnect() async {
    client.disconnect();
    if (client.connectionStatus.state == MqttConnectionState.disconnected) {
      return true;
    }
    return false;
  }
}
