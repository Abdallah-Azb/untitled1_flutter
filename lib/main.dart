// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:async_locks/async_locks.dart';
import 'package:logger/logger.dart' show Level, Logger;

// import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:byte_util/byte_array.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';

// import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:sound_stream/sound_stream.dart';
// import 'package:sound_stream/sound_stream.dart';
import 'package:untitled1_flutter/audio_queue.dart';
import 'package:untitled1_flutter/jpeg_queue.dart';
import 'package:untitled1_flutter/socket_connect_send_receive.dart';
import 'package:untitled1_flutter/udp_constants.dart';

import 'network_helper.dart';

void main() {
  Sodium.init();

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

const methodChannel = MethodChannel('com.kafd.intercom');

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    implements ImgListener, AudioListener {
  int _counter = 0;

  // final PlayerStream _player = PlayerStream();

  var encryptionNonce = 1;
  int audioTransmitSequenceNumber = 0;
  final RecorderStream _recorder = RecorderStream();

  late StreamSubscription _audioStream;


  List<int> audioPart = [];

  AudioQueue audioQueue = AudioQueue();
  // final _playerPCMI16 = RawSoundPlayer();

  Rx<Uint8List> image = Uint8List(0).obs;

  FlutterSoundPlayer player = FlutterSoundPlayer(logLevel: Level.nothing);

  // final FlutterSoundPlayer flutterSound =  FlutterSoundPlayer(voiceProcessing:false);
  final _semaphore =Semaphore(1);




  @override
  void initState()  {
    super.initState();
    initPlugin();
  }

  Future<void> initPlugin() async {


    await Permission.microphone.request();
    final session = await AudioSession.instance;
    await session.configure( AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
      AVAudioSessionCategoryOptions.allowBluetooth|AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.voiceChat,

      avAudioSessionRouteSharingPolicy:
      AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    await session.setActive(true);
    await player.openPlayer(enableVoiceProcessing: true);
    await player.startPlayerFromStream(
        codec: Codec.pcm16, numChannels: 1, sampleRate: 8000 );
    await player.setVolume(1);

  }


  runMic() async {

   //  await _recorder.initialize(sampleRate: 8000);
   //  _audioStream = _recorder.audioStream.listen((data) {
   //    Uint8List list = Uint8List.fromList(data);
   //    print("Returnede Length is ${list.length}");
   //
   //
   //    // if (_isPlaying) {
   //    //   _player.writeChunk(data);
   //    // } else {
   //    //   _micChunks.add(data);
   //    // }
   //  });
   // await _recorder.start();
    FlutterSoundRecorder sound = FlutterSoundRecorder( logLevel: Level.nothing);
    await sound.openRecorder();
    var recordingDataController = StreamController<Food>();

    await sound.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 8000,
        bitRate: 512,
        audioSource: AudioSource.voice_communication);


    recordingDataController.stream.listen((buffer) async {
      if (buffer is FoodData) {


        Uint8List u8list = Uint8List.fromList(buffer.data!);

        // print("All length${buffer.data?.length}");

        Int16List int16List = Int16List.view(u8list.buffer);

        // print("INT16List${int16List.length}");

        try {
          await _semaphore.acquire();
          for (int i = 0; i <= int16List.length - 160; i += 160) {
            Int16List subList = Int16List.fromList(
                int16List.getRange(i, i + 160).toList());
            print("SubList is ${subList.length}");
            // await _semaphore.acquire();
            transmitAudioData(int16List.toList());
            // player.foodSink!.add(FoodData(Uint8List.view(subList.buffer)));
            // _semaphore.release();

          }
          _semaphore.release();
        } on Exception catch (e) {
          print("Data is ${e}");
        }

        // if(Platform.isIOS) {
        //   print("length is ${int16List.length}");
        //   try {
        //     for (int i = 0; i <= int16List.length - 160; i += 160) {
        //       Int16List subList = Int16List.fromList(
        //           int16List.getRange(i, i + 160).toList());
        //       print("SubList is ${subList.length}");
        //       // await _semaphore.acquire();
        //       player.foodSink!.add(FoodData(Uint8List.view(subList.buffer)));
        //       // _semaphore.release();
        //
        //     }
        //   } on Exception catch (e) {
        //     print("Data is ${e}");
        //   }
        // }
        // else if(Platform.isAndroid){
        //
        //   print("length is ${int16List.length}");
        //   player.foodSink!.add(FoodData(Uint8List.view(int16List.buffer)));
        //
        // }



      }
    });

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
                socketConnectHelper = SocketConnectHelper(
                    host: responseGetInfo.host,
                    port: int.parse(responseGetInfo.port.toString()),
                    sessionId: responseGetInfo.sessionId,
                    keyEncepted: responseGetInfo.key);
                socketConnectHelper.connect(this, audioQueue);
                await audioQueue.reset();
                await audioQueue.startDecoding(this);
                await runMic();

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
    this.image.value = image;
  }

  @override
  Future<void> onAudioReceived(List<int> audio) async {
      Int16List int16list = Int16List.fromList(audio);
      player.foodSink!.add(FoodData(Uint8List.view(int16list.buffer)));
       print("Uint8List List${Uint8List.fromList(audio)}");
  }


  transmitAudioData(List<int> audioData) {
    if (audioData.length != 160) {
      print("Transmit must be of size 160");
      // log("Transmit must be of size 160");
      return;
    }
    // print("start transmitAudioData");
    Uint8List ulaw = Uint8List(160);

    for (int i = 0; i < ulaw.length; i++) {
      // conversion via mapping table from pcm to u-law 8kHz
      ulaw[i] = AudioQueue.l2u[audioData.elementAt(i) & 0xffff];
    }
    // print("== ulaw ==   ${ulaw.toList()}");
    Uint8List audioOutPacket = Uint8List(164);
    int i = 0;
    audioOutPacket[i++] = UdpConstants.PACKET_ULAW.value; // 33
    audioOutPacket[i++] = (audioTransmitSequenceNumber >> 16); // 0
    audioOutPacket[i++] = (audioTransmitSequenceNumber >> 8); // 0
    audioOutPacket[i++] = (audioTransmitSequenceNumber);

    audioOutPacket.setRange(4, ulaw.length + 4, ulaw);

    // List.copyRange(audioOutPacket, 4, ulaw);
    // audioOutPacket.addAll(ulaw);
    audioTransmitSequenceNumber++;
    // log("== audioOutPacket ==   ${audioOutPacket.toList()}");
    // try {
    // print("audioOutPacket >>>   $audioOutPacket");
    sendEncryptedPacket(audioOutPacket);
    // } catch (e) {
    //   log("TRY CACH ERROE  $e");
    // }
  }

  late SocketConnectHelper socketConnectHelper;

  sendEncryptedPacket(Uint8List data) {
    if (data.length < 4) {
      throw Exception("invalid packet:   ${data.length}");
    }

    Uint8List nonceData = Uint8List(8);
    for (int i = 0; i < nonceData.length; i++) {
      nonceData[i] = (encryptionNonce >> (i * 8));
    }

    String keyEncrypt = socketConnectHelper.keyEncepted;
    Uint8List keyUin8List = Uint8List.fromList(keyEncrypt.codeUnits);
    Uint8List cypherUnit8List = Sodium.cryptoAeadChacha20poly1305Encrypt(data,
        null, null, ByteArray(nonceData).bytes, ByteArray(keyUin8List).bytes);
    Uint8List encryptedPacket = Uint8List(
      cypherUnit8List.length + nonceData.length + 1,
    ); // 189




    encryptedPacket[0] =
        UdpConstants.PACKET_ENCRYPTION_TYPE_1.value; // -31 && 225

    encryptedPacket.setRange(
        1, nonceData.length + 1, ByteArray(nonceData).bytes);
    encryptedPacket.setRange(nonceData.length + 1,
        nonceData.length + 1 + cypherUnit8List.length, cypherUnit8List);
    // List.copyRange(encryptedPacket, 1, nonceData);

    // List.copyRange(encryptedPacket, nonceData.length , cypherUnit8List);

    // log("encryptedPacket    ${encryptedPacket.toList()}");
    // print("Sent${Int8List.view(encryptedPacket.buffer).toList()}");

    socketConnectHelper.sendPacket(Int8List.view(encryptedPacket.buffer).toList());
    // socketConnectHelper.processPacket(Datagram(encryptedPacket, InternetAddress("94.130.65.54", type: InternetAddressType.any), 6999) , this , audioQueue );

    encryptionNonce++;
  }
}
