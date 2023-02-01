import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:at_commons/at_commons.dart';
import 'package:byte_util/byte.dart';
import 'package:byte_util/byte_array.dart';
import 'package:flutter/services.dart';
import 'package:untitled1_flutter/audio_queue.dart';
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
    }  if (host == "apiulaw.doorbird.net") {
      host = "94.130.65.54";
    }
  }

  // String host = "142.132.214.220";


  JpegQueue jpegQueue = JpegQueue();
  late RawDatagramSocket datagramSocket;
  Datagram? datagramPacket;
  int subscribeSeq = 0;

  int requestedFlag = 0;
  int currentFlag = 0;


  connect(ImgListener imgListener , AudioQueue audioQueue) async {
    int lastSubscribe = 0;

    datagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    datagramPacket =
        Datagram(Uint8List(16 * 1024), InternetAddress(host, type: InternetAddressType.any), 6999);
   //
   Timer.periodic(const Duration(microseconds: 5), (timer) async {
     try{
       if(lastSubscribe + (currentFlag == requestedFlag ? 15000 : 500)< DateTime.now().millisecondsSinceEpoch ){
         lastSubscribe = DateTime.now().millisecondsSinceEpoch;
         _sendSubscribe(true);
       }
       datagramSocket.timeout(const Duration(seconds: 1));
       Datagram? datagram = datagramSocket.receive();
       if (datagram != null) {
         /// Process Data HERE
         processPacket(datagram , imgListener , audioQueue);
       }

     }catch(e){

       lastSubscribe =0;
       try{
         datagramSocket = datagramSocket.port >0 ? await RawDatagramSocket.bind(InternetAddress.anyIPv4, datagramSocket.port) : await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
     }
     catch(e){

       datagramSocket=  await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
     }
   }
   });

  //
  //   try{
  //
  //     while(true){
  //
  //         if(lastSubscribe + (currentFlag == requestedFlag ? 15000 : 500)< DateTime.now().millisecondsSinceEpoch ){
  //           lastSubscribe = DateTime.now().millisecondsSinceEpoch;
  //           _sendSubscribe(true);
  //         }
  //         datagramSocket.timeout(const Duration(seconds: 1));
  //         Datagram? datagram = datagramSocket.receive();
  //         if (datagram != null) {
  //           /// Process Data HERE
  //           _processPacket(datagram , imgListener , audioQueue);
  //         }
  //
  //
  //         try{
  //           datagramSocket = datagramSocket.port >0 ? await RawDatagramSocket.bind(InternetAddress.anyIPv4, datagramSocket.port) : await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  //         }
  //         catch(e){
  //           datagramSocket=  await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  //         }
  //       }
  //   }
  //
  // catch(e){
  //     print("Exceptionis$e");
  //   lastSubscribe =0;
  //
  // }




    // Timer.periodic(
    //   const Duration(milliseconds: 500),
    //   (timer) {
    //     _sendSubscribe(true);
    //     datagramSocket.timeout(const Duration(milliseconds: 1000));
    //
    //     Datagram? datagram = datagramSocket.receive();
    //     if (datagram != null) {
    //       /// Process Data HERE
    //       _processPacket(datagram , imgListener);
    //     }
    //   },
    // );
  }

  sendPacket(List<int> buffer) async {
    // print("Length${buffer.length}");
    datagramSocket.send(buffer, InternetAddress(host), port);
  }



  //
  void _sendSubscribe(bool subscribe) {
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
    bb.addByte(7); //  flag state + flag vedio
    bb.addByte(52); // videoType
    bb.addByte(33); // audioType enabled
    subscribeSeq++;
    sendPacket(bb.getData());
    requestedFlag = 5;
    // print("sendSubscribe   ${bb.getData()}");
  }

  //
  processPacket(Datagram datagram , ImgListener imgListener , AudioQueue audioQueue ) {
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
        data = ByteArray(sodiumDecryptHelper.decrypt());

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
        var after = Int8List.fromList(data.bytes);

        Byte state = data.array[4];
        int flags = data.array[5].value;
        // print("After is ${after}");
        after.forEach((element) {
          byteData.setInt8(i, element);
          i++;
        });

        if(data.array[0].value ==0x34){
         jpegQueue.enqueue(seq, byteData, imgListener);
        }
        
        if(data.array[0].value == 0x21){

          int length = 160;
          for (int i = 0, r = 0; i < length; r++) {
            type = data.array[i++];
            seq = ((data.array[i++].value & 0xff) << 16) | ((data.array[i++].value & 0xff) << 8) | ((data.array[i++].value & 0xff));
            state = data.array[i++];
            flags = data.array[i++].value;
            Int8List ulaw = Int8List(length);
            ulaw.setRange(0, length, data.bytes.sublist(i));
            // System.arraycopy(data, i, ulaw, 0, length);
            i += length;
            // print("AudioBefore${ulaw}");

            // audioQueue.enqueue(seq, ulaw, r);
          }
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
