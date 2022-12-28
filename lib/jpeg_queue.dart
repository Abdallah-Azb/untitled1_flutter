import 'dart:typed_data';

import 'package:bit_array/bit_array.dart';
import 'package:buffer/buffer.dart';
import 'package:byte_util/byte_util.dart';

class JpegQueue{

   int vSeq = 0;
   BitArray vPresent =  BitArray(0);
   Uint8List? vData =  Uint8List(64 * 1024);

   void reset() {
    vSeq = 0;
  }

  void enqueue(int seq , ByteBuffer bb , ImgListener imgListener){


     ByteDataReader reader = ByteDataReader();
    if (seq > vSeq) {

      imgListener.onImageReceived(Uint8List(0)); // marker for incomplete image (broken image)
      vPresent.clearAll();
      vSeq = seq;
      vData = null;
    }

    if(seq == vSeq){
      reader.add(bb.asUint8List());
      int imageLen = bb.asByteData().getInt32(reader.offsetInBytes + 6);

      if (vData == null || imageLen != vData?.length) {
        vPresent.clearAll();
        vData = Uint8List(imageLen);
      }
      int imageOffset = bb.asByteData().getInt32(reader.offsetInBytes);


      while (reader.remainingLength > 0) {
        // Log.e("Limit"  , String.valueOf(bb.limit()));
        // Log.e("Position"  , String.valueOf(bb.position()));
        // Log.e("Remaining"  , String.valueOf(bb.remaining()));

        // int blockSize = Math.min(bb.remaining(), 256);

        int blockSize = reader.remainingLength >256 ? 256 :reader.remainingLength;
        // reader.get(vData, imageOffset, blockSize);
//                Log.e("bbget2"  , String.valueOf(bb.get(vData, imageOffset, blockSize)));

        vPresent.setBit((imageOffset / 256).round());
        // Log.e("VPRESENT"  , String.valueOf(vPresent));

        // vPresent.clea(index)
        imageOffset += blockSize;
      }


    }

  }




}

abstract class ImgListener{

  void onImageReceived(Uint8List image);

}