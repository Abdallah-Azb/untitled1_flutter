// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
//
// class MyImageProvider extends ImageProvider<MyImageProvider> {
//   @override
//   ImageStreamCompleter loadBuffer(MyImageProvider key, DecoderBufferCallback decode) {
//     return MultiFrameImageStreamCompleter(
//       codec: _loadData(key, decode), scale: null,
//     );
//   }
//
//   Future<ui.Codec> _loadData(MyImageProvider key, DecoderBufferCallback decode) async {
//     final Uint8List bytes = await bytesFromSomeApi();
//     final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
//     return decode(buffer);
//   }
//
//   @override
//   Future<MyImageProvider> obtainKey(ImageConfiguration configuration) {
//     // TODO: implement obtainKey
//     throw UnimplementedError();
//   }
// }
//
// class MyDelegatingProvider extends ImageProvider<MyDelegatingProvider> {
//   MyDelegatingProvider(this.provider);
//
//   final ImageProvder provider;
//
//   @override
//   ImageStreamCompleter loadBuffer(MyDelegatingProvider key, DecoderCallback decode) {
//     return provider.loadBuffer(key, decode);
//   }
// }

import 'dart:typed_data';
import 'package:bit_array/bit_array.dart';
import 'dart:math' as Math;

import 'package:byte_util/byte_array.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
// import 'package:bit_array/bit_array.dart';

class JpegQueue {
  static int vSeq = 0;
  static Set<BitSet> vPresent = <BitSet>{};
  static ByteArray? vData = ByteArray(Uint8List(64 * 1024));
  static enqueue(int seq, ByteArray data, int length) {
    ByteBuffer byteBuffer;
    byteBuffer = data.bytes.buffer;
    MqttByteBuffer mqttByteBuffer = MqttByteBuffer.fromList(data.bytes);
    if (seq > vSeq) {
      print(" seq > vSeq ");

      vPresent.clear();
      vSeq = seq;
      vData = null;
    }

    print(
        "=== mqttByteBuffer.position 0000   ====     ${mqttByteBuffer.position}");
    if (seq == vSeq) {
      mqttByteBuffer.read(6);
      // data.array.

      // print("=== mqttByteBuffer.position 11111   ====     ${mqttByteBuffer.position}");

    }
  }
  // BitArray v = BitArray(1) ;

  // ByteBuffer vData = ByteBuffer(64 * 1024);
/*
  static Uint8List enqueue(int seq , Uint8List dataAfterDecrypt)   {
      int vSeq = 0;
      Uint8List vData = Uint8List(64 * 1024);

    // static Set<BitSet>  vPresent  ={};
       BitArray vPresent = new BitArray(1024);

    // if (seq > vSeq) {
      vPresent.clearAll();
      vSeq = seq;
      vData = Uint8List(0);
    // }
    // if (seq == vSeq) {
      // Position to 6 like java
      int offset = dataAfterDecrypt.offsetInBytes;
      int imageLen = dataAfterDecrypt.buffer.asByteData().getInt32(offset + 6);
      int remaining = dataAfterDecrypt.buffer.asByteData().lengthInBytes ~/ 2;
      // if (vData.isEmpty || imageLen != vData.length) {
        vPresent.clearAll();
        print("imageLen imageLen imageLen    $imageLen");
        vData = Uint8List(imageLen);
        print("vData vData vData vData vData vData vData   $vData");
      // }
      int imageOffset = dataAfterDecrypt.buffer.asByteData().getInt32(offset + 6);


      // while (remaining > 0) {
      //   int blockSize = Math.min(remaining, 256);
      //
      //   Uint8List.view(dataAfterDecrypt.buffer,blockSize);
      //   vPresent.setBit(imageOffset ~/ 256);
      //   // vPresent.add(BitSet(imageOffset ~/ 256));
      //   imageOffset += blockSize;
      //  // print(">>>>>>>>>>>>>>>   $imageOffset");
      //   // bb.get(vData, imageOffset, blockSize);
      //   // imageOffset += blockSize;
      // }
      vPresent.clearBit(0);




    // }
    return   vData ;
  }
*/

}
