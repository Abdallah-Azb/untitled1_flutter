// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'package:at_commons/at_commons.dart';
import 'package:bit_array/bit_array.dart';
import 'package:byte_util/byte.dart';
import 'package:byte_util/byte_array.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:untitled1_flutter/audio_queue.dart';
import 'package:untitled1_flutter/jpeg_queue.dart';
import 'package:untitled1_flutter/socket_connect_send_receive.dart';
// import 'package:image/image.dart';

import 'decrypt_sodium_data.dart';
import 'image_load.dart';
import 'network_helper.dart';

void main() {
  Sodium.init();

  runApp(const MyApp());
}

//
String token = "Bearer 4495e7fb983d031e194120efb33840487eb8faf71c31eac69ad752ee3fc38986";

//
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

class _MyHomePageState extends State<MyHomePage> implements ImgListener, AudioListener {
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
    requestLiveInfo();
  }

  void sendSubscribe(bool unsubscribe) {
    // print("sendSubscribe");
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
    bb.addByte(5); //  flag state + flag vedio
    bb.addByte(52); // videoType
    bb.addByte(47); // audioType enabled

    subscribeSeq++;
    sendPacket(bb.getData());

    requestedFlags = 5;
  }

  ///
  sendPacket(List<int> buffer) async {
    // print("sendPacket");
    // print(buffer);
    var d = await datagramSocket!.send(buffer, InternetAddress(host), port);
    // print("sendPacket sendPacket $d");
  }

  requestLiveInfo() async {
    responseDataRequest = "Waiting ......";
    setState(() {});
    String token = "Bearer ff96947f38af858924ec30d3026667687192c04a609e4e349a12bc273913d79a";

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
        // print("keyEncepted    ==>   $keyEncepted");

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
        if (lastSubscribe + (currentFlags == requestedFlags ? 15000 : 500) <
            DateTime.now().millisecondsSinceEpoch) {
          print("====  DateTime.now().millisecondsSinceEpoch =====     " +
              DateTime.now().millisecondsSinceEpoch.toString());
          lastSubscribe = DateTime.now().millisecondsSinceEpoch;
          sendSubscribe(false);
        }
        //  sendSubscribe(false);

        datagramSocket.timeout(const Duration(milliseconds: 1000));

        Datagram? datagram = datagramSocket.receive();
        if (datagram != null) {
          processPacket(datagram);
        }
      },
    );
  }

  // Uint8List? imageeeee = Uint8List(64 * 1024);

  processPacket(Datagram datagram) {
    // Uint8List packetData =  datagram.data ;
    ByteArray packetData = ByteArray(datagram.data);
    int dataLength = datagram.data.length;

    Byte type = packetData.array.first;

    ByteArray? data;
    // print("== type00 ===     $type"  ) ;
    // print("== type value00 ===     ${type.value}"  ) ;
    if (type.value == UdpConstants.PACKET_ENCRYPTION_TYPE_1.value) {
      // 225  &-OR-& -31
      // decrypt the data before handling them
      ByteArray nonce = ByteArray(packetData.bytes.sublist(1, 9));
      ByteArray encryptedData = ByteArray(packetData.bytes.sublist(nonce.array.length + 1));
      ByteArray key = ByteArray(toUnit8List(keyEncepted!.codeUnits));

      print("== nonce ===     $nonce");
      print("== nonce array ===     ${nonce.array}");
      print("== nonce array length ===     ${nonce.array.length}");
      print("== nonce bytes===     ${nonce.bytes}");
      print("== nonce bytes length===     ${nonce.bytes.length}");
      print("== nonce bytes lengthInBytes ===     ${nonce.bytes.lengthInBytes}");
      print("== nonce bytes offsetInBytes ===     ${nonce.bytes.offsetInBytes}");
      print("== nonce bytes buffer ===     ${nonce.bytes.buffer}");
      print("========================================================");
      print("========================================================");
      print("== encryptedData ===     $encryptedData");
      print("== encryptedData array ===     ${encryptedData.array}");
      print("== encryptedData array length ===     ${encryptedData.array.length}");
      print("== encryptedData bytes===     ${encryptedData.bytes}");
      print("== encryptedData bytes length===     ${encryptedData.bytes.length}");
      print("== encryptedData bytes lengthInBytes ===     ${encryptedData.bytes.lengthInBytes}");
      print("== encryptedData bytes offsetInBytes ===     ${encryptedData.bytes.offsetInBytes}");
      print("== encryptedData bytes buffer ===     ${encryptedData.bytes.buffer}");
      print("== key ===     $key");

      try {
        data = ByteArray(toUnit8List(HelperIncreptionUsingSodiom.decrypt(
            cipherText: encryptedData.bytes, nonce: nonce.bytes, key: key.bytes)));
      } catch (e) {
        print("== Catch Error in Decrypt Data In Sodiom");
      }

      if (data != null) {
        dataLength = data.array.length;
        type = data.array.first;
        int seq = ((data.array[1].value & 0xff) << 16) |
            ((data.array[2].value & 0xff) << 8) |
            ((data.array[3].value & 0xff));
        Byte state = data.array[4];
        int flags = data.array[5].value;

        print("========================================================");
        print("========================================================");
        // print("== data ===     $data"  ) ;
        print("== data array===     ${data.array}");
        print("== data array length ===     ${data.array.length}");
        print("== data bytes===     ${data.bytes}");
        print("== data bytes buffer===     ${data.bytes.buffer}");
        print("== data bytes length===     ${data.bytes.length}");
        print("========================================================");
        print("========================================================");
        print("== type ===     $type");
        print("== type value ===     ${type.value}");
        print("========================================================");
        print("========================================================");
        print("== seq ===     $seq");
        print("========================================================");
        print("========================================================");
        print("== state ===     $state");
        print("== state value ===     ${state.value}");
        print("========================================================");
        print("========================================================");
        print("== flags ===     $flags");

        /// Image
        if (type.value == UdpConstants.PACKET_JPEG_V2.value) {
          // 52

          // JpegQueue.enqueue(seq, data,dataLength);
        }
      }
    }

    /* ///
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
      int seq = ((dataAfterDecrypt![1] & 0xff) << 16) |
          ((dataAfterDecrypt![2] & 0xff) << 8) |
          ((dataAfterDecrypt![3] & 0xff));
      print("seq ===>>>    $seq");

      enqueue(seq);

print("imageLen ==>>   $imageLen");
print("remaining ==>>   $remaining");
print("offset ==>>   $offset");

      */ /*if(seq > vSeq){
        imageeeee = null ;
        vPresent.clearAll() ;
        vSeq = seq;
      }
      if(seq == vSeq){
        int offset = dataAfterDecrypt!.offsetInBytes;
        int imageLen = dataAfterDecrypt!.buffer.asByteData().getInt32(offset + 6);
  int pos = dataAfterDecrypt!.buffer.asByteData().getInt32(offset);      int remaining = dataAfterDecrypt!.buffer.asByteData().lengthInBytes ~/ 2;



      }*/ /*

      setState(() {});
    }*/
  }

  ///

  int vSeq = 0;

  Set<Byte> vPresent = <Byte>{};

