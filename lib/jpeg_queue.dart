import 'dart:typed_data';

import 'package:bit_array/bit_array.dart';
import 'package:buffer/buffer.dart';
import 'dart:math' as Math;

class JpegQueue {
  int vSeq = 0;
  BitArray vPresent = BitArray(0);
  Uint8List? vData = Uint8List(64 * 1024);

  void reset() {
    vSeq = 0;
  }

  void enqueue(int seq, Uint8List? bb, ImgListener imgListener) {
    ByteDataReader reader = ByteDataReader();
    if (seq > vSeq) {
      imgListener.onImageReceived(Uint8List(0)); // marker for incomplete image (broken image)
      vPresent.clearAll();
      vSeq = seq;
      vData = null;
    }
    if (seq == vSeq && bb!.length >= 10) {
      reader.add(bb.sublist(6));
      int imageLen = reader.readUint32();
      if (vData == null || imageLen != vData?.length) {
        vPresent.clearAll();
        vData = Uint8List(imageLen);
      }
      int imageOffset = reader.readUint32();
      print("IMAGE LENGTH >>>>>>> $imageLen");
      print("IMAGE OFFSET >>>>>>> $imageOffset");
      print("Remaining   ${reader.remainingLength}");
      while (reader.remainingLength > 0) {
      int blockSize = Math.min(reader.remainingLength, 256);
      vData!.setRange(imageOffset, imageOffset + blockSize, bb.sublist(6));
      vPresent.setBit((imageOffset ~/ 256).round());
      imageOffset += blockSize;
      }
      print("IMAGE OFFSET + BLOCK SIZE >>>>>>> $imageOffset");
      // Check if image is complete
      if (vPresent.cardinality > imageLen / 256) {
        // image complete
        imgListener.onImageReceived(vData!);
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
