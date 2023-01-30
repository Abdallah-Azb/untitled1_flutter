import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:bit_array/bit_array.dart';
import 'package:buffer/buffer.dart';
import 'package:flutter/material.dart';

class JpegQueue {
  int vSeq = 0;
  BitArray vPresent = BitArray(10000);
  Int8List? vData = Int8List(64 * 1024);

  void reset() {
    vSeq = 0;
  }

  void enqueue(int seq, ByteData bb, ImgListener imgListener) {
    if (seq > vSeq) {
      vPresent.clearAll();
      vSeq = seq;
      vData = null;
    }

    if (seq == vSeq) {
      // print("bb is ${json.encode(bb.buffer.asUint8List())}");
      // print("bb is ${json.encode(bb.buffer.asUint8List())}");

      // reader.add(bb.buffer.asUint8List().sublist(6));
      // bb= bb.sublist(6);
      // ByteDataReader reader= ByteDataReader();
      //
      // reader.add(bb.buffer.asUint8List());

      // print("All  Data >>>>>>> ${bb.buffer.asInt8List()}");
      // print("All  Length >>>>>>> ${bb.buffer.asInt8List().length}");

      var index = 6;
      int imageLen = bb.getInt32(index);
      index += 4;
      // int imageOffset = bb.sublist(10).buffer.asByteData().getUint32(0);
      // print("IMAGE Length >>>>>>> $imageLen");
      // print("Vdata Length >>>>>>> ${vData?.length}");
      // print("Vdata Length in Bytes >>>>>>> ${vData?.lengthInBytes}");

      if (vData == null || imageLen != vData?.lengthInBytes) {
        vPresent.clearAll();
        vData = Int8List(imageLen);
      }

      int imageOffset = bb.getInt32(index);
      index += 4;

      // print("IMAGE OFFSET >>>>>>> $imageOffset");
      // print("IMAGE Rmainig >>>>>>> ${bb.buffer.asUint8List().length -14}");

      int remaining = bb.buffer.asUint8List().length - index;
      // print("Initial Rmainig >>>>>>> ${remaining}");

      while (remaining > 0) {
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

        int blockSize = min(remaining, 256);

        //
        // print("Block Size >>>>>>> $blockSize");
        // print("OFFSET >>>>>>> $imageOffset");
        // print("INDEX >>>>>>> $index");

        Int8List viewedData =
            Int8List.sublistView(bb, index, index + blockSize);
        // print("New RANGE is ${viewedData}");

        vData!.setRange(imageOffset, imageOffset + blockSize, viewedData);
        // print("New VDdaata is ${vData}");

        // vData = vData?.sublist(imageOffset , blockSize);
        // vData = bb.buffer.asUint8List(imageOffset , blockSize);
        index += blockSize;

        // bb = ByteData.view(bb.buffer , imageOffset , blockSize);

        remaining = bb.buffer.asUint8List().length - index;
        vPresent.setBit((imageOffset ~/ 256));
        imageOffset += blockSize;
      }

      // Check if image is complete
      // vPresent.toBinaryString().indexOf('1')
      // print("Index of 1 ${vPresent.toBinaryString().indexOf('1')}");
      // print("State of 1 ${imageLen ~/ 256}");

      // debugPrint("Last Image is >>> ${vData}" , wrapWidth: 100000);
      // print("Index of 1 ${vPresent.toBinaryString().indexOf('0')}");
      if (vPresent.toBinaryString().indexOf('0') > imageLen ~/ 256) {
        // Image Complete
        imgListener.onImageReceived(Uint8List.fromList(vData!.toList()));
        vData = null;
        vPresent.clearAll();
        vSeq++;
      }
    }
  }
}

abstract class ImgListener {
  void onImageReceived(Uint8List image);
}
