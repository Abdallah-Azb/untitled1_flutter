// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'package:at_commons/at_commons.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

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

  int subscribeSeq = 0;

  var currentFlags = 0;

  var requestedFlags = 0;

  String host = "142.132.214.220";
  int port = 6999;
  String responseDataRequest = "Initial";

  String? sessionId;
  String? keyEncepted;

  Uint8List? dataAfterDecrypt;

  void _incrementCounter() async {
    //  datagramSocket = DatagramSocket.;
    requestLiveInfo();
  }

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
    bb.addByte(4); // flag vedio
    bb.addByte(52); // videoType
    bb.addByte(47); // audioType

    subscribeSeq++;
    sendPacket(bb.getData());
    requestedFlags = subscribe.buffer.lengthInBytes;
  }

  ///
  sendPacket(List<int> buffer) async {
    print("sendPacket");
    print(buffer);
    var d = await datagramSocket!.send(buffer, InternetAddress(host), port);
    print("sendPacket sendPacket $d");
  }

  requestLiveInfo() async {
    responseDataRequest = "Waiting ......";
    setState(() {});
    String token = "Bearer c4ec86150aeb1840a2ddb79be611c8690594b9d48ba0a0b473e1e2bf1432a9c3";

    String liveInfoApi = "https://api.doorbird.io/live/info";

    try {
      Dio dio = Dio();
      dio.options.headers = {"accept": "application/json", "Authorization": token, "cloud-mjpg": "active"};
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
    } catch (e) {
      print(e);
      // responseDataRequest = e.toString();
    }
    setState(() {});
  }

  runCamera() async {
    print("RUN CAMERA FUN");

    /// Initial Datagram Socket
    datagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    //
    Uint8List uint8list = Uint8List(16 * 1024);
    //
    datagramPacket = Datagram(uint8list, InternetAddress(host, type: InternetAddressType.any), 6999);
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
    print("processPacket ==>   ${datagram.data}");
    // encropt(datagram.data.toString(), keyEncepted!);

    // try{
    int dataLength = datagram.data.length;
    Uint8List nonce = datagram.data.sublist(1, 9);
    Uint8List cipherText = datagram.data.sublist(nonce.length + 1);
    Uint8List key = toUnit8List(keyEncepted!.codeUnits);

    print(" datagram.data ==>>   ${datagram.data}");
    print(" datagram.data.length ==>>   $dataLength");
    print(" cipherText ==>>   $cipherText");
    print(" nonce ==>>   $nonce");
    print(" key ==>>   $key");
    dataAfterDecrypt = HelperIncreptionUsingSodiom.decrypt(cipherText: cipherText, nonce: nonce, key: key);

    if (dataAfterDecrypt != null) {
      log("dataAfterIncrypt ==>>>     $dataAfterDecrypt");
      dataLength = dataAfterDecrypt!.length;
      log("dataLengthNew ==>>    $dataLength");
      int seq = ((dataAfterDecrypt![1] & 0xff) << 16) | ((dataAfterDecrypt![2] & 0xff) << 8) | ((dataAfterDecrypt![3] & 0xff));
      print("seq ===>>>    $seq");

      enqueue(seq);

      // if (seq != 0) {
      //   setState(() {});
      // }
      // enqueue(seq, dataAfterIncrypt!) ;
      // imageProvider =MemoryImage(dataAfterIncrypt!);
      // imageProvider.
    }
  }

  // private BitSet vPresent = new BitSet();
  // private byte[] vData = new byte[64 * 1024];
  int vSeq = 0;
  Uint8List vData = Uint8List(64 * 1024);

  Set vPresent = {};

  void enqueue(int seq) async {
    if (seq > vSeq) {
      vPresent.clear();
      vSeq = seq;
      vData = Uint8List(0);
    }
    if (seq == vSeq) {
      // Position to 6 like java
      int offset = dataAfterDecrypt!.offsetInBytes;
      int imageLen = dataAfterDecrypt!.buffer.asByteData().getInt32(offset + 6);
      int remaining = dataAfterDecrypt!.buffer.asByteData().lengthInBytes ~/ 2;
      if (vData.isEmpty || imageLen != vData.length) {
        vPresent.clear();
        vData = Uint8List(imageLen);
      }
      int imageOffset = dataAfterDecrypt!.buffer.asByteData().getInt32(offset + 6);
      int blockSize = Math.min(remaining, 256);

      // while (remaining > 0) {
      //   Uint8List.view(dataAfterIncrypt!.buffer,blockSize);
      //   vPresent.add(imageOffset / 256);
      //   imageOffset += blockSize;
      //   print(">>>>>>>>>>>>>>>   $imageOffset");
      //   // bb.get(vData, imageOffset, blockSize);
      //   // imageOffset += blockSize;
      // }

    }
  }

  ///
  // ImageProvider ? imageProvider ;
  // AssetBundle ?assetBundle ;
  Uint8List toUnit8List(List<int> data) {
    return Uint8List.fromList(data);
  }

  List<int> toBytes(List<int> bytes, int from, int amount) {
    return bytes.sublist(from, amount);
  }

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
            dataAfterDecrypt == null ? SizedBox() : Expanded(child: Image.memory(Uint8List.fromList(dataAfterDecrypt!.buffer.asUint8List())))
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          //
        ],
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

class HelperIncreptionUsingSodiom {
  static Uint8List decrypt({required Uint8List cipherText, required Uint8List nonce, required Uint8List key}) =>
      Sodium.cryptoAeadChacha20poly1305Decrypt(null, cipherText, null, nonce, key);

// static Uint8List decrypt(
//         {required Uint8List cipherText, required Uint8List nonce, required Uint8List key}) =>
//     ChaCha20Poly1305.decrypt(cipherText, nonce, key);
}
