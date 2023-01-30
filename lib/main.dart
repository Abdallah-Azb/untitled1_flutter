import 'dart:async';
import 'dart:math';
import 'dart:core';
import 'dart:typed_data';

import 'package:byte_util/byte.dart';
import 'package:byte_util/byte_array.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

import 'package:mic_stream/mic_stream.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:untitled1_flutter/socket_connect_send_receive.dart';
import 'package:untitled1_flutter/udp_constants.dart';

import 'audio_queue.dart';
import 'network_helper.dart';

enum Command {
  start,
  stop,
  change,
}


void main() => runApp(MicStreamExampleApp());

class MicStreamExampleApp extends StatefulWidget {
  @override
  _MicStreamExampleAppState createState() => _MicStreamExampleAppState();
}

class _MicStreamExampleAppState extends State<MicStreamExampleApp>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Stream? stream;
  late StreamSubscription listener;
  List<int>? currentSamples = [];
  List<int> visibleSamples = [];
  int? localMax;
  int? localMin;

  Random rng = new Random();

  // Refreshes the Widget for every possible tick to force a rebuild of the sound wave
  late AnimationController controller;

  Color _iconColor = Colors.white;
  bool isRecording = false;
  bool memRecordingState = false;
  late bool isActive;
  DateTime? startTime;

  int page = 0;
  List state = ["SoundWavePage", "IntensityWavePage", "InformationPage"];

  @override
  void initState() {
    print("Init application");
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    setState(() {
      initPlatformState();
    });
  }

  void _controlPage(int index) => setState(() => page = index);

  // Responsible for switching between recording / idle state
  void _controlMicStream({Command command = Command.change}) async {
    switch (command) {
      case Command.change:
        _changeListening();
        break;
      case Command.start:
        _startListening();
        break;
      case Command.stop:
        _stopListening();
        break;
    }
  }

  Future<bool> _changeListening() async => !isRecording ? await _startListening() : _stopListening();

  late int bytesPerSample;
  late int samplesPerSecond;

  Future<bool> _startListening() async {
    print("START LISTENING");
    if (isRecording) return false;
    // if this is the first time invoking the microphone()
    // method to get the stream, we don't yet have access
    // to the sampleRate and bitDepth properties
    print("wait for stream");


    NetworkHelper networkHelper = NetworkHelper();
    ResponseGetInfo? responseGetInfo = await networkHelper.getInfo();
    if (responseGetInfo != null) {

      socketConnectHelper = SocketConnectHelper(
          host: responseGetInfo.host,
          port: int.parse(responseGetInfo.port.toString()),
          sessionId: responseGetInfo.sessionId,
          keyEncepted: responseGetInfo.key);

      socketConnectHelper.connect();



    // Default option. Set to false to disable request permission dialogue
    MicStream.shouldRequestPermission(true);
    stream = await MicStream.microphone(
      audioSource: AudioSource.MIC,
      sampleRate: 4000, //1000 * (rng.nextInt(50) + 30),
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );

    // after invoking the method for the first time, though, these will be available;
    // It is not necessary to setup a listener first, the stream only needs to be returned first
    print(
        "Start Listening to the microphone, sample rate is ${await MicStream.sampleRate}, bit depth is ${await MicStream.bitDepth}, bufferSize: ${await MicStream.bufferSize}");
    bytesPerSample = (await MicStream.bitDepth)! ~/ 8;
    samplesPerSecond = (await MicStream.sampleRate)!.toInt();
    localMax = null;
    localMin = null;

    listener = stream!.listen(( sample){
      // List<int> sam = sample;
      // print(sample.getRange(0, 160).length);
      transmitAudioData(sample.getRange(0, 160).toList());

    });
    return true;
    }else {
      return false;
    }

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
    Uint8List ulaw = Uint8List(160);

    for (int i = 0; i < ulaw.length; i++) {
      // conversion via mapping table from pcm to u-law 8kHz
      ulaw[i] = AudioQueue.l2u[audioData.elementAt(i) & 0xffff];
    }
    print("== ulaw ==   ${ulaw.toList()}");
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
    print("audioOutPacket >>>   $audioOutPacket");
      sendEncryptedPacket(audioOutPacket);
    // } catch (e) {
    //   log("TRY CACH ERROE  $e");
    // }
  }
  late SocketConnectHelper socketConnectHelper;

  sendEncryptedPacket(Uint8List data) {
    print("sendEncryptedPacket >>>   $data");
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
    Sodium.cryptoAeadChacha20poly1305Encrypt(data, null, null, ByteArray(nonceData).bytes, ByteArray(keyUin8List).bytes);

    // log("cypherUnit8List    ${cypherUnit8List.toList()}");

    // List<int> encryptedPacket = List.filled(cypherUnit8List.length + nonceData.length + 1 , 0 , growable: false); // 189
    Uint8List encryptedPacket = Uint8List(cypherUnit8List.length + nonceData.length + 1 , ); // 189

    encryptedPacket[0] = UdpConstants.PACKET_ENCRYPTION_TYPE_1.value; // -31 && 225

    encryptedPacket.setRange(1, nonceData.length , ByteArray(nonceData).bytes);
    encryptedPacket.setRange(nonceData.length +1, nonceData.length +1 +cypherUnit8List.length, cypherUnit8List);

    // List.copyRange(encryptedPacket, 1, nonceData);

    // List.copyRange(encryptedPacket, nonceData.length , cypherUnit8List);

    // log("encryptedPacket    ${encryptedPacket.toList()}");

    socketConnectHelper.sendPacket(Int8List.fromList(encryptedPacket.toList()));

    encryptionNonce++;
  }


  bool _stopListening() {
    if (!isRecording) return false;
    print("Stop Listening to the microphone");
    listener.cancel();

    setState(() {
      isRecording = false;
      currentSamples = null;
      startTime = null;
    });
    return true;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;
    isActive = true;

    Statistics(false);

    controller = AnimationController(duration: Duration(seconds: 1), vsync: this)
      ..addListener(() {
        if (isRecording) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed)
          controller.reverse();
        else if (status == AnimationStatus.dismissed) controller.forward();
      })
      ..forward();
  }

  Color _getBgColor() => (isRecording) ? Colors.red : Colors.cyan;

  Icon _getIcon() => (isRecording) ? Icon(Icons.stop) : Icon(Icons.keyboard_voice);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin: mic_stream :: Debug'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _controlMicStream,
            child: _getIcon(),
            foregroundColor: _iconColor,
            backgroundColor: _getBgColor(),
            tooltip: (isRecording) ? "Stop recording" : "Start recording",
          ),


          // bottomNavigationBar: BottomNavigationBar(
          //   items: [
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.broken_image),
          //       label: "Sound Wave",
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.broken_image),
          //       label: "Intensity Wave",
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.view_list),
          //       label: "Statistics",
          //     )
          //   ],
          //   backgroundColor: Colors.black26,
          //   elevation: 20,
          //   currentIndex: page,
          //   onTap: _controlPage,
          // ),
          // body: (page == 0 || page == 1)
          //     ? CustomPaint(
          //         painter: WavePainter(
          //           samples: visibleSamples,
          //           color: _getBgColor(),
          //           localMax: localMax,
          //           localMin: localMin,
          //           context: context,
          //         ),
          //       )
          //     : Statistics(
          //         isRecording,
          //         startTime: startTime,
          //       ),

      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      isActive = true;
      print("Resume app");

      _controlMicStream(command: memRecordingState ? Command.start : Command.stop);
    } else if (isActive) {
      memRecordingState = isRecording;
      _controlMicStream(command: Command.stop);

      print("Pause app");
      isActive = false;
    }
  }

  @override
  void dispose() {
    listener.cancel();
    controller.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
}

