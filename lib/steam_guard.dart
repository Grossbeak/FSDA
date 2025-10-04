import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;

class SteamGuard {
  static const String _charset = '23456789BCDFGHJKMNPQRTVWXY';

  static String generateCode({required String sharedSecret, required int timestampSeconds}) {
    final Uint8List key = base64.decode(sharedSecret);
    final Uint8List timeBytes = _int64ToBigEndian(timestampSeconds ~/ 30);
    final crypto.Hmac hmacSha1 = crypto.Hmac(crypto.sha1, key);
    final crypto.Digest digest = hmacSha1.convert(timeBytes);

    final List<int> bytes = digest.bytes;
    final int offset = bytes.last & 0x0f;
    int truncatedHash = ((bytes[offset] & 0x7f) << 24) |
        ((bytes[offset + 1] & 0xff) << 16) |
        ((bytes[offset + 2] & 0xff) << 8) |
        (bytes[offset + 3] & 0xff);

    final StringBuffer code = StringBuffer();
    for (int i = 0; i < 5; i++) {
      code.write(_charset[truncatedHash % _charset.length]);
      truncatedHash ~/= _charset.length;
    }
    return code.toString();
  }

  static Uint8List _int64ToBigEndian(int value) {
    final bytes = ByteData(8);
    bytes.setUint64(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }
}



