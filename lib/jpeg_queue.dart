import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:bit_array/bit_array.dart';
import 'package:buffer/buffer.dart' hide ByteData;
import 'package:flutter/material.dart';

class JpegQueue {
  int vSeq = 0;
  BitArray vPresent = BitArray(10000);
  Uint8List? vData = Uint8List(64 * 1024);

  void reset() {
    vSeq = 0;
  }

  void enqueue(int seq, ByteData bb, ImgListener imgListener) {


    print("seq is $seq");
    if (seq > vSeq) {
      imgListener.onImageReceived(Uint8List(0));
      vPresent.clearAll();
      vSeq = seq;
      vData = null;
    }

    if (seq == vSeq ) {
      // print("bb is ${json.encode(bb.buffer.asUint8List())}");
      // print("bb is ${json.encode(bb.buffer.asUint8List())}");

      // reader.add(bb.buffer.asUint8List().sublist(6));
      // bb= bb.sublist(6);

      print("All  Data >>>>>>> ${bb.buffer.asUint8List()}");
      print("All  Length >>>>>>> ${bb.buffer.asUint8List().length}");


      int imageLen = bb.getInt32(6);
      // int imageOffset = bb.sublist(10).buffer.asByteData().getUint32(0);
      print("IMAGE Length >>>>>>> $imageLen");

      if (vData == null || imageLen != vData?.length) {
        vPresent.clearAll();
        vData = Uint8List(imageLen);
      }

      int imageOffset = bb.getInt32(10);

      print("IMAGE OFFSET >>>>>>> $imageOffset");
      print("IMAGE Rmainig >>>>>>> ${bb.buffer.asUint8List().length -14}");

      int remaining = bb.buffer.asUint8List().length -14;
      while (remaining >0) {
        // print("IMAGE Rmainig >>>>>>> ${bb.sublist(i).length}");

//         int blockSize = Math.min(bb.remaining(), 256);
//
//
//         bb.get(vData, imageOffset, blockSize);
//
// //                Log.e("bbget2"  , String.valueOf(bb.get(vData, imageOffset, blockSize)));
//
//         vPresent.set(imageOffset / 256);
// //                Log.e("VPRESENT"  , String.valueOf(vPresent));
//
//         imageOffset += blockSize;

//

        int blockSize =  min(remaining, 256);

        // vData!.setRange(imageOffset, imageOffset + blockSize, vData!);

        // vData = vData?.sublist(imageOffset , blockSize);
        // vData = Uint8List.view(bb.buffer , imageOffset , blockSize);
        bb = ByteData.view(bb.buffer , imageOffset , blockSize);
        remaining = bb.buffer.asUint8List().length;
        print("Remaining After Edit>>>>>>> $remaining");

        vPresent.setBit((imageOffset ~/ 256));
        imageOffset += blockSize;
        print("IMAGE OFFSET + BLOCK SIZE >>>>>>> $imageOffset");
      }

      // Check if image is complete
      print("VPresent ${json.encode(vPresent.toBinaryString())}");
      // vPresent.toBinaryString().indexOf('1')
      if (vPresent.toBinaryString().indexOf('1') == imageLen ~/ 256) {
        print("IMAGE COMPLETED");
        // Image Complete
        imgListener.onImageReceived(Uint8List.fromList(vData!));
        vData = null;
        vPresent.clearAll();
        vSeq++;
      }
    }
  }
}



abstract class ImgListener{

  void onImageReceived(Uint8List image);

}