class WavePainter extends CustomPainter {
  int? localMax;
  int? localMin;
  List<int>? samples;
  late List<Offset> points;
  Color? color;
  BuildContext? context;
  Size? size;

  // Set max val possible in stream, depending on the config
  // int absMax = 255*4; //(AUDIO_FORMAT == AudioFormat.ENCODING_PCM_8BIT) ? 127 : 32767;
  // int absMin; //(AUDIO_FORMAT == AudioFormat.ENCODING_PCM_8BIT) ? 127 : 32767;

  WavePainter({this.samples, this.color, this.context, this.localMax, this.localMin});

  @override
  void paint(Canvas canvas, Size? size) {
    this.size = context!.size;
    size = this.size;

    Paint paint = new Paint()
      ..color = color!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (samples!.length == 0) return;

    points = toPoints(samples);

    Path path = new Path();
    path.addPolygon(points, false);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldPainting) => true;

  // Maps a list of ints and their indices to a list of points on a cartesian grid
  List<Offset> toPoints(List<int>? samples) {
    List<Offset> points = [];
    if (samples == null) samples = List<int>.filled(size!.width.toInt(), (0.5).toInt());
    double pixelsPerSample = size!.width / samples.length;
    for (int i = 0; i < samples.length; i++) {
      var point = Offset(i * pixelsPerSample,
          0.5 * size!.height * pow((samples[i] - localMin!) / (localMax! - localMin!), 5));
      points.add(point);
    }
    return points;
  }

  double project(int val, int max, double height) {
    double waveHeight = (max == 0) ? val.toDouble() : (val / max) * 0.5 * height;
    return waveHeight + 0.5 * height;
  }
}

class Statistics extends StatelessWidget {
  final bool isRecording;
  final DateTime? startTime;

  final String url = "https://github.com/anarchuser/mic_stream";

  Statistics(this.isRecording, {this.startTime});

  @override
  Widget build(BuildContext context) {
    return ListView(children: <Widget>[
      ListTile(leading: Icon(Icons.title), title: Text("Microphone Streaming Example App")),
      ListTile(
        leading: Icon(Icons.keyboard_voice),
        title: Text((isRecording ? "Recording" : "Not recording")),
      ),
      ListTile(
          leading: Icon(Icons.access_time),
          title: Text((isRecording ? DateTime.now().difference(startTime!).toString() : "Not recording"))),
    ]);
  }
}

Iterable<T> eachWithIndex<E, T>(Iterable<T> items, E Function(int index, T item) f) {
  var index = 0;

  for (final item in items) {
    f(index, item);
    index = index + 1;
  }

  return items;
}
///
