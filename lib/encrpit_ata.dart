import 'package:encrypt/encrypt.dart';

String encropt( data ,String keye) {
  final key = Key.fromUtf8(keye);
  final iv = IV.fromLength(16);

  final encrypter = Encrypter(AES(key));

  final encrypted = encrypter.encrypt(data, iv: iv);
  final decrypted = encrypter.decrypt(encrypted, iv: iv);

  print(" decrypted ==>  "+decrypted); // Lorem ipsum dolor sit amet, consectetur adipiscing elit
  print(" encrypted.base16  =>   "+encrypted.base16);
  print(" encrypted.base64  =>  "+encrypted.base64);
  // R4PxiU3h8YoIRqVowBXm36ZcCeNeZ4s1OvVBTfFlZRdmohQqOpPQqD1YecJeZMAop/hZ4OxqgC1WtwvX/hP9mw==
  return decrypted ;
}


// void main() {
//   final key = "Your16CharacterK";
//   final plainText = "lorem ipsum example example";
//   Encrypted encrypted = encrypt(key, plainText);
//   String decryptedText = decrypt(key, encrypted);
//   print(decryptedText);
// }



class EncryptionHelper{
 static String decrypt(String keyString, Encrypted encryptedData) {
    final key = Key.fromUtf8(keyString);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final initVector = IV.fromUtf8(keyString.substring(0, 32));
    return encrypter.decrypt(encryptedData, iv: initVector);
  }

 static Encrypted encrypt(String keyString, String plainText) {
    final key = Key.fromUtf8(keyString);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final initVector = IV.fromUtf8(keyString.substring(0, 32));
    Encrypted encryptedData = encrypter.encrypt(plainText, iv: initVector);
    return encryptedData;
  }
}