/*
  imageEnqueue (Uint8List data , int length,int seq){
    // Uint8List vData =   Uint8List(64 * 1024);
    BitArray ?vData =   BitArray(64 * 1024);
    InputBuffer inputBuffer = InputBuffer(data.buffer.asUint8List(),offset: 0,length:length );
    InputBuffer inputBufferNew ;
    // int remaining = dataAfterDecrypt!.buffer.asByteData().lengthInBytes ~/ 2;

    // = InputBuffer(data.buffer.asUint8List(),offset: 0,length:length );
    if(seq > vSeq){
      vPresent.clear();
      vSeq = seq;
      vData.clearAll();
      vData = null ;
    }
    if(seq == vSeq){

    }

  }
*/

  ///

  ///
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
            // imageeeee == null ? SizedBox() : Expanded(child: Image.memory(Uint8List.fromList(imageeeee!)))
            //    Expanded(child: Image.memory(Uint8List.fromList(fakwDataImage))),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            // onPressed: _incrementCounter,
            onPressed: () async {

              // ByteArray nonce = ByteArray(Uint8List.fromList([62,-56,-78,11,-68,58,-52,-81]));
              // ByteArray encryptedData = ByteArray(Uint8List.fromList([-4,-49,69,79,126,-21,31,-3,67,-96,15,-87,-32,43,-49,80,12,122,-12,-121,9,107,27,49,-51,-53,34,-6,16,71,122,-80,-85,48,-49,92,-45,-5,60,-65,60,-66,-32,109,6,95,32,87,-97,-70,-102,-125,40,3,-40,-110,-94,-112,92,-111,9,-100,14,-80,-68,87,-107,-68,18,100,-105,124,-24,40,110,-126,72,43,-55,117,106,101,45,-81,-2,-86,51,-19,122,55,-109,-25,-119,-88,-46,-9,-96,23,16,-34,68,96,83,67,-95,-87,-112,101,-30,72,-82,-30,-19,-113,-66,-94,-96,-21,-45,96,-125,56,-114,45,-47,-72,-62,-3,78,-80,-52,3,-33,14,-121,-22,13,70,52,18,96,-76,-4,75,58,120,-103,61,-74,-126,50,45,-79,124,30,-2,49,-2,-44,-53,-74,-110,-36,93,20,-120,79,-99,60,-31,-108,91,-64,126,2,-119,-105,-113,31,6,-91,119,62,-49,60,83,-80,-118,103,-54,113,60,16,40,15,27,64,36,17,107,-73,-26,65,104,-86,-3,-32,-32,7,-127,-113,-87,-25,5,104,58,108,-58,76,-27,-9,96,72,-11,119,63,12,-106,38,123,43,30,40,62,-30,-114,-86,-76,-97,-104,-79,28,15,17,-39,41,26,-10,38,103,26,87,56,41,-55,-32,-44,25,-5,-126,-14,-122,-8,82,-80,112,2,-92,-111,-19,-124,-24,-33,-128,-71,-75,42,74,-57,16,105,-83,-67,96,10,47,94,111,99,-85,-113,-25,32,-65,111,-128,65,29,-50,72,-54,-102,-111,95,-20,-126,63,-45,114,27,46,-79,-3,-51,-103,15,107,14,-37,71,-75,-122,123,-95,13,-11,44,114,-70,91,-118,105,20,-83,89,-41,-111,89,87,-59,-32,52,96,-16,100,-114,119,127,93,25,24,51,22,-6,-28,-80,-7,-86,-77,-17,101,-91,-121,46,-108,56,-100,48,117,124,-19,-67,100,-101,50,87,41,-22,-35,63,-5,-59,27,-84,12,55,-114,72,-12,103,96,91,-32,-42,68,21,-34,55,-103,-36,-93,124,37,36,58,60,-79,68,121,48,63,9,-52,30,102,-29,-22,-59,88,-39,8,60,16,75,-99,99,66,89,46,-16,69,17,106,-16,-111,-71,127,38,75,-1,-66,0,-58,-61,-73,-11,114,-119,107,-71,-13,7,-5,11,29,110,118,125,11,-80,-90,-114,120,40,-42,17,-25,-111,24,77,-45,102,21,44,-61,61,92,116,-43,124,121,31,25,-47,-121,20,-117,-27,-125,80,49,-90,-88,-59,-75,-81,-68,23,40,72,-32,-128,-60,125,104,-42,-11,-50,17,-29,78,-55,93,4,-11,42,48,72,-16,76,-60,18,90,81,97,88,71,108,-2,76,39,-17,125,-60,22,-18,114,-95,22,122,87,110]));
              // ByteArray key = ByteArray(toUnit8List("2f11c5a7cfe6d8572841cf5f7ad93e63".codeUnits));
              // try {
              //   SodiumDecryptHelper sodiumDecryptHelper =
              //   SodiumDecryptHelper(cipherText: encryptedData.bytes, nonce: nonce.bytes, key: key.bytes);
              //   var data = ByteArray(toUnit8List(sodiumDecryptHelper.decrypt()));
              //   log(Int8List.fromList(sodiumDecryptHelper.decrypt()).toString());
              //   print("DATA     ${Int8List.fromList(sodiumDecryptHelper.decrypt())}") ;
              //
              // } catch (e) {
              //   print("== Catch Error in Decrypt Data In Sodiom");
              // }

              NetworkHelper networkHelper = NetworkHelper();
              ResponseGetInfo? responseGetInfo = await networkHelper.getInfo();
              if (responseGetInfo != null) {
                SocketConnectHelper socketConnectHelper = SocketConnectHelper(
                    host: responseGetInfo.host,
                    port: int.parse(responseGetInfo.port.toString()),
                    sessionId: responseGetInfo.sessionId,
                    keyEncepted: responseGetInfo.key);

                socketConnectHelper.connect();
              }
            },
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          //
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void onImageReceived(Uint8List image) {
    // TODO: implement onImageReceived
  }

  @override
  void onAudioReceived(List<int> audio) {
    // TODO: implement onAudioReceived
  }
}
//

