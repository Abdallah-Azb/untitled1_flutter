// import 'dart:typed_data';

// import 'dart:typed_data' ;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:at_commons/at_commons.dart';
import 'package:byte_util/byte_array.dart';
import 'package:byte_util/byte_util.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'encrpit_ata.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // final String host = "apiorun.doorbird.net";

  late RawDatagramSocket datagramSocket;

  Datagram? datagramPacket;

  ByteBuffer? byteBuffer;
  var currentFlags = 0;

  var requestedFlags = 0;

  void _incrementCounter() async {
    //  datagramSocket = DatagramSocket.;
    requestLiveInfo();

    // datagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    // setState(() {
    //   _counter++;
    // });
    // print("000");
    // Uint8List uint8list = Uint8List(16 * 1024);
    // print("111");
    //
    // datagramPacket = Datagram(
    //     uint8list, InternetAddress(host, type: InternetAddressType.any), 6999);
    //
    // print("222");
    //
    // print(await datagramPacket!.address.reverse());
    // var lastSubscribe = 0;
    //
    // Timer.periodic(const Duration(seconds: 2), (timer) {
    //   ByteData subscribe = ByteData(0);
    //   String subscribeString = subscribe.toString();
    //   var videoType = UdpConstants.PACKET_NO_VIDEO;
    //   var audioType = UdpConstants.PACKET_NO_AUDIO;
    //   subscribe = UdpConstants.FLAG_STATE;
    //   ByteBuffer bb = ByteBuffer(capacity: 128);
    //   // BytesBuilder bb = BytesBuilder.allocate(128);
    //
    //   // bb.addByte(UdpConstants.PACKET_SUBSCRIBE.buffer.asInt32List()[0]);
    //   bb.addByte(UdpConstants.PACKET_SUBSCRIBE.buffer.lengthInBytes);
    //   bb.addByte((subscribeSeq >> 16));
    //   bb.addByte((subscribeSeq >> 8));
    //   bb.addByte(subscribeSeq);
    //   List<int> session = sessionId!.codeUnits;
    //
    //   bb.addByte(session.length);
    //   bb.append(session);
    //   bb.addByte(5);
    //   bb.addByte(25);
    //   bb.addByte(47);
    //
    //   subscribeSeq++;
    //
    //   // datagramSocket.receive();
    //
    //   final d = datagramSocket.send(bb.getData(), InternetAddress(host), port);
    //   print("SEND SEND $d");
    //
    //   requestedFlags = subscribe.buffer.lengthInBytes;
    //
    //   // if (lastSubscribe + (currentFlags == requestedFlags ? 15000 : 500) <
    //   //     DateTime.now().millisecond) {
    //   //   print("Inside IFF");
    //   //   lastSubscribe = DateTime.now().millisecond;
    //   //   sendSubscribe(false);
    //   // }
    //   datagramSocket.timeout(const Duration(milliseconds: 1000));
    //   Datagram? datagram = datagramSocket.receive();
    //   print(datagram);
    //   if (datagram != null) {
    //     print("DATA IS NOT NULL ");
    //     print(datagram.data.toString());
    //     String v = String.fromCharCodes(datagram.data);
    //     print(v);
    //
    //     String dd = encropt(v, keyEncepted!);
    //     print(dd);
    //   }
    // });
  }

