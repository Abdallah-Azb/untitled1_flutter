import 'dart:typed_data';

import 'package:bit_array/bit_array.dart';
import 'package:buffer/buffer.dart';
import 'dart:math' as Math;

class JpegQueue {
  int vSeq = 0;
  BitArray vPresent = BitArray(0);
  Int8List? vData = Int8List(64 * 1024);

  void reset() {
    vSeq = 0;
  }

  void enqueue(int seq, Int8List? bb, ImgListener imgListener) {
    print("SEQ >>>   $seq");
    print("Int8List bb >>>   $bb");
    ByteDataReader reader = ByteDataReader();
    reader.add(bb!.toList());
    if (seq > vSeq) {
      imgListener.onImageReceived(Int8List(0));
      vPresent.clearAll();
      vSeq = seq;
      vData = null;
    }
    if (seq == vSeq ) {
      reader.add(bb!.sublist(6));
      int imageLen = reader.readInt8();
      // int imageOffset = bb.sublist(10).buffer.asByteData().getUint32(0);

      if (vData == null || imageLen != vData?.length) {
        vPresent.clearAll();
        vData = Int8List(imageLen);
      }

      // int imageOffset = bb.sublist(10).buffer.asByteData().getUint32(0);
      int imageOffset = reader.readInt8();

      print("IMAGE LENGTH >>>>>>> $imageLen");
      print("IMAGE OFFSET >>>>>>> $imageOffset");
      while (reader.remainingLength > 0) {
        int blockSize = Math.min(reader.remainingLength, 256);
        // vData!.setRange(imageOffset, imageOffset + blockSize, bb.sublist(imageOffset, imageOffset + blockSize));
        vData!.setRange(imageOffset, blockSize,reader.read(blockSize));
        vPresent.setBit((imageOffset ~/ 256).round());
        imageOffset += blockSize;
        print("IMAGE OFFSET + BLOCK SIZE >>>>>>> $imageOffset");
      }

      // Check if image is complete
      if (vPresent.cardinality == imageLen / 256) {
        print("IMAGE COMPLETED");
        // Image Complete
        imgListener.onImageReceived(vData!);
        vData = null;
        vPresent.clearAll();
        vSeq++;
      }
    }
  }
}

abstract class ImgListener {
  void onImageReceived(Int8List image);
}