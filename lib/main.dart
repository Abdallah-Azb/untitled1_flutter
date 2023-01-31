import 'dart:async';
import 'dart:math' as math;
import 'dart:core';
import 'dart:typed_data';

import 'package:byte_util/byte.dart';
import 'package:byte_util/byte_array.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:get/get.dart';

import 'package:mic_stream/mic_stream.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:raw_sound/raw_sound_player.dart';
import 'package:untitled1_flutter/socket_connect_send_receive.dart';
import 'package:untitled1_flutter/udp_constants.dart';

import 'audio_queue.dart';
import 'network_helper.dart';

void main() => runApp(const MicStreamExampleApp());

class MicStreamExampleApp extends StatefulWidget {
  const MicStreamExampleApp({super.key});

  @override
  _MicStreamExampleAppState createState() => _MicStreamExampleAppState();
}

class _MicStreamExampleAppState extends State<MicStreamExampleApp>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Stream? stream;
  late StreamSubscription listener;

  bool isRecording = false;
  bool memRecordingState = false;

  @override
  void initState() {
    print("Init application");
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    setState(() {
      initPlatformState();
    });
  }

  late int bytesPerSample;
  late int samplesPerSecond;
  math.Random random = math.Random();

  Future<bool> transmitMic() async {
    print("START LISTENING");
    if (isRecording) return false;
    print("wait for stream");

    // Default option. Set to false to disable request permission dialogue
    MicStream.shouldRequestPermission(true);
    stream = await MicStream.microphone(
      audioSource: AudioSource.VOICE_COMMUNICATION,
      sampleRate: 1000 * (random.nextInt(50) + 30), //  4000, //1000 * (rng.nextInt(50) + 30),
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );

    // after invoking the method for the first time, though, these will be available;
    // It is not necessary to setup a listener first, the stream only needs to be returned first
    print(
        "Start Listening to the microphone, sample rate is ${await MicStream.sampleRate}, bit depth is ${await MicStream.bitDepth}, bufferSize: ${await MicStream.bufferSize}");
    // bytesPerSample = (await MicStream.bitDepth)! ~/ 8;
    // samplesPerSecond = (await MicStream.sampleRate)!.toInt();
    listener = stream!.listen((sample) {
      Uint8List uint8List = sample;
      Int16List int16List = Int16List.fromList(uint8List.buffer.asInt16List(0, 160));

      // List<int> sam = sample.toList();
      // print(sample.getRange(0, 160).length);
      // Int16List array = Int16List.fromList(sample.toList());
      // ByteArray array = ByteArray(Uint8List.fromList(sample.toList()))  ;
      // print(array.bytes.buffer.asInt16List());
      print(int16List);
      // print(array.array.map((e) {
      //
      //   return ;
      //
      // }).toList());
      transmitAudioData(int16List);
    });
    return true;
  }

  Future<bool> getInfo() async {
    bool success = false;
    NetworkHelper networkHelper = NetworkHelper();
    ResponseGetInfo? responseGetInfo = await networkHelper.getInfo();
    if (responseGetInfo != null) {
      socketConnectHelper = SocketConnectHelper(
          host: responseGetInfo.host,
          port: int.parse(responseGetInfo.port.toString()),
          sessionId: responseGetInfo.sessionId,
          keyEncepted: responseGetInfo.key);
      socketConnectHelper.connect();
      success = true;
    }
    return success;
  }

  var encryptionNonce = 1;
  int audioTransmitSequenceNumber = 0;

  transmitAudioData(List<int> audioData) {
    if (audioData.length != 160) {
      print("Transmit must be of size 160");
      // log("Transmit must be of size 160");
      return;
    }
    print("start transmitAudioData");
    // Uint8List ulaw = Uint8List(160);
    Int16List ulaw = Int16List(160);

    for (int i = 0; i < ulaw.length; i++) {
      // conversion via mapping table from pcm to u-law 8kHz
      print("BEFOOER  ${audioData[i]}  AFTEER   ${audioData.elementAt(i) & 0xffff}");
      ulaw[i] = AudioQueue.l2u[audioData[i] & 0xffff];
    }
    print("== ulaw ==   ${ulaw.toList()}");
    Int16List audioOutPacket = Int16List(164);
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
    print("audioOutPacket >>>   $audioOutPacket");
    sendEncryptedPacket(audioOutPacket);
    // } catch (e) {
    //   log("TRY CACH ERROE  $e");
    // }
  }

  late SocketConnectHelper socketConnectHelper;

  sendEncryptedPacket(Int16List data) {
    print("sendEncryptedPacket >>>   $data");
    if (data.length < 4) {
      throw Exception("invalid packet:   ${data.length}");
    }

    Int16List nonceData = Int16List(8);
    for (int i = 0; i < nonceData.length; i++) {
      nonceData[i] = (encryptionNonce >> (i * 8));
    }

    String keyEncrypt = socketConnectHelper.keyEncepted;
    Int16List keyUin8List = Int16List.fromList(keyEncrypt.codeUnits);
    // print("keyUin8List = ${keyUin8List.toList()}\n");
    Uint8List cypherUnit8List = Sodium.cryptoAeadChacha20poly1305Encrypt(
        data.buffer.asUint8List(),
        null,
        null,
        ByteArray(nonceData.buffer.asUint8List()).bytes,
        ByteArray(keyUin8List.buffer.asUint8List()).bytes);

    // log("cypherUnit8List    ${cypherUnit8List.toList()}");

    // List<int> encryptedPacket = List.filled(cypherUnit8List.length + nonceData.length + 1 , 0 , growable: false); // 189
    Int16List encryptedPacket = Int16List(
      cypherUnit8List.length + nonceData.length + 1,
    ); // 189

    encryptedPacket[0] = UdpConstants.PACKET_ENCRYPTION_TYPE_1.value; // -31 && 225

    encryptedPacket.setRange(
        1, nonceData.length, ByteArray(Uint8List.fromList(nonceData.buffer.asUint8List())).bytes);
    encryptedPacket.setRange(
        nonceData.length + 1, nonceData.length + 1 + cypherUnit8List.length, cypherUnit8List);

    // List.copyRange(encryptedPacket, 1, nonceData);

    // List.copyRange(encryptedPacket, nonceData.length , cypherUnit8List);

    // log("encryptedPacket    ${encryptedPacket.toList()}");

    socketConnectHelper.sendPacket(encryptedPacket);

    encryptionNonce++;
  }

  bool _stopListening() {
    // if (!isRecording) return false;
    listener.cancel();
    print("Stop Listening to the microphone");

    setState(() {
      isRecording = false;
    });
    return true;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin: mic_stream :: Debug'),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              onPressed: () async {
                // if(isRecording){
                _stopListening();
                // }
              },
              child: Icon(Icons.stop),
              // foregroundColor: _iconColor,
              backgroundColor: Colors.red,
              tooltip: (isRecording) ? "Stop recording" : "Start recording",
            ),
            FloatingActionButton(
              onPressed: () async {
                if (!isRecording) {
                  // await transmitMic();
                  if (await getInfo()) {
                    await transmitMic();
                  }
                }
              },
              child: Icon(Icons.keyboard_voice),
              // foregroundColor: _iconColor,
              backgroundColor: Colors.blue,
              tooltip: (isRecording) ? "Stop recording" : "Start recording",
            ),
          ],
        ).paddingSymmetric(horizontal: 40),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    listener.cancel();
    // controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}

///
