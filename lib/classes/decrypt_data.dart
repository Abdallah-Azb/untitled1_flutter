import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';

class HelperDecryptionUsingSodium {
  static Uint8List decrypt({required Uint8List cipherText, required Uint8List nonce, required Uint8List key}) =>
      Sodium.cryptoAeadChacha20poly1305Decrypt(null, cipherText, null, nonce, key);
}
