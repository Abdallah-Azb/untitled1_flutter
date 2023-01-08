// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:async';
import 'dart:collection';
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
import 'package:get/get.dart';
import 'package:raw_sound/raw_sound_player.dart';
import 'package:untitled1_flutter/audio_queue.dart';
import 'package:untitled1_flutter/jpeg_queue.dart';
import 'package:untitled1_flutter/socket_connect_send_receive.dart';
// import 'package:image/image.dart';

import 'image_load.dart';
import 'network_helper.dart';

void main() {
  Sodium.init();

  runApp(const MyApp());
}

//
String token =
    "Bearer c80b07efad87ced9561178c13fcda0ba4112bf5b0b793f434c50ff61e457f0ae";

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

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin
    implements ImgListener, AudioListener {
  int _counter = 0;

  AudioQueue audioQueue = AudioQueue();
  final _playerPCMI16 = RawSoundPlayer();


  Rx<Uint8List> image = Uint8List(0).obs ;
  // Uint8List? image;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..repeat(reverse: true);
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

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
      body: Obx(() {
        return Center(
            child: image.value.isEmpty
                ? const SizedBox()
                : Image.memory(
                    image.value!,
                    width: MediaQuery.of(context).size.width,
                    height: 500,
                    fit: BoxFit.contain,
              gaplessPlayback:true ,
                  ));
      }),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            // onPressed: _incrementCounter,
            onPressed: () async {
              NetworkHelper networkHelper = NetworkHelper();
              ResponseGetInfo? responseGetInfo = await networkHelper.getInfo();
              if (responseGetInfo != null) {

                _playerPCMI16
                    .initialize(
                  bufferSize: 724,
                  nChannels: 1,
                  sampleRate: 8000,
                  pcmType: RawSoundPCMType.PCMI16,
                )
                    .then((value) {
                  setState(() {
                    // Trigger rebuild to update UI
                  });
                });


                // audioQueue.startDecoding(this);


                SocketConnectHelper socketConnectHelper = SocketConnectHelper(
                    host: responseGetInfo.host,
                    port: int.parse(responseGetInfo.port.toString()),
                    sessionId: responseGetInfo.sessionId,
                    keyEncepted: responseGetInfo.key);



                socketConnectHelper.connect(this , audioQueue);

               // await playAudio();

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
    // print("returned Image is${Int8List.fromList(image)}");
    // print("returned Image is${image}");

    //
    // Flutter.app.post(() {
    //   // This callback will be run in the UI thread
    //   print("Running in the UI thread");
    // });
    // Future.wait((){});
      print("ImageReieved");
      this.image.value = image;

    // TODO: implement onImageReceived
  }


  playAudio() async{

    Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if(!_playerPCMI16.isPlaying){
        await _playerPCMI16.play();
      }
      // print("AudiLength${audio.length}");
      if(_playerPCMI16.isPlaying){
        _playerPCMI16.feed(Uint8List.fromList([-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124]));
      }
    });



  }
  @override
  Future<void> onAudioReceived(List<int> audio) async {

    if(!_playerPCMI16.isPlaying){
   await _playerPCMI16.play();
    }
    print("AudiLength${audio.length}");
    if(_playerPCMI16.isPlaying){
      _playerPCMI16.feed(Uint8List.fromList([-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124,-32124]));
    }
    // TODO: implement onAudioReceived
  }
}

