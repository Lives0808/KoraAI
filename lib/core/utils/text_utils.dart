/// Rough token estimate that works for mixed Chinese/English text.
///
/// CJK characters are counted one-by-one (they are usually ~1 token each),
/// latin text is approximated at four characters per token.
int estimateTokens(String text) {
  var cjk = 0;
  var other = 0;
  for (final rune in text.runes) {
    final isCjk = (rune >= 0x3040 && rune <= 0x30ff) || // kana
        (rune >= 0x3400 && rune <= 0x4dbf) || // CJK ext A
        (rune >= 0x4e00 && rune <= 0x9fff) || // CJK unified
        (rune >= 0xac00 && rune <= 0xd7af) || // hangul
        (rune >= 0xf900 && rune <= 0xfaff); // CJK compat
    if (isCjk) {
      cjk++;
    } else {
      other++;
    }
  }
  return cjk + (other / 4).ceil();
}

String normalizeWhitespace(String text) {
  var value = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  value = value.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  value = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  value = value.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return value.trim();
}

/// Trims a string to [maxChars] without cutting a surrogate pair in half.
String truncate(String text, int maxChars) {
  if (text.length <= maxChars) return text;
  var end = maxChars;
  final codeUnit = text.codeUnitAt(end - 1);
  if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) end -= 1;
  return '${text.substring(0, end)}…';
}
