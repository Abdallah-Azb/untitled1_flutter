// ignore_for_file: non_constant_identifier_names, avoid_log
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
import 'package:flutter/services.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_voice_processor/flutter_voice_processor.dart';
import 'package:get/get.dart';
import 'package:raw_sound/raw_sound_player.dart';
import 'package:untitled1_flutter/audio_queue.dart';
import 'package:untitled1_flutter/jpeg_queue.dart';
import 'package:untitled1_flutter/socket_connect_send_receive.dart';
import 'package:untitled1_flutter/udp_constants.dart';

import '../network_helper.dart';
// import 'package:image/image.dart';

// import 'image_load.dart';
// import 'network_helper.dart';

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin
    implements ImgListener, AudioListener {

  final FlutterAudioCapture _plugin =   FlutterAudioCapture();


  AudioQueue audioQueue = AudioQueue();
  final _playerPCMI16 = RawSoundPlayer();

  Rx<Uint8List> image = Uint8List(0).obs;

  // Uint8List? image;

  Uint8List toUnit8List(List<int> data) {
    return Uint8List.fromList(data);
  }

  List<int> toBytes(List<int> bytes, int from, int amount) {
    return bytes.sublist(from, amount);
  }

  late SocketConnectHelper socketConnectHelper;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _startBuild() ,
              _stopBuild(),
            ],
          )
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            onPressed: () async {
              NetworkHelper networkHelper = NetworkHelper();
              ResponseGetInfo? responseGetInfo = await networkHelper.getInfo();
              if (responseGetInfo != null) {

                socketConnectHelper = SocketConnectHelper(
                    host: responseGetInfo.host,
                    port: int.parse(responseGetInfo.port.toString()),
                    sessionId: responseGetInfo.sessionId,
                    keyEncepted: responseGetInfo.key);

              //  socketConnectHelper.connect(this, audioQueue);
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

    // TODO: implement onImageReceived
  }

  @override
  Future<void> onAudioReceived(List<int> audio) async {
    if (!_playerPCMI16.isPlaying) {
      await _playerPCMI16.play();
    }
    log("AudiLength${audio.length}");
    if (_playerPCMI16.isPlaying) {
      _playerPCMI16.feed(Uint8List.fromList([
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124,
        -32124
      ]));
    }
    // TODO: implement onAudioReceived
  }

  // transmitMic
  int frameLength = 512;
  int sampleRate = 16000;
  VoiceProcessor voiceProcessor = VoiceProcessor.getVoiceProcessor(512, 16000);



  bool _isButtonDisabled = false;
  bool _isProcessing = false;
  VoiceProcessor? _voiceProcessor;
  Function? _removeListener;
  Function? _removeListener2;
  Function? _errorListener;

  void _initVoiceProcessor() async {
    _voiceProcessor = VoiceProcessor.getVoiceProcessor(160, 16000);
  }

  @override
  void initState() {
    super.initState();
    _initVoiceProcessor();
  }

  Future<void> _startProcessing() async {

    _removeListener = _voiceProcessor?.addListener(_onBufferReceived);
    _errorListener = _voiceProcessor?.addErrorListener(_onErrorReceived);
    try {
      if (await _voiceProcessor?.hasRecordAudioPermission() ?? false) {
        await _voiceProcessor?.start();

      } else {
        log("Recording permission not granted");
      }
    } on PlatformException catch (ex) {
      log("Failed to start recorder: $ex");
    } finally {

    }
  }

  void _onBufferReceived(eventData) {
    log("Listener 1 received buffer of size ${eventData.length}!");
    log("Listener 2 received buffer   ${eventData} !");
    transmitAudioData(eventData);
  }

  var encryptionNonce = 1;
  int audioTransmitSequenceNumber = 0;

  transmitAudioData(audioData) {
    if (audioData.length != 160) {
      log("Transmit must be of size 160");
      return;
    }
    Int8List ulaw = Int8List(160);
    for (int i = 0; i < audioData.length; i++) {
      // conversion via mapping table from pcm to u-law 8kHz
      ulaw[i] = AudioQueue.l2u[audioData[i] & 0xffff];
    }
    log("== ulaw ==   ${ulaw.toList()}");
    Int8List audioOutPacket = Int8List(164);
    int i = 0;
    audioOutPacket[i++] = UdpConstants.PACKET_ULAW.value; // 33
    audioOutPacket[i++] = (audioTransmitSequenceNumber >> 16); // 0
    audioOutPacket[i++] = (audioTransmitSequenceNumber >> 8); // 0
    audioOutPacket[i++] = (audioTransmitSequenceNumber);
    List.copyRange(audioOutPacket, 4, ulaw);
    // audioOutPacket.addAll(ulaw);
    audioTransmitSequenceNumber++;
    log("== audioOutPacket ==   ${audioOutPacket.toList()}");
    try {
      sendEncryptedPacket(Uint8List.fromList(audioOutPacket));
    } catch (e) {
      log("TRY CACH ERROE  $e");
    }
  }

  String key = '';

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
    Uint8List cypherUnit8List =
    Sodium.cryptoAeadChacha20poly1305Encrypt(data, null, null, nonceData, keyUin8List);

    // log("cypherUnit8List    ${cypherUnit8List.toList()}");

    Uint8List encryptedPacket = Uint8List(cypherUnit8List.length + nonceData.length + 1); // 189

    encryptedPacket[0] = UdpConstants.PACKET_ENCRYPTION_TYPE_1.value; // -31 && 225
    List.copyRange(encryptedPacket, 1, nonceData);
    List.copyRange(encryptedPacket, nonceData.length, cypherUnit8List);

    // log("encryptedPacket    ${encryptedPacket.toList()}");

    socketConnectHelper.sendPacket(encryptedPacket);

    encryptionNonce++;
  }

  void _onErrorReceived(dynamic eventData) {
    String errorMsg = eventData as String;
    log("_onErrorReceived   $errorMsg");
  }

  Future<void> _stopProcessing() async {


    await _voiceProcessor?.stop();
    _removeListener?.call();
    _removeListener2?.call();
    _errorListener?.call();

  }

  void _toggleProcessing() async {
    log("toggleProcessing");
    await _startProcessing();


  }

  Widget _startBuild() {
    return ElevatedButton(
      onPressed: _startCapture,
      child: const Text("Start", style: TextStyle(fontSize: 20)),
    );
  }

  Widget _stopBuild() {
    return ElevatedButton(
      onPressed: _stopCapture,
      child: const Text("Stop", style: TextStyle(fontSize: 20)),
    );
  }

  Future<void> _startCapture() async {
    await _plugin.start(listener, onError, sampleRate: 8000, bufferSize: 16000,);
  }

  Future<void> _stopCapture() async {
    await _plugin.stop();
    print(">>>>>  STOP REC FROM MIC <<<<<<  ");
  }

  void listener(  obj) {
    print(obj.runtimeType.toString());
    print("DATA FROM MIC>>>>     "+obj.toString());
  }

  void onError(Object e) {
    print("ON ERROR=>>>>    "+e.toString());
  }

}


