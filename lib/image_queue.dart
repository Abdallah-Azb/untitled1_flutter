import 'dart:typed_data';

import 'package:bit_array/bit_array.dart';
import 'dart:math' as Math;


class JpegQueue {
  int vSeq = 0;

  // BitSet vPresent = BitSet();
  Uint8List? vData = Uint8List(64 * 1024);

  void reset() {
    vSeq = 0;
  }

  void enqueue(int seq, ByteBuffer bb, ImgListener imgListener) {
    if (seq > vSeq) {
      imgListener.onImageReceived(List.filled(0, 0)); // marker for incomplete image (broken image)
      // vPresent.clear();
      vSeq = seq;
      vData = null;
    }
    if (seq == vSeq) {
      ByteData bd = ByteData.view(bb);
      print("BYTE DATA >>>>>>> $bd");
      bd.setUint8(bd.offsetInBytes, 6);
      int imageLen = bd.getInt64(0);
      print("IMAGE LENGTH >>>>>>> $imageLen");
      if (vData == null || imageLen != vData!.length) {
        // vPresent.clear();
        vData = Uint8List(imageLen);
      }
      int imageOffset = bd.getInt8(0);
      print("IMAGE OFFSET >>>>>>> $imageOffset");
      print("V DATA >>>>>>> $vData");
      print("BYTE DATA AFTER POSITIONED >>>>>>> $bd");
      // int remaining = bd.lengthInBytes - bd.offsetInBytes;
      int remaining = vData!.length - bd.offsetInBytes;
      print("REMAINNING >>>>>>>>> $remaining") ;
      // while (remaining > 0) {
      //   int blockSize = Math.min(remaining, 256);
        // vData!.sublist(imageOffset, blockSize) ;
        // bb.get(vData, imageOffset, blockSize);
        // vPresent.set(imageOffset ~/ 256);
        // imageOffset += blockSize;
      // }
      // if (vPresent.nextClearBit(0) > imageLen ~/ 256) {
      //   image complete
        // imgListener.imgReceived(vData);
        // vData = null;
        // vPresent.clear();
        // vSeq++;
      // }
    }
  }
/**
 * Should not be necessary for normal use of doorstations with camera
 */
// void enqueueNoVideo(int seq, ImgListener imgListener) {
//   if (seq > vSeq) {
//     imgListener.imgReceived(List.filled(0, 0)); // marker for incomplete image
//     vPresent.clear();
//     vSeq = seq;
//     vData = null;
//   }
//   if (seq == vSeq) {
//     imgListener.imgReceived(null);
//   }
// }
}
abstract class ImgListener {
  void onImageReceived(List<int> image);
}
