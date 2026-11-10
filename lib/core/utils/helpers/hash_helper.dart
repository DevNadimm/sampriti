import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashHelper {
  HashHelper._();

  /// Fast hash matching the HTML implementation in sampriti-admin.html
  /// Used for shareholder PIN verification: hash(s.no + '|' + pin)
  static String fastHash(String s) {
    s = 'sampriti|$s';
    int a = 0xdeadbeef;
    int b = 0x41c6ce57;

    for (int i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      a = _imul(a ^ c, 2654435761);
      b = _imul(b ^ c, 1597334677);
    }

    final a2 = _imul(a ^ (a >>> 16), 2246822507) ^ _imul(b ^ (b >>> 13), 3266489909);
    final b2 = _imul(b ^ (b >>> 16), 2246822507) ^ _imul(a ^ (a >>> 13), 3266489909);

    final high = 2097151 & b2;
    final low = a2 >>> 0;
    final full = (4294967296 * high) + low;

    return full.toRadixString(36);
  }

  static int _imul(int a, int b) {
    return (BigInt.from(a) * BigInt.from(b)).toSigned(32).toInt();
  }

  /// Standard SHA-256 hash
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
