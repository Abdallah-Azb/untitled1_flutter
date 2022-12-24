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
