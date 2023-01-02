import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:byte_util/byte.dart';
import 'package:byte_util/byte_array.dart';
import 'package:untitled1_flutter/udp_constants.dart';

import '../jpeg_queue.dart';
import 'decrypt_sodium_data.dart';

class ProcessPacket implements ImgListener {
  Int8List? dataAfterDecrypt;

  processPacket(Datagram datagram, String? encryptKey) {


    ByteArray packetData = ByteArray(datagram.data);

    Byte type = packetData.array.first;

    ByteArray? data;
    if (type.value == UdpConstants.PACKET_ENCRYPTION_TYPE_1.value) {
      // 225  &-OR-& -31
      // decrypt the data before handling them
      ByteArray nonce = ByteArray(packetData.bytes.sublist(1, 9));
      ByteArray encryptedData = ByteArray(packetData.bytes.sublist(nonce.array.length + 1));
      ByteArray key = ByteArray(toUnit8List(encryptKey!.codeUnits));
      dataAfterDecrypt = SodiumDecryptHelper(cipherText: encryptedData.bytes, nonce: nonce.bytes, key: key.bytes).decrypt();
      if (dataAfterDecrypt != null) {
        int seq = ((dataAfterDecrypt![1] & 0xff) << 16) | ((dataAfterDecrypt![2] & 0xff) << 8) | ((dataAfterDecrypt![3] & 0xff));
        JpegQueue().enqueue(seq, Int8List.fromList(dataAfterDecrypt!.toList()), this);
        log("dataAfterDecrypt ==>>>     $dataAfterDecrypt");
        print("seq ===>>>    $seq");
      }
    }
  }

  Uint8List toUnit8List(List<int> data) {
    return Uint8List.fromList(data);
  }
  @override
  void onImageReceived(Int8List image) {
  }
}
