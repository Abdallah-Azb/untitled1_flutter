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
    String token = "Bearer dd0d245d8614b2c9fffff6cea355398d2a63f4ce9734668e707827949608913f";

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
    // }catch(e){
    //   log(e.toString(),error: "Error Process",name: "Error In Process Packet ");
    // }

    if (dataAfterIncrypt != null) {
      print("dataAfterIncrypt ==>>>     $dataAfterIncrypt");
      dataLength = dataAfterIncrypt!.length ;
      print("dataLengthNew ==>>    $dataLength");
      int seq = ((dataAfterIncrypt![1] & 0xff) << 16) | ((dataAfterIncrypt![2] & 0xff) << 8) | ((dataAfterIncrypt![3] & 0xff));
      print("seq ===>>>    $seq");

    }
  }

  // List<int>    toBytes(List<int>  bytes, int from, int amount) {
  //     List.copyRange(bytes, from, mIdBytes, 2);
  //     return Arrays.copyOfRange(bytes, from, from + amount);
  // }

  ///
  _tttteeessst() async {
    // Uint8List decrypt(Uint8List cipherText, Uint8List nonce, Uint8List key,
    //     {Uint8List? additionalData}) =>

    print("keyEncepted!.codeUnits ==>     " + "b5ecb888447f16e27df6fce07e91ebd5".codeUnits.toString());
    print(AsciiEncoder().convert("b5ecb888447f16e27df6fce07e91ebd5"));

    final das = AsciiCodec().encode("b5ecb888447f16e27df6fce07e91ebd5");
    print("das das das das ===>>>     $das");
    try {
      Uint8List dd = ChaCha20Poly1305.decrypt(
          // null,
          toUnit8List([
            -38,
            -93,
            -63,
            64,
            -79,
            -93,
            73,
            48,
            -68,
            -38,
            10,
            99,
            -113,
            -113,
            56,
            -88,
            -7,
            -107,
            -66,
            -106,
            110,
            -53
          ]),
          toUnit8List([2, -107, 107, -92, -18, -77, 3, -108]),
          AsciiEncoder().convert("b5ecb888447f16e27df6fce07e91ebd5"));
      print("dd dd dd ====>>>>    $dd");
    } catch (e) {
      print("hhezn  ==###     $e");
    }
  }

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
             Expanded(child: Image.memory(Uint8List.fromList([ 0,  0, 5,5,17]),fit: BoxFit.cover,))
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
          FloatingActionButton(
            onPressed: _tttteeessst,
            tooltip: 'encript',
            child: const Icon(Icons.energy_savings_leaf),
          ),
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
      Sodium.cryptoAeadChacha20poly1305Decrypt(
          null, cipherText, null, nonce, key);


  // static Uint8List decrypt(
  //         {required Uint8List cipherText, required Uint8List nonce, required Uint8List key}) =>
  //     ChaCha20Poly1305.decrypt(cipherText, nonce, key);
}
