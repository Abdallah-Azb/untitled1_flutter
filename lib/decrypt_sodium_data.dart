
import 'dart:typed_data';
import 'package:flutter_sodium/flutter_sodium.dart';

class SodiumDecryptHelper {
  // Variables
  Uint8List cipherText = Uint8List.fromList([]);
  Uint8List nonce = Uint8List.fromList([]);
  Uint8List key = Uint8List.fromList([]);

  // function decrypt
  void decrypt() {
    print("cipherText ==>  $cipherText");
    print("nonce ==>  $nonce");
    print("key ==>  $key");
    Uint8List decryptData = Sodium.cryptoAeadChacha20poly1305Decrypt(null, cipherText, null, nonce, key);
    print("decryptData ==>  $decryptData");
  }
}
