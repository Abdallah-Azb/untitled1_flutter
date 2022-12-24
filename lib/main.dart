// import 'dart:typed_data';

// import 'dart:typed_data' ;

// ignore_for_file: non_constant_identifier_names, avoid_print
// hhhhh bbb
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:at_commons/at_commons.dart';
import 'package:byte_util/byte_array.dart';
import 'package:byte_util/byte_util.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'encrpit_ata.dart';
import 'dart:math' as Math;
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
  }

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
    bb.addByte(4); // flag vedio
    bb.addByte(52); // videoType
    bb.addByte(47); // audioType

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
    String token = "Bearer a5aa49e265d423d8c03a53440115c2f40af6394c8f507d93ceec306c9521ddbc";

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

  Uint8List? dataAfterIncrypt;

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
    dataAfterIncrypt = HelperIncreptionUsingSodiom.decrypt(cipherText: cipherText, nonce: nonce, key: key);
    setState(() {

    });
    // }catch(e){
    //   log(e.toString(),error: "Error Process",name: "Error In Process Packet ");
    // }

    if (dataAfterIncrypt != null) {
      log("dataAfterIncrypt ==>>>     $dataAfterIncrypt");
      dataLength = dataAfterIncrypt!.length;
      log("dataLengthNew ==>>    $dataLength");
      int seq = ((dataAfterIncrypt![1] & 0xff) << 16) |
          ((dataAfterIncrypt![2] & 0xff) << 8) |
          ((dataAfterIncrypt![3] & 0xff));
      print("seq ===>>>    $seq");


      // imageProvider =MemoryImage(dataAfterIncrypt!);
      // imageProvider.
    }
  }


  ByteBuffer ?buffer ;
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
            dataAfterIncrypt == null
                ? SizedBox()
                :
            Expanded(
              child: Image.memory(Uint8List.view(dataAfterIncrypt!.buffer,dataAfterIncrypt!.length, Math.min(dataAfterIncrypt!.buffer.lengthInBytes, 256)))
            )
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
  static Uint8List decrypt(
          {required Uint8List cipherText, required Uint8List nonce, required Uint8List key}) =>
      Sodium.cryptoAeadChacha20poly1305Decrypt(null, cipherText, null, nonce, key);

// static Uint8List decrypt(
//         {required Uint8List cipherText, required Uint8List nonce, required Uint8List key}) =>
//     ChaCha20Poly1305.decrypt(cipherText, nonce, key);
}

