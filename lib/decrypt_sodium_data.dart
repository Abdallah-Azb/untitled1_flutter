import 'dart:typed_data';
import 'package:flutter_sodium/flutter_sodium.dart';

class SodiumDecryptHelper {
  // Variables
  // final  Uint8List cipherText = Uint8List.fromList([]);
  // final Uint8List nonce = Uint8List.fromList([]);
  // final Uint8List key = Uint8List.fromList([]);
  final Uint8List cipherText;
  final Uint8List nonce;

  final Uint8List key;

  SodiumDecryptHelper({
    required this.cipherText,
    required this.nonce,
    required this.key,
  });

  // function decrypt
  Uint8List decrypt() {
    // print("cipherText ==>  $cipherText");
    // print("nonce ==>  $nonce");
    // print("key ==>  $key");
    Uint8List decryptData = Sodium.cryptoAeadChacha20poly1305Decrypt(null, cipherText, null, nonce, key);
    // print("decryptData ==>  $decryptData");
    return decryptData ;
  }

  // Uint8List encrypt(Int8List data , Int8List noce) {
  // }


}