///

//
class UdpConstants {
  static ByteData PACKET_SUBSCRIBE = ByteData(0x01);
  static Byte PACKET_STATE_CHANGE = Byte(0x11); //17
  static Byte PACKET_ULAW = Byte(0x21); // 33
  static Byte PACKET_NO_AUDIO = Byte(0x2F);
  static Byte PACKET_JPEG_V2 = Byte(0x34); // 52
  static Byte PACKET_NO_VIDEO = Byte(0x3F);
  static Byte PACKET_ENCRYPTION_TYPE_1 = Byte(0xE1); //225
  static ByteData FLAG_STATE = ByteData(1);
  static Byte FLAG_AUDIO = Byte(2);
  static Byte FLAG_VIDEO = Byte(4);
  static Byte STATE_VIDEO_SESSION_INVALID = Byte(5);
  static Byte STATE_AUDIO_SESSION_INVALID = Byte(6);
}
//

///

//
class HelperIncreptionUsingSodiom {
  static Uint8List decrypt(
          {required Uint8List cipherText, required Uint8List nonce, required Uint8List key}) =>
      Sodium.cryptoAeadChacha20poly1305Decrypt(null, cipherText, null, nonce, key);
}

/*
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
    int seq = ((dataAfterDecrypt![1] & 0xff) << 16) |
    ((dataAfterDecrypt![2] & 0xff) << 8) |
    ((dataAfterDecrypt![3] & 0xff));
    print("seq ===>>>    $seq");
    int offset = dataAfterDecrypt!.offsetInBytes;
    int imageLen = dataAfterDecrypt!.buffer.asByteData().getInt32(offset + 6);
    int remaining = dataAfterDecrypt!.buffer.asByteData().lengthInBytes ~/ 2;

    print("imageLen ==>>   $imageLen");
    print("remaining ==>>   $remaining");
    print("offset ==>>   $offset");

    */
