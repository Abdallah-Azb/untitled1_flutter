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
