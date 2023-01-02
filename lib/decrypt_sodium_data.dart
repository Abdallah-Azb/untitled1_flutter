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
  Int8List decrypt() {
    print("cipherText ==>  $cipherText");
    print("nonce ==>  $nonce");
    print("key ==>  $key");
    Int8List decryptData = Int8List.fromList(Sodium.cryptoAeadChacha20poly1305Decrypt(null, cipherText, null, nonce, key));
    print("decryptData ==>  $decryptData");
    return decryptData ;
  }
}