/*
  void _incrementCounter() async {
    String session = "2TTB9vduqaYbPJ754170";
   List<int> sessionListIntCodeUnits =  session.codeUnits;


    Uint8List uint8list =Uint8List.fromList(sessionListIntCodeUnits);
    // final bytes = Uint8List.fromList([0x80, 01, 02, 0xff, 0xA1, 30, 10, 20, 77]);
    final str1 = ByteUtil.toReadable(uint8list,radix:Radix.dec );
    final str2 = ByteUtil.toBase64(uint8list);
    final str3 = ByteUtil.clone(uint8list);
    // final str1 = ByteUtil.toReadable(uint8list);
    print(str1);
    print(str2);
    print(str3);
    ByteArray byteArray1 =ByteArray.combine1(uint8list, -1);
    ByteArray fromByte =ByteArray.fromByte(20);
print(byteArray1.bytes.buffer.lengthInBytes);
print(fromByte.array);


  }*/

  int subscribeSeq = 0;

  void sendSubscribe(bool unsubscribe) {
    print("sendSubscribe");
    ByteData subscribe = ByteData(0);
    String subscribeString = subscribe.toString();
    var videoType = UdpConstants.PACKET_NO_VIDEO;
    var audioType = UdpConstants.PACKET_NO_AUDIO;
    subscribe = UdpConstants.FLAG_STATE;
    ByteBuffer bb = ByteBuffer(capacity: 128);
    bb.addByte(UdpConstants.PACKET_SUBSCRIBE.buffer.lengthInBytes);
    bb.addByte((subscribeSeq >> 16));
    bb.addByte((subscribeSeq >> 8));
    bb.addByte(subscribeSeq);
    List<int> session = sessionId!.codeUnits;

    bb.addByte(session.length);
    bb.append(session);
    bb.addByte(5);
    bb.addByte(25);
    bb.addByte(47);

    subscribeSeq++;
    sendPacket(bb.getData());
    requestedFlags = subscribe.buffer.lengthInBytes;
  }

  ///
  sendPacket(
    List<int> buffer,
  ) async {
    print("sendPacket");
    print(buffer);
    var d = await datagramSocket!.send(buffer, InternetAddress(host), port);
    print("sendPacket sendPacket $d");
  }

  ///
  //
  ///
  String host = "142.132.214.220";
  int port = 6999;
  String responseDataRequest = "Initial";

  //
  String? sessionId;
  String? keyEncepted;

  requestLiveInfo() async {
    responseDataRequest = "Waiting ......";
    setState(() {});
    String token =
        "Bearer cdb7cda409e67390845f384c41d63f6a3a23578ecc2ef33980e356502078dc71";

    String liveInfoApi = "https://api.doorbird.io/live/info";

    try {
      Dio dio = Dio();
      dio.options.headers = {
        "accept": "application/json",
        "Authorization": token,
        "cloud-mjpg": "active"
      };
      var response = await dio.get(liveInfoApi);
      if (response.statusCode == 401) {
        responseDataRequest = "Yoy Aye Unauthorized";
      } else if (response.statusCode == 200) {
        // Run Camera Fun
        responseDataRequest = 'Success';

        Map<String, dynamic> jsonData = json.decode(response.toString());
        sessionId = jsonData["video"]["cloud"]["mjpg"]["default"]["session"];
        keyEncepted = jsonData["video"]["cloud"]["mjpg"]["default"]["key"];
        print("keyEncepted    ==>   $keyEncepted");

        runCamera();
      }
      //   datagramSocket =
      //       await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      //   setState(() {
      //     _counter++;
      //   });
      //   print("000");
      //   Uint8List uint8list = Uint8List(16 * 1024);
      //   print("111");
      //
      //   datagramPacket = Datagram(uint8list,
      //       InternetAddress(host, type: InternetAddressType.any), 6999);
      //
      //   print("222");
      //
      //   print(await datagramPacket!.address.reverse());
      //   var lastSubscribe = 0;
      //
      //   Timer.periodic(const Duration(seconds: 2), (timer) {
      //     ByteData subscribe = ByteData(0);
      //     String subscribeString = subscribe.toString();
      //     var videoType = UdpConstants.PACKET_NO_VIDEO;
      //     var audioType = UdpConstants.PACKET_NO_AUDIO;
      //     subscribe = UdpConstants.FLAG_STATE;
      //     ByteBuffer bb = ByteBuffer(capacity: 128);
      //     // BytesBuilder bb = BytesBuilder.allocate(128);
      //
      //     // bb.addByte(UdpConstants.PACKET_SUBSCRIBE.buffer.asInt32List()[0]);
      //     bb.addByte(UdpConstants.PACKET_SUBSCRIBE.buffer.lengthInBytes);
      //     bb.addByte((subscribeSeq >> 16));
      //     bb.addByte((subscribeSeq >> 8));
      //     bb.addByte(subscribeSeq);
      //     List<int> session = sessionId!.codeUnits;
      //
      //     bb.addByte(session.length);
      //     bb.append(session);
      //     bb.addByte(5);
      //     bb.addByte(25);
      //     bb.addByte(47);
      //
      //     subscribeSeq++;
      //
      //     // datagramSocket.receive();
      //
      //     final d =
      //         datagramSocket.send(bb.getData(), InternetAddress(host), port);
      //     // print("SEND SEND $d");
      //
      //     requestedFlags = subscribe.buffer.lengthInBytes;
      //
      //     // if (lastSubscribe + (currentFlags == requestedFlags ? 15000 : 500) <
      //     //     DateTime.now().millisecond) {
      //     //   print("Inside IFF");
      //     //   lastSubscribe = DateTime.now().millisecond;
      //     //   sendSubscribe(false);
      //     // }
      //     datagramSocket.timeout(const Duration(milliseconds: 1000));
      //     Datagram? datagram = datagramSocket.receive();
      //     print(datagram);
      //     if (datagram != null) {
      //       // print("DATA IS NOT NULL ");
      //       // print(datagram.data.toString());
      //       String v = String.fromCharCodes(datagram.data);
      //       print(v);
      //
      //       String dd = encropt(v, keyEncepted!);
      //       print(dd);
      //     }
      //   });
      // }
    } catch (e) {
      print(e);
      // responseDataRequest = e.toString();
    }
    setState(() {});
  }

  ///
  //
  ///

  runCamera() async {
    print("RUN CAMERA FUN");

    /// Initial Datagram Socket
    datagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    //
    Uint8List uint8list = Uint8List(16 * 1024);
    //
    datagramPacket = Datagram(
        uint8list, InternetAddress(host, type: InternetAddressType.any), 6999);
    //
    var lastSubscribe = 0;
    //
    Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        sendSubscribe(false);

        datagramSocket.timeout(const Duration(milliseconds: 1000));

        Datagram? datagram = datagramSocket.receive();
        if (datagram != null) {
          processPacket(datagram);
        }
      },
    );
  }

  processPacket(Datagram datagram) {
    print("processPacket ==>   "+datagram.data.toString());
     encropt(datagram.data.toString(),keyEncepted!);
  }

  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              responseDataRequest,
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class UdpConstants {
  static ByteData PACKET_SUBSCRIBE = ByteData(0x01);
  static ByteData PACKET_STATE_CHANGE = ByteData(0x11);
  static ByteData PACKET_ULAW = ByteData(0x21);
  static ByteData PACKET_NO_AUDIO = ByteData(0x2F);
  static ByteData PACKET_JPEG_V2 = ByteData(0x34);
  static ByteData PACKET_NO_VIDEO = ByteData(0x3F);
  static ByteData PACKET_ENCRYPTION_TYPE_1 = ByteData(0xE1); //225
  static ByteData FLAG_STATE = ByteData(1);
  static ByteData FLAG_AUDIO = ByteData(2);
  static ByteData FLAG_VIDEO = ByteData(4);
  static ByteData STATE_VIDEO_SESSION_INVALID = ByteData(5);
  static ByteData STATE_AUDIO_SESSION_INVALID = ByteData(6);
}
