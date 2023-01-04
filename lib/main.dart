import 'package:flutter/material.dart';
import 'package:untitled1_flutter/socket_connect_send_receive.dart';

import 'network_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomeApp(),
    );
  }
}

class MyHomeApp extends StatelessWidget {
  const MyHomeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: FloatingActionButton(
        onPressed: liveVideo,
        child: const Icon(Icons.power_settings_new),
      )),
    );
  }

  void liveVideo() async {
    print("object");
    NetworkHelper networkHelper = NetworkHelper();
    ResponseGetInfo? responseGetInfo = await networkHelper.getInfo();
    if (responseGetInfo != null) {
      SocketConnectHelper socketConnectHelper = SocketConnectHelper(
          host: responseGetInfo.host,
          port: int.parse(responseGetInfo.port),
          sessionId: responseGetInfo.sessionId,
          keyEncepted: responseGetInfo.key);

      socketConnectHelper.connect();

    }
  }
}