/*if(seq > vSeq){
        imageeeee = null ;
        vPresent.clearAll() ;
        vSeq = seq;
      }
      if(seq == vSeq){
        int offset = dataAfterDecrypt!.offsetInBytes;
        int imageLen = dataAfterDecrypt!.buffer.asByteData().getInt32(offset + 6);
        int remaining = dataAfterDecrypt!.buffer.asByteData().lengthInBytes ~/ 2;



      }*/ /*


    setState(() {});
  }
}

///

// void enqueue(int seq) async {
  //   if (seq > vSeq) {
  //     vPresent.clear();
  //     vSeq = seq;
  //     vData = Uint8List(0);
  //   }
  //   if (seq == vSeq) {
  //     // Position to 6 like java
  //     int offset = dataAfterDecrypt!.offsetInBytes;
  //     int imageLen = dataAfterDecrypt!.buffer.asByteData().getInt32(offset + 6);
  //     int remaining = dataAfterDecrypt!.buffer.asByteData().lengthInBytes ~/ 2;
  //     if (vData.isEmpty || imageLen != vData.length) {
  //       vPresent.clear();
  //       vData = Uint8List(imageLen);
  //     }
  //     int imageOffset = dataAfterDecrypt!.buffer.asByteData().getInt32(offset + 6);
  //
  //
  //     while (remaining > 0) {
  //       int blockSize = Math.min(remaining, 256);
  //
  //       Uint8List.view(dataAfterDecrypt!.buffer,blockSize);
  //       vPresent.add(ByteData(imageOffset ~/ 256));
  //       imageOffset += blockSize;
  //       print(">>>>>>>>>>>>>>>   $imageOffset");
  //       // bb.get(vData, imageOffset, blockSize);
  //       // imageOffset += blockSize;
  //     }
  //
  //
  //
  //
  //   }
  // }

*/

