// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

// import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:byte_util/byte_array.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';

// import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:raw_sound/raw_sound_player.dart';

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

  Stream? stream;
  late StreamSubscription listener;

  List<int> audioPart = [];

  AudioQueue audioQueue = AudioQueue();
  final _playerPCMI16 = RawSoundPlayer();

  Rx<Uint8List> image = Uint8List(0).obs;

  FlutterSoundPlayer player = FlutterSoundPlayer();

  // final FlutterSoundPlayer flutterSound =  FlutterSoundPlayer(voiceProcessing:false);

  @override
  void initState() {
    super.initState();
    initPlugin();
  }

  Future<void> initPlugin() async {
    //
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
    // player.startPlayerFromStream(codec: Codec)
    // await player.openPlayer(enableVoiceProcessing: true);
    // await player.startPlayerFromStream(
    //     codec: Codec.pcm16, numChannels: 1, sampleRate: 4000);
    // await player.setVolume(.9);

    // await player.openPlayer(enableVoiceProcessing: true);
    // await player.startPlayerFromStream(
    //     codec: Codec.pcm8, numChannels: 1, sampleRate: 4000);

    // int intSize = await FlutterSound;
    // print("Buffer size: $intSize");4
    await _playerPCMI16.initialize(
        nChannels: 1,
        bufferSize: 8,
        pcmType: RawSoundPCMType.PCMI16,
        sampleRate: 8000);
    await _playerPCMI16.setVolume(1.0);
    //  await flutterSound.openPlayer(enableVoiceProcessing: false);
    //  await flutterSound.setVolume(1.0);
    //  await flutterSound.startPlayerFromStream( codec: Codec.pcm16, sampleRate: 4000, numChannels: 1 );

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
  }

  @override
  Future<void> onAudioReceived(List<int> audio) async {
    // flutterSound.feedFromStream(Uint8List.fromList(audio));
    // _player.writeChunk(Uint8List.fromList(audio));

    // print("LEngth${audio.length}");
    //
    // audioPart.addAll(audio);
    // if(audioPart.length == 320){
    //
    //
    // }

    // Future.delayed(const Duration(microseconds: 10) , (){
    //   player.foodSink!.add(FoodData(Uint8List.fromList(audio)));
    //
    // });
    // Future.microtask(() async {
    if (!_playerPCMI16.isPlaying) {
      await _playerPCMI16.play();
    }
    if (_playerPCMI16.isPlaying) {
      Int16List int16list = Int16List.fromList(audio);
      _playerPCMI16.feed(Uint8List.view(int16list.buffer));
      // await Future.delayed(const Duration(milliseconds: 100));
      // audioPart.clear();
    }
    //   //
    //
    //
    //
    //   // audioPart.addAll(audio);
    //
    //
    // });

    // if(audioPart.length > 10000){
    //
    //   audioPart.clear();
    // };

    // print("Default List${audio}");
    // print("Uint8List List${Uint8List.fromList(audio)}");
    // player.foodSink!.add(FoodData(Uint8List.fromList(audio)));

    // player.foodSink!.add(FoodData(Uint8List.fromList(audio)));

    // methodChannel
    //     .invokeMethod(
    //     "playAudio",
    //     {
    //       "audioBuffer":audio,
    //     });
    // TODO: implement onAudioReceived
  }

  runMic() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    FlutterSoundPlayer player = FlutterSoundPlayer();

    player.openPlayer();
    player.startPlayerFromStream(
        codec: Codec.pcm16, sampleRate: 8000, numChannels: 1);

    FlutterSoundRecorder sound = FlutterSoundRecorder();
    await sound.openRecorder();

    var recordingDataController = StreamController<Food>();

    recordingDataController.stream.listen((buffer) {
      if (buffer is FoodData) {
        // player.feedFromStream(buffer.data!);

        // List<int> intList = List<int>.filled(160, 0);
        // for (int i = 0; i < 160; i++) {
        //   intList[i] = buffer!.data![i] - 256;
        // }
        //

        // Uint8List list = Uint8List.sublistView(buffer.data!  ,0 , 640 );

        Uint8List u8list = Uint8List.fromList(buffer.data!);

        print("All length${buffer.data?.length}");

        Int16List int16List = Int16List.view(u8list.buffer);

        print("INT16List${int16List.length}");

        if (int16List.length > 160) {
          transmitAudioData(int16List.getRange(0, 160).toList());
          // methodChannel
          //     .invokeMethod(
          //     "playAudio",
          //     {
          //       "audioBuffer":int16List.getRange(0, 160).toList()
          //     });
        } else {
          transmitAudioData(int16List.toList());

          // methodChannel
          //     .invokeMethod(
          //     "playAudio",
          //     {
          //       "audioBuffer":int16List.toList()
          //     });
        }
      }
    });

    await sound!.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 8000,
        bitRate: 512,
        audioSource: AudioSource.voice_communication);
    //   MicStream.shouldRequestPermission(true);
    //   stream = await MicStream.microphone(
    //     audioSource: AudioSource.VOICE_COMMUNICATION,
    //     sampleRate: 8000, //1000 * (rng.nextInt(50) + 30),
    //     channelConfig: ChannelConfig.CHANNEL_IN_MONO,
    //     audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    //   );
    //
    //   // after invoking the method for the first time, though, these will be available;
    //   // It is not necessary to setup a listener first, the stream only needs to be returned first
    //   stream!.listen((  sample){
    //
    //     Future.microtask(() {
    //       Uint8List data = Uint8List.fromList(sample);
    //       print("Data 8 = ${data}");
    //       // ByteData byteData = ByteData.view(data.buffer , );
    //       // Int16List int16List = Int16List.sublistView(data , );
    //       // print("Data 8list = ${data.buffer.asByteData().getUint8(0)}");
    //
    //       Int16List list = Int16List.view(data.buffer);
    //       print("Data 16= ${list.length}");
    //
    //
    //       methodChannel
    //           .invokeMethod(
    //           "playAudio",
    //           {
    //             "audioBuffer":list.getRange(0  , 160).toList()
    //           });
    //     });
    //
    //
    //     // transmitAudioData(sample.getRange(0, 160).toList());
    //   });
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
    // print("keyUin8List = ${keyUin8List.toList()}\n");
    Uint8List cypherUnit8List = Sodium.cryptoAeadChacha20poly1305Encrypt(data,
        null, null, ByteArray(nonceData).bytes, ByteArray(keyUin8List).bytes);

    // log("cypherUnit8List    ${cypherUnit8List.toList()}");

    // List<int> encryptedPacket = List.filled(cypherUnit8List.length + nonceData.length + 1 , 0 , growable: false); // 189
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
    // print("LEbght${Int8List.view(encryptedPacket.buffer).toList()}");

    socketConnectHelper.sendPacket(Int8List.view(encryptedPacket.buffer));
    // socketConnectHelper.processPacket(Datagram(encryptedPacket, InternetAddress("94.130.65.54", type: InternetAddressType.any), 6999) , this , audioQueue );

    encryptionNonce++;
  }
}
