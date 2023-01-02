import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_sodium/flutter_sodium.dart';

import 'jpeg_queue.dart';

class ProcessPacket implements ImgListener {
  final String? encryptKey ;

  ProcessPacket(this.encryptKey);

  Uint8List? dataAfterDecrypt ;

  Uint8List toUnit8List(List<int> data) {
    return Uint8List.fromList(data);
  }

  processPacket(Datagram datagram) {
    int dataLength = datagram.data.length;
    Uint8List nonce = datagram.data.sublist(1, 9);
    Uint8List cipherText = datagram.data.sublist(nonce.length + 1);
    Uint8List key = toUnit8List(encryptKey!.codeUnits);

    print("processPacket ==>   ${datagram.data}");
    print(" datagram.data ==>>   ${datagram.data}");
    print(" datagram.data.length ==>>   $dataLength");
    print(" cipherText ==>>   $cipherText");
    print(" nonce ==>>   $nonce");
    print(" key ==>>   $key");

    dataAfterDecrypt = HelperDecryptionUsingSodium.decrypt(cipherText: cipherText, nonce: nonce, key: key);
    if (dataAfterDecrypt != null) {
      dataLength = dataAfterDecrypt!.length;
      int seq = ((dataAfterDecrypt![1] & 0xff) << 16) | ((dataAfterDecrypt![2] & 0xff) << 8) | ((dataAfterDecrypt![3] & 0xff));
      JpegQueue().enqueue(seq, dataAfterDecrypt, this);

      log("dataAfterEncrypt ==>>>     $dataAfterDecrypt");
      log("dataLengthNew ==>>    $dataLength");
      print("seq ===>>>    $seq");

    }
  }

  @override
  void onImageReceived(Uint8List imgData) async  {
    print("Image received : ${imgData.length}");
    // decode jpeg into bitmap to display it in image view
    final codec = await instantiateImageCodec(imgData);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    // setState(() {
    //   liveIv.image = image;
    // });
    }
}

class HelperDecryptionUsingSodium {
  static Uint8List decrypt({required Uint8List cipherText, required Uint8List nonce, required Uint8List key}) =>
      Sodium.cryptoAeadChacha20poly1305Decrypt(null, cipherText, null, nonce, key);
}
