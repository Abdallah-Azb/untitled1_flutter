// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:byte_util/byte.dart';

class UdpConstants {
  static ByteData PACKET_SUBSCRIBE = ByteData(0x01);
  static Byte PACKET_STATE_CHANGE = Byte(0x11); //17
  static Byte PACKET_ULAW = Byte(0x21); // 33
  static Byte PACKET_NO_AUDIO = Byte(0x2F);
  static Byte PACKET_JPEG_V2 = Byte(0x34); // 52
  static Byte PACKET_NO_VIDEO = Byte(0x3F);
  static Byte PACKET_ENCRYPTION_TYPE_1 = Byte(0xE1); //225
  static ByteData FLAG_STATE = ByteData(1);
  static Byte FLAG_AUDIO = Byte(2);
  static Byte FLAG_VIDEO = Byte(4);
  static Byte STATE_VIDEO_SESSION_INVALID = Byte(5);
  static Byte STATE_AUDIO_SESSION_INVALID = Byte(6);
}


// void enqueue(int seq, ByteBuffer bb, ImgListener imgListener) {
//   if (seq > vSeq) {
//     imgListener.imgReceived(new Uint8List(0)); // marker for incomplete image (broken image)
//     vPresent.clear();
//     vSeq = seq;
//     vData = null;
//   }
//   if (seq == vSeq) {
//     bb.position(6);
//     int imageLen = bb.getInt();
//     if (vData == null || imageLen != vData.length) {
//       vPresent.clear();
//       vData = new Uint8List(imageLen);
//     }
//     int imageOffset = bb.getInt();
//     while (bb.remaining() > 0) {
//       int blockSize = min(bb.remaining(), 256);
//       vData.setRange(imageOffset, imageOffset + blockSize, bb.getUint8List(blockSize));
//       vPresent.set(imageOffset ~/ 256);
//       imageOffset += blockSize;
//     }
//     if (vPresent.nextClearBit(0) > imageLen ~/ 256) {
//       imgListener.imgReceived(vData);
//       vData = null;
//       vPresent.clear();
//       vSeq++;
//     }
//   }
// }