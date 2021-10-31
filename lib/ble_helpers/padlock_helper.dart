import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

class PadLockHelper {
  static const HEAD = 0x00;
  static Uint8List encodeUnlockData(String bleToken) {
    List<int> token = [
      int.parse(bleToken.substring(0, 2), radix: 16),
      int.parse(bleToken.substring(2, 4), radix: 16),
      int.parse(bleToken.substring(4, 6), radix: 16),
      int.parse(bleToken.substring(6, 8), radix: 16),
    ];
    int unixTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    List<int> buffer = [
          HEAD,
          _Commands.UNLOCK_CMD,
          _CommandLengths.UNLOCK_CMD,
        ] +
        Uint8List.fromList(
            [unixTime >> 24, unixTime >> 16, unixTime >> 8, unixTime]) +
        [0x01] +
        token;
    print('the buffer is $buffer');

    final key = Key(Uint8List.fromList([
      0x2b,
      0x7e,
      0x15,
      0x16,
      0x28,
      0xae,
      0xd2,
      0xa6,
      0xab,
      0xf7,
      0x15,
      0x88,
      0x09,
      0xcf,
      0x4f,
      0x3c
    ]));
    final encrypter = Encrypter(AES(
      key,
      mode: AESMode.ctr,
    ));
    final iv = IV.fromLength(16);
    final encryptedData = encrypter.encryptBytes(buffer, iv: iv).bytes;
    print('encrypted data is  $encryptedData');
    return encryptedData;
  }
}

class _Commands {
  static const UNLOCK_CMD = 0x00;
  static const CHANGE_TOKEN_CMD = 0x0B;
}

class _CommandLengths {
  static const UNLOCK_CMD = 0x05;
  static const CHANGE_TOKEN_CMD = 0x04;
}

class _ProtocolIndex {
  static const HEAD = 0;
  static const CMD = 1;
  static const LEN = 2;
  static const DATA = 3;
}
