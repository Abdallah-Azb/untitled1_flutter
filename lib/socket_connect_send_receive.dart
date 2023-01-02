import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:at_commons/at_commons.dart';
import 'package:byte_util/byte.dart';
import 'package:byte_util/byte_array.dart';
import 'package:flutter/services.dart';
import 'package:untitled1_flutter/process_data.dart';
import 'package:untitled1_flutter/udp_constants.dart';

import 'decrypt_sodium_data.dart';

class SocketConnectHelper {
  // HOST AND PORT
  String host;
  final String sessionId;
  final String keyEncepted;
  final int port;

  SocketConnectHelper({
    required this.host,
    required this.port,
    required this.sessionId,
    required this.keyEncepted,
  }) {
    if (host == "apiorun.doorbird.net") {
      host = "142.132.214.220";
    }
  }

  // String host = "142.132.214.220";

  late RawDatagramSocket datagramSocket;
  Datagram? datagramPacket;

  connect() async {
    datagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    datagramPacket =
        Datagram(Uint8List(16 * 1024), InternetAddress(host, type: InternetAddressType.any), 6999);
    Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        _sendSubscribe(true);

        datagramSocket.timeout(const Duration(milliseconds: 1000));

        Datagram? datagram = datagramSocket.receive();
        if (datagram != null) {
          /// Process Data HERE
          ProcessPacket().processPacket(datagram, keyEncepted) ;
        }
      },
    );
  }

  _sendPacket(List<int> buffer) async {
    datagramSocket.send(buffer, InternetAddress(host), port);
  }

  //
  void _sendSubscribe(bool subscribe) {
    int subscribeSeq = 0;
    // var currentFlags = 0;
    // var requestedFlags = 0;
    // ByteData subscribe = ByteData(0);
    // String subscribeString = subscribe.toString();
    // var videoType = UdpConstants.PACKET_NO_VIDEO;
    // var audioType = UdpConstants.PACKET_NO_AUDIO;
    // subscribe = UdpConstants.FLAG_STATE;
    ByteBuffer bb = ByteBuffer(capacity: 128);
    bb.addByte(UdpConstants.PACKET_SUBSCRIBE.buffer.lengthInBytes);
    bb.addByte((subscribeSeq >> 16));
    bb.addByte((subscribeSeq >> 8));
    bb.addByte(subscribeSeq);
    List<int> session = sessionId.codeUnits;
    bb.addByte(session.length);
    bb.append(session);
    bb.addByte(5); //  flag state + flag vedio
    bb.addByte(52); // videoType
    bb.addByte(47); // audioType enabled
    subscribeSeq++;
    _sendPacket(bb.getData());
    // requestedFlags = 5;
    // print("sendSubscribe   ${bb.getData()}");
  }

  //
  Uint8List toUnit8List(List<int> data) {
    return Uint8List.fromList(data);
  }
}
