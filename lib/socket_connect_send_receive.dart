import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:at_commons/at_commons.dart';
import 'package:byte_util/byte.dart';
import 'package:byte_util/byte_array.dart';
import 'package:flutter/services.dart';
import 'package:untitled1_flutter/jpeg_queue.dart';
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

  connect(ImgListener imgListener) async {
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
          _processPacket(datagram , imgListener);
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
  _processPacket(Datagram datagram , ImgListener imgListener) {
    ByteArray packetData = ByteArray(datagram.data);

    Byte type = packetData.array.first;

    ByteArray? data;

    if (type.value == UdpConstants.PACKET_ENCRYPTION_TYPE_1.value) {
      // 225  &-OR-& -31
      // decrypt the data before handling them
      ByteArray nonce = ByteArray(packetData.bytes.sublist(1, 9));
      ByteArray encryptedData = ByteArray(packetData.bytes.sublist(nonce.array.length + 1));
      ByteArray key = ByteArray(toUnit8List(keyEncepted.codeUnits));

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
        // log("DATA AFTER DECRYPT AS  bytes ===>>>    ${data.bytes}");

        int seq = ((data.array[1].value & 0xff) << 16) |
        ((data.array[2].value & 0xff) << 8) |
        ((data.array[3].value & 0xff));


        int dataLength = data.bytes.length;
        var byteData = ByteData(dataLength);
        var i = 0;
        var after = data.bytes;
        print("After is ${after}");
        after.forEach((element) {
          byteData.setUint8(i, element);
          i++;
        });

        if(data.array[0].value ==0x34){
          JpegQueue().enqueue(seq, byteData, imgListener);
        }

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