// Uint8List
Uint8List fakdata = Uint8List.fromList(
    [
  52,
  0,
  0,
  26,
  0,
  4,
  0,
  0,
  117,
  107,
  0,
  0,
  80,
  0,
  100,
  255,
  0,
  11,
  99,
  34,
  167,
  228,
  30,
  180,
  249,
  172,
  28,
  183,
  46,
  125,
  165,
  15,
  31,
  55,
  226,
  180,
  11,
  132,
  35,
  141,
  216,
  247,
  21,
  79,
  105,
  35,
  25,
  34,
  156,
  1,
  219,
  193,
  163,
  156,
  92,
  165,
  147,
  112,
  158,
  167,
  30,
  184,
  165,
  19,
  166,
  57,
  207,
  229,
  85,
  176,
  77,
  1,
  79,
  78,
  212,
  115,
  7,
  41,
  103,
  237,
  49,
  142,
  187,
  255,
  0,
  239,
  154,
  62,
  209,
  31,
  125,
  223,
  149,
  85,
  216,
  79,
  52,
  187,
  125,
  232,
  230,
  14,
  82,
  208,
  157,
  9,
  227,
  119,
  229,
  64,
  187,
  65,
  252,
  45,
  85,
  177,
  129,
  72,
  87,
  60,
  18,
  115,
  79,
  152,
  92,
  132,
  87,
  51,
  135,
  190,
  223,
  128,
  3,
  32,
  29,
  125,
  51,
  75,
  188,
  250,
  84,
  18,
  194,
  177,
  76,
  178,
  18,
  204,
  15,
  12,
  73,
  206,
  61,
  13,
  88,
  219,
  142,
  104,
  184,
  52,
  33,
  60,
  14,
  51,
  81,
  146,
  119,
  100,
  14,
  106,
  109,
  188,
  211,
  25,
  126,
  108,
  98,
  166,
  224,
  51,
  36,
  140,
  142,
  41,
  57,
  61,
  13,
  73,
  143,
  206,
  157,
  180,
  83,
  184,
  16,
  245,
  235,
  156,
  83,
  89,
  79,
  189,
  79,
  142,
  59,
  82,
  98,
  154,
  2,
  2,
  184,
  237,
  72,
  20,
  131,
  156,
  26,
  176,
  84,
  28,
  224,
  82,
  109,
  226,
  128,
  34,
  231,
  186,
  226,
  141,
  167,
  112,
  28,
  116,
  38,
  165,
  192,
  201,
  197,
  1,
  126,
  111,
  165,
  49,
  17,
  52,
  126,
  244,
  207,
  43,
  39,
  138,
  177,
  140,
  81,
  182,
  128,
  34,
  82,
  84,
  124,
  235,
  145,
  235,
  82,
  163,
  2,
  50,
  167,
  34,
  141,
  191,
  133,
  48,
  168,
  254,
  18,
  65,
  170,
  189,
  132,
  209,
  56,
  52,
  224,
  112,
  61,
  42,
  1,
  38,
  15,
  204,
  63,
  30,
  213,
  32,
  108,
  140,
  102,
  168,
  150,
  74,
  13,
  25,
  244,
  237,
  81,
  228,
  19,
  214,
  151,
  56,
  166,
  0,
  204,
  118,
  251,
  98,
  144,
  2,
  41,
  9,
  221,
  197,
  61,
  84,
  158,
  245,
  44,
  104,
  112,
  4,
  228,
  116,
  160,
  140,
  100,
  245,
  165,
  80,
  105,
  197,
  112,
  14,
  7,
  106,
  0,
  135,
  24,
  235,
  214,
  151,
  25,
  250,
  211,
  202,
  228,
  82,
  109,
  230,
  152,
  27,
  58,
  66,
  236,
  209,
  102,
  124,
  99,
  204,
  152,
  143,
  203,
  2,
  164,
  81,
  197,
  62,
  213,
  54,
  104,
  22,
  139,
  131,
  153,
  9,
  115,
  248,
  146,
  127,
  173,
  0,
  96,
  86,
  177,
  50,
  100,
  100,
  86,
  150,
  157,
  14,
  235,
  109,
  199,
  128,
  204,
  72,
  254,
  95,
  210,
  179,
  200,
  245,
  173,
  155,
  21,
  219,
  99,
  0,
  61,
  208,
  55,
  231,
  207,
  245,
  167,
  114,
  30,
  164,
  192,
  0,
  48,
  40,
  165,
  52,
  148,
  134,
  33,
  164,
  61,
  13,
  14,
  202,
  131,
  44,
  112,
  42,
  148,
  243,
  151,
  36,
  14,
  23,
  210,
  154,
  66,
  103,
  255,
  209,
  226,
  143,
  79,
  122,
  74,
  113,
  253,
  105,
  42,
  88,
  131,
  28,
  82,
  17,
  239,
  74,
  9,
  164,
  206,
  69,
  33,
  137,
  198,
  62,
  149,
  118,
  212,
  44,
  182,
  242,
  196,
  112,
  114,
  51,
  143,
  94,
  199,
  250,
  85,
  32,
  13,
  71,
  51,
  188,
  72,
  146,
  161,
  32,
  171,
  99,
  32,
  226,
  128,
  68,
  208,
  222,
  221,
  105,
  178,
  21,
  134,
  79,
  221,
  231,
  152,
  216
],
);
