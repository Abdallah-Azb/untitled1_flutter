// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:raw_sound/raw_sound_player.dart';
// import 'package:sound_stream/sound_stream.dart';
import 'package:untitled1_flutter/audio_queue.dart';
import 'package:untitled1_flutter/jpeg_queue.dart';
import 'package:untitled1_flutter/socket_connect_send_receive.dart';

import 'image_load.dart';
import 'network_helper.dart';

void main() {
  Sodium.init();

  runApp(const MyApp());
}

//
String token =
    "Bearer 3cf5e05d6b71acd38e30109dd658ba698213904bb159ec8fc4f75dfcfafb7817";

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

  // final PlayerStream _player = PlayerStream();

  late StreamSubscription _playerStatus;

  AudioQueue audioQueue = AudioQueue();
  final _playerPCMI16 = RawSoundPlayer();

  Rx<Uint8List> image = Uint8List(0).obs;
  final FlutterSoundPlayer flutterSound =  FlutterSoundPlayer(voiceProcessing:true );


  @override
  void initState() {
    super.initState();
    initPlugin();
  }

  Future<void> initPlugin() async {

    // int intSize = await FlutterSound;
    // print("Buffer size: $intSize");


   await _playerPCMI16
        .initialize(
     bufferSize: 4,
      nChannels: 1,
      sampleRate: 8000,
      pcmType: RawSoundPCMType.PCMI16,
    );
   //  await flutterSound.openPlayer(enableVoiceProcessing: true);
   //  await flutterSound.setVolume(1.0);
   //  await flutterSound.startPlayerFromStream( codec: Codec.pcm16, sampleRate: 8000, numChannels: 1 );

    // _playerStatus = _player.status.listen((status) {
    // });
    //
    // await Future.wait([
    //   _player.initialize(sampleRate: 8000),
    // ]);

    // await _player.start();

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
      body: Obx(() {
        return Center(
            child: image.value.isEmpty
                ? const SizedBox()
                : Image.memory(
                    image.value!,
                    width: MediaQuery.of(context).size.width,
                    height: 500,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
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
                SocketConnectHelper socketConnectHelper = SocketConnectHelper(
                    host: responseGetInfo.host,
                    port: int.parse(responseGetInfo.port.toString()),
                    sessionId: responseGetInfo.sessionId,
                    keyEncepted: responseGetInfo.key);
                socketConnectHelper.connect(this, audioQueue);
               await audioQueue.startDecoding(this);
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

  playAudio() async {


    // int i =0;
    // Timer.periodic(const Duration(microseconds: 10), (timer) async {
    //   if (!_playerPCMI16.isPlaying) {
    //     await _playerPCMI16.play();
    //   }
    //   print("AudiLength${allAudioList[i]}");
    //   // ;
    //   if (_playerPCMI16.isPlaying) {
    //     _playerPCMI16.feed(Uint8List.fromList(allAudioList[i]));
    //     if(allAudioList.length -i ==1){
    //       i=0;
    //     }
    //     else{
    //       i++;
    //     }
    //   }
    // });
  }

  @override
  Future<void> onAudioReceived(List<int> audio) async {



    // flutterSound.feedFromStream(Uint8List.fromList(audio));
    // _player.writeChunk(Uint8List.fromList(audio));

    if (!_playerPCMI16.isPlaying) {
      await _playerPCMI16.play();
    }
    print("AudiLength${audio}");
    if (_playerPCMI16.isPlaying) {
      _playerPCMI16.feed(Uint8List.fromList(audio));
    }
    // TODO: implement onAudioReceived
  }
}
