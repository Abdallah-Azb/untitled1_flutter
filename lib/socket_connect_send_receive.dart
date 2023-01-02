import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:at_commons/at_commons.dart';
import 'package:byte_util/byte.dart';
import 'package:byte_util/byte_array.dart';
import 'package:flutter/services.dart';
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
          _processPacket(datagram);
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
  _processPacket(Datagram datagram) {
    ByteArray packetData = ByteArray(datagram.data);

    Byte type = packetData.array.first;

    ByteArray? data;
    if (type.value == UdpConstants.PACKET_ENCRYPTION_TYPE_1.value) {
      // 225  &-OR-& -31
      // decrypt the data before handling them
      ByteArray nonce = ByteArray(packetData.bytes.sublist(1, 9));
      ByteArray encryptedData = ByteArray(packetData.bytes.sublist(nonce.array.length + 1));
      ByteArray key = ByteArray(toUnit8List(keyEncepted.codeUnits));
      // ByteArray nonce = ByteArray(Uint8List.fromList([62,-56,-78,11,-68,58,-52,-81]));
      // ByteArray encryptedData = ByteArray(Uint8List.fromList([-4,-49,69,79,126,-21,31,-3,67,-96,15,-87,-32,43,-49,80,12,122,-12,-121,9,107,27,49,-51,-53,34,-6,16,71,122,-80,-85,48,-49,92,-45,-5,60,-65,60,-66,-32,109,6,95,32,87,-97,-70,-102,-125,40,3,-40,-110,-94,-112,92,-111,9,-100,14,-80,-68,87,-107,-68,18,100,-105,124,-24,40,110,-126,72,43,-55,117,106,101,45,-81,-2,-86,51,-19,122,55,-109,-25,-119,-88,-46,-9,-96,23,16,-34,68,96,83,67,-95,-87,-112,101,-30,72,-82,-30,-19,-113,-66,-94,-96,-21,-45,96,-125,56,-114,45,-47,-72,-62,-3,78,-80,-52,3,-33,14,-121,-22,13,70,52,18,96,-76,-4,75,58,120,-103,61,-74,-126,50,45,-79,124,30,-2,49,-2,-44,-53,-74,-110,-36,93,20,-120,79,-99,60,-31,-108,91,-64,126,2,-119,-105,-113,31,6,-91,119,62,-49,60,83,-80,-118,103,-54,113,60,16,40,15,27,64,36,17,107,-73,-26,65,104,-86,-3,-32,-32,7,-127,-113,-87,-25,5,104,58,108,-58,76,-27,-9,96,72,-11,119,63,12,-106,38,123,43,30,40,62,-30,-114,-86,-76,-97,-104,-79,28,15,17,-39,41,26,-10,38,103,26,87,56,41,-55,-32,-44,25,-5,-126,-14,-122,-8,82,-80,112,2,-92,-111,-19,-124,-24,-33,-128,-71,-75,42,74,-57,16,105,-83,-67,96,10,47,94,111,99,-85,-113,-25,32,-65,111,-128,65,29,-50,72,-54,-102,-111,95,-20,-126,63,-45,114,27,46,-79,-3,-51,-103,15,107,14,-37,71,-75,-122,123,-95,13,-11,44,114,-70,91,-118,105,20,-83,89,-41,-111,89,87,-59,-32,52,96,-16,100,-114,119,127,93,25,24,51,22,-6,-28,-80,-7,-86,-77,-17,101,-91,-121,46,-108,56,-100,48,117,124,-19,-67,100,-101,50,87,41,-22,-35,63,-5,-59,27,-84,12,55,-114,72,-12,103,96,91,-32,-42,68,21,-34,55,-103,-36,-93,124,37,36,58,60,-79,68,121,48,63,9,-52,30,102,-29,-22,-59,88,-39,8,60,16,75,-99,99,66,89,46,-16,69,17,106,-16,-111,-71,127,38,75,-1,-66,0,-58,-61,-73,-11,114,-119,107,-71,-13,7,-5,11,29,110,118,125,11,-80,-90,-114,120,40,-42,17,-25,-111,24,77,-45,102,21,44,-61,61,92,116,-43,124,121,31,25,-47,-121,20,-117,-27,-125,80,49,-90,-88,-59,-75,-81,-68,23,40,72,-32,-128,-60,125,104,-42,-11,-50,17,-29,78,-55,93,4,-11,42,48,72,-16,76,-60,18,90,81,97,88,71,108,-2,76,39,-17,125,-60,22,-18,114,-95,22,122,87,110]));
      // ByteArray key = ByteArray(toUnit8List("2f11c5a7cfe6d8572841cf5f7ad93e63".codeUnits));

      try {
        SodiumDecryptHelper sodiumDecryptHelper =
            SodiumDecryptHelper(cipherText: encryptedData.bytes, nonce: nonce.bytes, key: key.bytes);
        data = ByteArray(toUnit8List(sodiumDecryptHelper.decrypt()));
      } catch (e) {
        print("== Catch Error in Decrypt Data In Sodiom");
      }
      if (data != null) {
        //log("DATA AFTER DECRYPT AS array  ===>>>    ${data.array}");
        // print("======================");
        log("DATA AFTER DECRYPT AS  bytes ===>>>    ${data.bytes}");
      } else {
        print("DATA AFTER DECRYPT IS NULL");
      }
    }
  }

  //
  Uint8List toUnit8List(List<int> data) {
    return Uint8List.fromList(data);
  }
}
