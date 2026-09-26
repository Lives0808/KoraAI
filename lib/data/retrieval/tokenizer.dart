/// Tokenizer tuned for mixed Chinese/English documents.
///
/// Latin runs become lower-cased words, CJK runs become single characters
/// *and* bigrams so that BM25 still finds multi-character terms.
List<String> tokenize(String text) {
  final tokens = <String>[];
  final buffer = StringBuffer();

  void flushLatins() {
    if (buffer.isEmpty) return;
    final word = buffer.toString().toLowerCase();
    buffer.clear();
    if (word.length > 1 || RegExp(r'[a-z0-9]').hasMatch(word)) {
      tokens.add(word);
    }
  }

  final runes = text.runes.toList(growable: false);
  var pendingCjk = <String>[];
  var pendingHasPrevious = false;

  void flushCjk() {
    if (pendingCjk.isEmpty) return;
    for (var i = 0; i < pendingCjk.length; i++) {
      tokens.add(pendingCjk[i]);
      if (i > 0) tokens.add('${pendingCjk[i - 1]}${pendingCjk[i]}');
    }
    pendingCjk = <String>[];
    pendingHasPrevious = false;
  }

  for (final rune in runes) {
    if (_isCjk(rune)) {
      flushLatins();
      pendingCjk.add(String.fromCharCode(rune));
      pendingHasPrevious = true;
      continue;
    }
    if (_isWordChar(rune)) {
      if (pendingHasPrevious) flushCjk();
      buffer.writeCharCode(rune);
      continue;
    }
    flushLatins();
    flushCjk();
  }
  flushLatins();
  flushCjk();
  return tokens;
}

bool _isWordChar(int rune) {
  if (rune >= 0x30 && rune <= 0x39) return true; // 0-9
  if (rune >= 0x61 && rune <= 0x7a) return true; // a-z
  if (rune >= 0x41 && rune <= 0x5a) return true; // A-Z
  if (rune == 0x5f) return true; // underscore
  // Latin-1 letters and common accented ranges
  if (rune >= 0x00c0 && rune <= 0x024f) return true;
  return false;
}

bool _isCjk(int rune) {
  return (rune >= 0x3040 && rune <= 0x30ff) || // kana
      (rune >= 0x3400 && rune <= 0x4dbf) || // CJK ext A
      (rune >= 0x4e00 && rune <= 0x9fff) || // CJK unified
      (rune >= 0xf900 && rune <= 0xfaff); // CJK compatibility
}
