import 'dart:math';

import 'package:flutter/foundation.dart';

/// Short, collision-resistant identifier (22 chars of base64url ≈ 128 bits).
String newId() => _randomId(16);

String _randomId(int byteCount) {
  final random = Random.secure();
  final bytes = Uint8List(byteCount);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return _base64Url(bytes);
}

const String _alphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

String _base64Url(Uint8List bytes) {
  final buffer = StringBuffer();
  var bits = 0;
  var value = 0;
  for (final byte in bytes) {
    value = (value << 8) | byte;
    bits += 8;
    while (bits >= 6) {
      bits -= 6;
      buffer.write(_alphabet[(value >> bits) & 0x3f]);
    }
  }
  if (bits > 0) {
    buffer.write(_alphabet[(value << (6 - bits)) & 0x3f]);
  }
  return buffer.toString();
}