List<int> fakwDataImage = [
  -1,
  -40,
  -1,
  -32,
  0,
  16,
  74,
  70,
  73,
  70,
  0,
  1,
  2,
  1,
  0,
  96,
  0,
  96,
  0,
  0,
  -1,
  -37,
  0,
  -124,
  0,
  13,
  9,
  10,
  11,
  10,
  8,
  13,
  11,
  10,
  11,
  14,
  14,
  13,
  15,
  19,
  32,
  21,
  19,
  18,
  18,
  19,
  39,
  28,
  30,
  23,
  32,
  46,
  41,
  49,
  48,
  46,
  41,
  45,
  44,
  51,
  58,
  74,
  62,
  51,
  54,
  70,
  55,
  44,
  45,
  64,
  87,
  65,
  70,
  76,
  78,
  82,
  83,
  82,
  50,
  62,
  90,
  97,
  90,
  80,
  96,
  74,
  81,
  82,
  79,
  1,
  14,
  14,
  14,
  19,
  17,
  19,
  38,
  21,
  21,
  38,
  79,
  53,
  45,
  53,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  79,
  -1,
  -60,
  1,
  -94,
  0,
  0,
  1,
  5,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  1,
  0,
  3,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  16,
  0,
  2,
  1,
  3,
  3,
  2,
  4,
  3,
  5,
  5,
  4,
  4,
  0,
  0,
  1,
  125,
  1,
  2,
  3,
  0,
  4,
  17,
  5,
  18,
  33,
  49,
  65,
  6,
  19,
  81,
  97,
  7,
  34,
  113,
  20,
  50,
  -127,
  -111,
  -95,
  8,
  35,
  66,
  -79,
  -63,
  21,
  82,
  -47,
  -16,
  36,
  51,
  98,
  114,
  -126,
  9,
  10,
  22,
  23,
  24,
  25,
  26,
  37,
  38,
  39,
  40,
  41,
  42,
  52,
  53,
  54,
  55,
  56,
  57,
  58,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
  99,
  100,
  101,
  102,
  103,
  104,
  105,
  106,
  115,
  116,
  117,
  118,
  119,
  120,
  121,
  122,
  -125,
  -124,
  -123,
  -122,
  -121,
  -120,
  -119,
  -118,
  -110,
  -109,
  -108,
  -107,
  -106,
  -105,
  -104,
  -103,
  -102,
  -94,
  -93,
  -92,
  -91,
  -90,
  -89,
  -88,
  -87,
  -86,
  -78,
  -77,
  -76,
  -75,
  -74,
  -73,
  -72,
  -71,
  -70,
  -62,
  -61,
  -60,
  -59,
  -58,
  -57,
  -56,
  -55,
  -54,
  -46,
  -45,
  -44,
  -43,
  -42,
  -41,
  -40,
  -39,
  -38,
  -31,
  -30,
  -29,
  -28,
  -27,
  -26,
  -25,
  -24,
  -23,
  -22,
  -15,
  -14,
  -13,
  -12,
  -11,
  -10,
  -9,
  -8,
  -7,
  -6,
  17,
  0,
  2,
  1,
  2,
  4,
  4,
  3,
  4,
  7,
  5,
  4,
  4,
  0,
  1,
  2,
  119,
  0,
  1,
  2,
  3,
  17,
  4,
  5,
  33,
  49,
  6,
  18,
  65,
  81,
  7,
  97,
  113,
  19,
  34,
  50,
  -127,
  8,
  20,
  66,
  -111,
  -95,
  -79,
  -63,
  9,
  35,
  51,
  82,
  -16,
  21,
  98,
  114,
  -47,
  10,
  22,
  36,
  52,
  -31,
  37,
  -15,
  23,
  24,
  25,
  26,
  38,
  39,
  40,
  41,
  42,
  53,
  54,
  55,
  56,
  57,
  58,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
  99,
  100,
  101,
  102,
  103,
  104,
  105,
  106,
  115,
  116,
  117,
  118,
  119,
  120,
  121,
  122,
  -126,
  -125,
  -124,
  -123,
  -122,
  -121,
  -120,
  -119,
  -118,
  -110
];
